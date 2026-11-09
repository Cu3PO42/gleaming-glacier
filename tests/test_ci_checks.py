import os
from pathlib import Path
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]


class ResultTests(unittest.TestCase):
    def check_result(self, **overrides):
        env = {
            "TESTS": "success", "EVAL": "success", "BUILD": "success",
            "UPLOAD_CACHED": "success", "EXPECTED_BUILD": "success",
            "EXPECTED_UPLOAD": "success",
        }
        return subprocess.run(
            ["bash", str(ROOT / "ci/check-results.sh")],
            env={**os.environ, **env, **overrides}, capture_output=True, text=True,
        ).returncode

    def test_required_jobs_must_succeed(self):
        self.assertEqual(self.check_result(), 0)
        for job in ("TESTS", "EVAL", "BUILD", "UPLOAD_CACHED"):
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
