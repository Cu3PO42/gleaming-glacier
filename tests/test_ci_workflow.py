import os
from pathlib import Path
import subprocess
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
            "EXPECTED_UPLOAD": "success",
        }
        return subprocess.run(
            ["bash", "-e", "-c", step_script("Check results")],
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


if __name__ == "__main__":
    unittest.main()
