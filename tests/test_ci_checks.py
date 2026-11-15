import os
from pathlib import Path
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]


class ResultTests(unittest.TestCase):
    systems = ("X86_64_LINUX", "AARCH64_LINUX", "AARCH64_DARWIN")

    def check_result(self, **overrides):
        env = {
            "EVAL": "success",
            "UPLOAD_CACHED": "success", "EXPECTED_UPLOAD": "success",
        }
        for system in self.systems:
            env[f"BUILD_{system}"] = "success"
            env[f"EXPECTED_BUILD_{system}"] = "success"
        return subprocess.run(
            ["bash", str(ROOT / "ci/check-results.sh")],
            env={**os.environ, **env, **overrides}, capture_output=True, text=True,
        ).returncode

    def test_required_jobs_must_succeed(self):
        self.assertEqual(self.check_result(), 0)
        jobs = ("EVAL", "UPLOAD_CACHED", *(f"BUILD_{s}" for s in self.systems))
        for job in jobs:
            for result in ("failure", "cancelled", "skipped", ""):
                with self.subTest(job=job, result=result):
                    self.assertNotEqual(self.check_result(**{job: result}), 0)

    def test_skips_are_accepted_only_when_expected(self):
        jobs = [(f"BUILD_{s}", f"EXPECTED_BUILD_{s}") for s in self.systems]
        jobs.append(("UPLOAD_CACHED", "EXPECTED_UPLOAD"))
        all_skipped = {}
        for job, expected in jobs:
            with self.subTest(job=job):
                skipped = {job: "skipped", expected: "skipped"}
                self.assertEqual(self.check_result(**skipped), 0)
                all_skipped.update(skipped)
                for result in ("failure", "cancelled", "success", ""):
                    self.assertNotEqual(self.check_result(**{job: result, expected: "skipped"}), 0)
        self.assertEqual(self.check_result(**all_skipped), 0)

    def test_failure_is_not_hidden_by_other_platforms_being_cached(self):
        for failed in self.systems:
            with self.subTest(failed=failed):
                overrides = {}
                for system in self.systems:
                    overrides[f"BUILD_{system}"] = "failure" if system == failed else "skipped"
                    overrides[f"EXPECTED_BUILD_{system}"] = "success" if system == failed else "skipped"
                self.assertNotEqual(self.check_result(**overrides), 0)


class HandoffTests(unittest.TestCase):
    def test_pending_builds_require_a_committed_manifest(self):
        for any_jobs in ("true", "false"):
            for version in ("", "0", "invalid", "1", "123"):
                with self.subTest(any_jobs=any_jobs, version=version):
                    result = subprocess.run(
                        ["bash", str(ROOT / "ci/check-handoff.sh")],
                        env={**os.environ, "ANY_JOBS": any_jobs, "MANIFEST_VERSION": version},
                        capture_output=True, text=True,
                    )
                    expected = any_jobs == "false" or version in ("1", "123")
                    self.assertEqual(result.returncode == 0, expected)


if __name__ == "__main__":
    unittest.main()
