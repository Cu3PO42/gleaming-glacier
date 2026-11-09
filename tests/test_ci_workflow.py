import os
import json
from pathlib import Path
import subprocess
import tempfile
import textwrap
import unittest


ROOT = Path(__file__).resolve().parents[1]


def step_script(name):
    """Run the actual workflow shell block so gate tests cannot drift from it."""
    workflow = (ROOT / ".github/workflows/ci.yml").read_text()
    step = workflow.split(f"      - name: {name}\n", 1)[1]
    lines = step.split("        run: |\n", 1)[1].splitlines(keepends=True)
    script = []
    for line in lines:
        if line.strip() and not line.startswith("          "):
            break
        script.append(line)
    return textwrap.dedent("".join(script))


class ResultTests(unittest.TestCase):
    def check_result(self, **overrides):
        env = {
            "TESTS": "success", "EVAL": "success", "BUILD": "success",
            "UPLOAD_CACHED": "success", "EXPECTED_BUILD": "success",
            "EXPECTED_UPLOAD": "success", "DEDUPLICATE": "success",
            "SHOULD_SKIP": "false", "WAIT_DUPLICATE": "skipped",
        }
        return subprocess.run(
            ["bash", "-e", "-c", step_script("Check results")],
            env={**os.environ, **env, **overrides}, capture_output=True, text=True,
        ).returncode

    def test_required_jobs_must_succeed(self):
        self.assertEqual(self.check_result(), 0)
        for job in ("TESTS", "DEDUPLICATE", "EVAL", "BUILD", "UPLOAD_CACHED"):
            for result in ("failure", "cancelled", "skipped", ""):
                with self.subTest(job=job, result=result):
                    self.assertNotEqual(self.check_result(**{job: result}), 0)

    def test_skips_are_accepted_only_when_expected(self):
        self.assertEqual(self.check_result(BUILD="skipped", EXPECTED_BUILD="skipped"), 0)
        self.assertEqual(self.check_result(UPLOAD_CACHED="skipped", EXPECTED_UPLOAD="skipped"), 0)
        self.assertEqual(self.check_result(
            BUILD="skipped", UPLOAD_CACHED="skipped",
            EXPECTED_BUILD="skipped", EXPECTED_UPLOAD="skipped",
        ), 0)
        for result in ("failure", "cancelled"):
            with self.subTest(result=result):
                self.assertNotEqual(self.check_result(BUILD=result, EXPECTED_BUILD="skipped"), 0)
                self.assertNotEqual(self.check_result(UPLOAD_CACHED=result, EXPECTED_UPLOAD="skipped"), 0)

    def test_duplicate_runs_require_original_success(self):
        env = {
            "SHOULD_SKIP": "true", "WAIT_DUPLICATE": "success", "EVAL": "skipped",
            "BUILD": "skipped", "UPLOAD_CACHED": "skipped",
            "EXPECTED_BUILD": "skipped", "EXPECTED_UPLOAD": "skipped",
        }
        self.assertEqual(self.check_result(**env), 0)
        for result in ("failure", "cancelled", "skipped", ""):
            with self.subTest(result=result):
                self.assertNotEqual(self.check_result(**{**env, "WAIT_DUPLICATE": result}), 0)


class DuplicateTests(unittest.TestCase):
    def test_only_push_runs_with_the_actual_checkout_tree_are_reused(self):
        tree = subprocess.run(
            ["git", "rev-parse", "HEAD^{tree}"], cwd=ROOT,
            check=True, capture_output=True, text=True,
        ).stdout.strip()
        for event, candidate_tree, candidate_skip, expected in (
            ("push", tree, "true", "true"),
            ("pull_request", tree, "true", "false"),
            ("push", "different-merge-tree", "true", "false"),
            ("push", tree, "false", "false"),
        ):
            with self.subTest(event=event, tree=candidate_tree, skip=candidate_skip):
                with tempfile.TemporaryDirectory() as directory:
                    output = Path(directory) / "outputs"
                    subprocess.run(
                        ["bash", "-e", "-c", step_script("Verify duplicate content")],
                        cwd=ROOT, check=True, capture_output=True, text=True,
                        env={**os.environ, "GITHUB_OUTPUT": str(output),
                             "CANDIDATE_SKIP": candidate_skip,
                             "CANDIDATE": json.dumps({"event": event, "treeHash": candidate_tree, "id": 123})},
                    )
                    self.assertIn(f"should-skip={expected}\n", output.read_text())
                    self.assertIn("run-id=123\n" if expected == "true" else "run-id=\n", output.read_text())

    def test_waiter_only_accepts_success_and_polls_pending_runs(self):
        with tempfile.TemporaryDirectory() as directory:
            bin_dir = Path(directory)
            gh = bin_dir / "gh"
            gh.write_text(
                '#!/usr/bin/env python3\n'
                'import json, os\n'
                'from pathlib import Path\n'
                'state = Path(os.environ["WAIT_STATE"])\n'
                'if not state.exists():\n'
                '    state.touch()\n'
                '    print(json.dumps({"status": "in_progress", "conclusion": None}))\n'
                'else:\n'
                '    print(json.dumps({"status": "completed", "conclusion": os.environ["CONCLUSION"]}))\n'
            )
            gh.chmod(0o755)
            sleep = bin_dir / "sleep"
            sleep.write_text('#!/usr/bin/env bash\necho polled >> "$WAIT_POLLS"\n')
            sleep.chmod(0o755)
            for conclusion in ("success", "failure", "cancelled", "timed_out", "skipped", "neutral"):
                with self.subTest(conclusion=conclusion):
                    state = bin_dir / "state"
                    polls = bin_dir / "polls"
                    result = subprocess.run(
                        ["bash", "-e", "-c", step_script("Require duplicate success")],
                        capture_output=True, text=True,
                        env={**os.environ, "PATH": f"{bin_dir}:{os.environ['PATH']}",
                             "CONCLUSION": conclusion, "WAIT_STATE": str(state),
                             "WAIT_POLLS": str(polls), "GITHUB_REPOSITORY": "owner/repo",
                             "DUPLICATE_RUN_ID": "123"},
                    )
                    self.assertEqual(result.returncode == 0, conclusion == "success")
                    self.assertEqual(polls.read_text(), "polled\n")
                    state.unlink()
                    polls.unlink()


class HandoffTests(unittest.TestCase):
    def test_pending_builds_require_a_committed_manifest(self):
        for any_jobs in ("true", "false"):
            for version in ("", "0", "invalid", "1", "123"):
                with self.subTest(any_jobs=any_jobs, version=version):
                    result = subprocess.run(
                        ["bash", "-e", "-c", step_script("Validate derivation cache handoff")],
                        env={**os.environ, "ANY_JOBS": any_jobs, "MANIFEST_VERSION": version},
                        capture_output=True, text=True,
                    )
                    expected = any_jobs == "false" or version in ("1", "123")
                    self.assertEqual(result.returncode == 0, expected)


if __name__ == "__main__":
    unittest.main()
