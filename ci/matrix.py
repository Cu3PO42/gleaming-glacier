"""Partition Hestia jobs by platform and configuration build dependencies."""

import json
import subprocess
import sys
from collections import defaultdict


def derivations(row):
    # Hestia groups have multiple installables; drvPath describes only the first.
    return {item.partition("^")[0] for item in row["installables"].split()}


def query_requisites(roots):
    # Query the instantiated derivations, not their outputs: no builds or eval.
    result = subprocess.run(
        ["nix-store", "--query", "--requisites", *roots],
        check=True,
        stdout=subprocess.PIPE,
        text=True,
    )
    return set(result.stdout.splitlines())


def split_matrix(matrix, requisites=query_requisites):
    platforms = defaultdict(list)
    for row in matrix["include"]:
        platforms[row["system"]].append(row)

    result = {"include": []}
    for system, rows in sorted(platforms.items()):
        packages = []
        configurations = []
        for row in rows:
            target = packages if row["attr"].startswith(("packages.", "checks.")) else configurations
            target.append(row)

        roots = {drv for row in configurations for drv in derivations(row)}
        dependencies = set(requisites(sorted(roots))) if roots and packages else set()
        required = []
        independent = []
        for row in packages:
            target = required if derivations(row) & dependencies else independent
            target.append(row)

        result["include"].append({
            "system": system,
            "packages": {"include": required},
            "other-packages": {"include": independent},
            "configurations": {"include": configurations},
            "any-packages": bool(required),
            "any-other-packages": bool(independent),
            "any-configurations": bool(configurations),
        })
    return result


def main():
    matrix = split_matrix(json.load(sys.stdin))
    for platform in matrix["include"]:
        print(
            f"{platform['system']}: "
            f"{len(platform['packages']['include'])} prerequisite package/check jobs, "
            f"{len(platform['other-packages']['include'])} independent jobs, "
            f"{len(platform['configurations']['include'])} configuration jobs",
            file=sys.stderr,
        )
    print(json.dumps(matrix, separators=(",", ":")))


if __name__ == "__main__":
    main()
