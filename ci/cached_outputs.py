"""Collect outputs omitted from Hestia's matrix because they are cached."""

import json
import sys


def cached_outputs(jobs):
    paths = set()
    for job in jobs:
        if "error" in job:
            raise ValueError(f"Evaluation failed: {job['error']}")
        if not job.get("isCached", False):
            continue
        outputs = job["outputs"]
        if not outputs:
            raise ValueError("Cached derivation has no outputs")
        for path in outputs.values():
            if not isinstance(path, str) or not path.startswith("/nix/store/"):
                raise ValueError(f"Unresolved cached output: {path!r}")
            paths.add(path)
    return sorted(paths)


if __name__ == "__main__":
    print(json.dumps(cached_outputs(json.loads(line) for line in sys.stdin if line.strip()),
                     separators=(",", ":")))
