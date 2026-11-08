import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

from ci.cached_outputs import cached_outputs


ROOT = Path(__file__).resolve().parents[1]


class EvaluationPolicyTests(unittest.TestCase):
    def test_cache_status_is_preserved_and_evaluation_is_saved(self):
        with tempfile.TemporaryDirectory() as directory:
            nix = Path(directory) / "nix"
            nix.write_text('#!/usr/bin/env python3\nimport json, sys\nprint(json.dumps(sys.argv[1:]))\n')
            nix.chmod(0o755)
            for upload in ("true", "false", ""):
                with self.subTest(upload=upload):
                    saved = Path(directory) / "evaluation.jsonl"
                    result = subprocess.run(
                        ["bash", str(ROOT / "ci/nix-eval-jobs.sh"),
                         "--workers", "1", "--flake", ".#ciJobs",
                         "--check-cache-status", "--meta", "--force-recurse"],
                        env={**os.environ, "PATH": f"{directory}:{os.environ['PATH']}",
                             "CACHE_UPLOAD": upload, "NIX_EVAL_JOBS_OUTPUT": str(saved)},
                        check=True, capture_output=True, text=True,
                    )
                    arguments = json.loads(result.stdout)
                    expected = ["run", "--inputs-from", ".", "nixpkgs#nix-eval-jobs",
                                "--", "--workers", "1", "--flake", ".#ciJobs"]
                    expected.append("--check-cache-status")
                    expected.extend(["--meta", "--force-recurse"])
                    self.assertEqual(arguments, expected)
                    self.assertEqual(saved.read_text(), result.stdout)

    def test_failed_evaluation_is_not_hidden_by_tee(self):
        with tempfile.TemporaryDirectory() as directory:
            nix = Path(directory) / "nix"
            nix.write_text('#!/usr/bin/env bash\necho partial-output\nexit 42\n')
            nix.chmod(0o755)
            saved = Path(directory) / "evaluation.jsonl"
            result = subprocess.run(
                ["bash", str(ROOT / "ci/nix-eval-jobs.sh")],
                env={**os.environ, "PATH": f"{directory}:{os.environ['PATH']}",
                     "NIX_EVAL_JOBS_OUTPUT": str(saved)},
                capture_output=True, text=True,
            )
            self.assertEqual(result.returncode, 42)
            self.assertEqual(saved.read_text(), "partial-output\n")


class CachedOutputTests(unittest.TestCase):
    def test_cached_outputs_include_all_platforms_and_deduplicate_all_outputs(self):
        jobs = [
            {"system": "aarch64-darwin", "isCached": True,
             "outputs": {"out": "/nix/store/mac", "dev": "/nix/store/mac-dev"}},
            {"system": "aarch64-linux", "isCached": True,
             "outputs": {"out": "/nix/store/linux"}},
            {"isCached": True, "outputs": {"out": "/nix/store/mac"}},
            {"isCached": False, "outputs": {"out": "/nix/store/pending"}},
        ]
        self.assertEqual(cached_outputs(jobs),
                         ["/nix/store/linux", "/nix/store/mac", "/nix/store/mac-dev"])

    def test_fully_uncached_or_empty_runs_have_no_backfill(self):
        self.assertEqual(cached_outputs([]), [])
        self.assertEqual(cached_outputs([{"isCached": False}]), [])

    def test_unresolved_outputs_and_eval_errors_fail_closed(self):
        for job in ({"error": "broken"}, {"isCached": True, "outputs": {}},
                    {"isCached": True, "outputs": {"out": None}}):
            with self.subTest(job=job), self.assertRaises(ValueError):
                cached_outputs([job])


class PromotionTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        self.remote = self.directory / "remote.git"
        self.work = self.directory / "work"
        self.work.mkdir()
        self.git("init", "--bare", str(self.remote))
        self.git("init", "--initial-branch=master")
        self.git("config", "user.name", "CI test")
        self.git("config", "user.email", "ci@example.invalid")
        self.git("remote", "add", "origin", str(self.remote))
        self.first = self.commit("first")
        self.second = self.commit("second")
        self.third = self.commit("third")
        self.git("push", "origin", "master")

    def git(self, *arguments):
        return subprocess.run(
            ["git", *arguments], cwd=self.work, check=True,
            capture_output=True, text=True,
        ).stdout.strip()

    def commit(self, name):
        self.git("-c", "commit.gpgsign=false", "commit", "--allow-empty", "-m", name)
        return self.git("rev-parse", "HEAD")

    def promote(self, sha):
        return subprocess.run(
            ["bash", str(ROOT / "ci/promote-deploy.sh")], cwd=self.work,
            env={**os.environ, "GITHUB_SHA": sha}, capture_output=True, text=True,
        )

    def deployed(self):
        return self.git("--git-dir", str(self.remote), "rev-parse", "refs/heads/deploy")

    def test_creates_branch_at_tested_commit_even_if_master_has_advanced(self):
        result = self.promote(self.second)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.deployed(), self.second)

    def test_fast_forwards_existing_deploy(self):
        self.git("push", "origin", f"{self.first}:refs/heads/deploy")
        result = self.promote(self.third)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.deployed(), self.third)

    def test_retries_never_roll_back_deploy(self):
        self.git("push", "origin", f"{self.third}:refs/heads/deploy")
        for sha in (self.third, self.second):
            with self.subTest(sha=sha):
                result = self.promote(sha)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(self.deployed(), self.third)

    def test_rejects_commit_outside_current_master_history(self):
        self.git("push", "origin", f"{self.first}:refs/heads/deploy")
        self.git("checkout", "--detach", self.first)
        unrelated = self.commit("other branch")
        result = self.promote(unrelated)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.deployed(), self.first)

    def test_rejects_divergent_deploy(self):
        self.git("checkout", "--detach", self.first)
        unrelated = self.commit("divergent deployment")
        self.git("push", "origin", f"{unrelated}:refs/heads/deploy")
        result = self.promote(self.third)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.deployed(), unrelated)

    def test_conflicting_remote_update_cannot_be_overwritten(self):
        self.git("push", "origin", f"{self.first}:refs/heads/deploy")
        # Simulate another run advancing deploy between our fetch and push.
        hook = self.work / ".git/hooks/pre-push"
        hook.write_text(
            '#!/usr/bin/env bash\n'
            f'git --git-dir="{self.remote}" update-ref refs/heads/deploy {self.third}\n'
        )
        hook.chmod(0o755)
        result = self.promote(self.second)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.deployed(), self.third)


if __name__ == "__main__":
    unittest.main()
