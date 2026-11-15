import copy
import unittest
from unittest.mock import Mock

from ci.automerge import GitHub, REPOSITORY, eligible, merge, tested


def pull_request():
    return {
        "number": 12, "state": "open", "draft": False, "changed_files": 1,
        "user": {"login": "dependabot[bot]", "type": "Bot"},
        "head": {"sha": "head", "repo": {"full_name": REPOSITORY}},
        "base": {"sha": "base", "ref": "master", "repo": {"full_name": REPOSITORY}},
    }


def run(identifier=1):
    return {
        "id": identifier, "event": "pull_request", "status": "completed",
        "conclusion": "success", "head_sha": "head",
        "pull_requests": [{"number": 12, "base": {"sha": "base"}, "head": {"sha": "head"}}],
    }


FILES = [{"filename": "flake.lock", "status": "modified"}]


class PaginationTests(unittest.TestCase):
    def test_all_pages_are_read_including_changes_beyond_first_page(self):
        api = GitHub("unused")
        api.request = Mock(side_effect=[FILES * 100, [{"filename": "other", "status": "added"}]])
        files = list(api.pages("pulls/12/files"))
        self.assertEqual(len(files), 101)
        self.assertFalse(eligible(pull_request(), files))
        self.assertEqual([call.args[0] for call in api.request.call_args_list], [
            "pulls/12/files?per_page=100&page=1", "pulls/12/files?per_page=100&page=2",
        ])

    def test_workflow_run_pagination_preserves_query(self):
        api = GitHub("unused")
        api.request = Mock(side_effect=[{"workflow_runs": [run()] * 100}, {"workflow_runs": []}])
        self.assertEqual(len(list(api.pages("runs?head_sha=head", "workflow_runs"))), 100)
        self.assertEqual(api.request.call_args_list[-1].args[0], "runs?head_sha=head&per_page=100&page=2")


class EligibilityTests(unittest.TestCase):
    def test_only_same_repository_dependabot_updates_to_master(self):
        self.assertTrue(eligible(pull_request(), FILES))
        changes = [
            ("state", "closed"), ("draft", True), ("changed_files", 2),
            ("user", {"login": "someone", "type": "User"}),
            ("user", {"login": "dependabot[bot]", "type": "User"}),
            ("head", {"sha": "head", "repo": None}),
            ("head", {"sha": "head", "repo": {"full_name": "someone/fork"}}),
            ("base", {"ref": "deploy", "repo": {"full_name": REPOSITORY}}),
        ]
        for key, value in changes:
            with self.subTest(key=key, value=value):
                pr = pull_request()
                pr[key] = value
                self.assertFalse(eligible(pr, FILES))

    def test_file_list_must_be_exactly_one_modified_root_lockfile(self):
        for files in [[], FILES * 2,
                      [{"filename": "nested/flake.lock", "status": "modified"}],
                      [{"filename": "flake.nix", "status": "modified"}],
                      *[[{"filename": "flake.lock", "status": status}]
                        for status in ("added", "removed", "renamed")],
                      [{**FILES[0], "previous_filename": "other"}]]:
            with self.subTest(files=files):
                self.assertFalse(eligible(pull_request(), files))

    def test_ci_must_pass_on_the_current_head_and_base(self):
        self.assertTrue(tested(run(), pull_request()))
        for key, value in [("event", "push"), ("status", "in_progress"),
                           ("conclusion", "failure"), ("conclusion", "cancelled"),
                           ("conclusion", "skipped"), ("head_sha", "old"),
                           ("pull_requests", []),
                           ("pull_requests", [{"number": 99, "base": {"sha": "base"}, "head": {"sha": "head"}}]),
                           ("pull_requests", [{"number": 12, "base": {"sha": "old"}, "head": {"sha": "head"}}])]:
            with self.subTest(key=key, value=value):
                candidate = run()
                candidate[key] = value
                self.assertFalse(tested(candidate, pull_request()))


class MergeTests(unittest.TestCase):
    def api(self, runs=None, current=None, files=None):
        api = Mock()
        pr = pull_request()
        reads = iter([pr, current or copy.deepcopy(pr)])

        def request(path, method="GET", data=None):
            if path == "pulls/12" and method == "GET":
                return next(reads)
            if path == "pulls/12/merge" and method == "PUT":
                return {"merged": True, "sha": "merged"}
            if path == "actions/workflows/ci.yml/dispatches" and method == "POST":
                return None
            raise AssertionError((path, method, data))

        def pages(path, key=None):
            if path == "pulls/12/files":
                return iter(FILES if files is None else files)
            return iter([run()] if runs is None else runs)

        api.request.side_effect = request
        api.pages.side_effect = pages
        return api

    def writes(self, api):
        return [call for call in api.request.call_args_list if len(call.args) > 1]

    def test_merge_pins_head_and_dispatches_master_after_success(self):
        api = self.api()
        merge(api, 12)
        self.assertEqual([call.args for call in self.writes(api)], [
            ("pulls/12/merge", "PUT", {"sha": "head", "merge_method": "squash"}),
            ("actions/workflows/ci.yml/dispatches", "POST", {"ref": "master"}),
        ])
        self.assertEqual(sum(call.args[0] == 'pulls/12/files' for call in api.pages.call_args_list), 2)

    def test_latest_failed_or_pending_attempt_blocks_older_success(self):
        for result in ("failure", None, "cancelled"):
            latest = run(2)
            latest["conclusion"] = result
            api = self.api(runs=[run(), latest])
            merge(api, 12)
            self.assertEqual(self.writes(api), [])

    def test_missing_ci_or_mixed_file_changes_never_merge(self):
        for api in (self.api(runs=[]), self.api(files=FILES + [{"filename": "flake.nix", "status": "modified"}])):
            merge(api, 12)
            self.assertEqual(self.writes(api), [])

    def test_either_workflow_can_block_merging(self):
        api = self.api()
        pages = api.pages.side_effect
        api.pages.side_effect = lambda path, key=None: iter([]) if "verify-lockfile.yml" in path else pages(path, key)
        merge(api, 12)
        self.assertEqual(self.writes(api), [])

    def test_concurrent_head_base_or_author_changes_block_merge(self):
        for key, value in [("head", {"sha": "new", "repo": {"full_name": REPOSITORY}}),
                           ("base", {"sha": "new", "ref": "master", "repo": {"full_name": REPOSITORY}}),
                           ("user", {"login": "someone", "type": "User"})]:
            current = pull_request()
            current[key] = value
            api = self.api(current=current)
            merge(api, 12)
            self.assertEqual(self.writes(api), [])

    def test_rerun_can_repair_dispatch_after_a_successful_bot_merge(self):
        api = self.api()
        request = api.request.side_effect
        pr = {**pull_request(), "state": "closed", "merged": True,
              "merged_by": {"login": "github-actions[bot]"}}
        api.request.side_effect = lambda path, method="GET", data=None: pr if path == "pulls/12" else request(path, method, data)
        merge(api, 12, recover_head="head")
        self.assertEqual([call.args for call in self.writes(api)], [
            ("actions/workflows/ci.yml/dispatches", "POST", {"ref": "master"}),
        ])

    def test_api_error_fails_closed(self):
        api = self.api()
        api.pages.side_effect = RuntimeError("API unavailable")
        with self.assertRaises(RuntimeError):
            merge(api, 12)
        self.assertEqual(self.writes(api), [])

    def test_refused_merge_never_dispatches(self):
        api = self.api()
        request = api.request.side_effect
        api.request.side_effect = lambda path, method="GET", data=None: {"merged": False} if method == "PUT" else request(path, method, data)
        with self.assertRaises(RuntimeError):
            merge(api, 12)
        self.assertEqual(len(self.writes(api)), 1)


if __name__ == "__main__":
    unittest.main()
