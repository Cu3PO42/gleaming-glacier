"""Merge tested Dependabot lockfile updates using trusted workflow metadata."""

import json
import os
from pathlib import Path
import urllib.parse
import urllib.request


REPOSITORY = "Cu3PO42/gleaming-glacier"
WORKFLOWS = ("ci.yml", "verify-lockfile.yml")


class GitHub:
    def __init__(self, token):
        self.token = token

    def request(self, path, method="GET", data=None):
        request = urllib.request.Request(
            f"https://api.github.com/repos/{REPOSITORY}/{path}",
            data=None if data is None else json.dumps(data).encode(),
            method=method,
            headers={
                "Authorization": f"Bearer {self.token}",
                "Accept": "application/vnd.github+json",
                "X-GitHub-Api-Version": "2022-11-28",
                "Content-Type": "application/json",
            },
        )
        with urllib.request.urlopen(request, timeout=30) as response:
            body = response.read()
            return json.loads(body) if body else None

    def pages(self, path, key=None):
        separator = "&" if "?" in path else "?"
        page = 1
        while True:
            result = self.request(f"{path}{separator}per_page=100&page={page}")
            rows = result[key] if key else result
            yield from rows
            if len(rows) < 100:
                return
            page += 1


def eligible(pr, files):
    return (
        pr["state"] == "open"
        and not pr["draft"]
        and pr["user"]["login"] == "dependabot[bot]"
        and pr["user"]["type"] == "Bot"
        and pr["base"]["ref"] == "master"
        and pr["base"]["repo"]["full_name"] == REPOSITORY
        and pr["head"]["repo"] is not None
        and pr["head"]["repo"]["full_name"] == REPOSITORY
        and pr["changed_files"] == 1
        and len(files) == 1
        and files[0]["filename"] == "flake.lock"
        and files[0]["status"] == "modified"
        and "previous_filename" not in files[0]
    )


def tested(run, pr):
    return (
        run["event"] == "pull_request"
        and run["status"] == "completed"
        and run["conclusion"] == "success"
        and run["head_sha"] == pr["head"]["sha"]
        and any(
            item["number"] == pr["number"]
            and item["base"]["sha"] == pr["base"]["sha"]
            and item["head"]["sha"] == pr["head"]["sha"]
            for item in run["pull_requests"]
        )
    )


def dispatch_master(api):
    # GITHUB_TOKEN merges do not trigger push workflows. Dispatch master CI so
    # the resulting revision uploads its closures and can advance deploy.
    api.request("actions/workflows/ci.yml/dispatches", "POST", {"ref": "master"})
    print("Dispatched Nix CI on master for cache uploads and deploy promotion")


def merge(api, number, recover_head=None):
    pr = api.request(f"pulls/{number}")
    files = list(api.pages(f"pulls/{number}/files"))
    # A rerun can repair a failed dispatch after this automation merged the PR.
    if (
        recover_head == pr["head"]["sha"]
        and pr.get("merged")
        and (pr.get("merged_by") or {}).get("login") == "github-actions[bot]"
        and eligible({**pr, "state": "open"}, files)
    ):
        dispatch_master(api)
        return
    if not eligible(pr, files):
        print(f"PR #{number}: not an eligible lockfile update")
        return

    for workflow in WORKFLOWS:
        query = urllib.parse.urlencode({"event": "pull_request", "head_sha": pr["head"]["sha"]})
        runs = list(api.pages(f"actions/workflows/{workflow}/runs?{query}", "workflow_runs"))
        runs = [run for run in runs if any(item["number"] == number for item in run["pull_requests"])]
        if not runs or not tested(max(runs, key=lambda run: run["id"]), pr):
            print(f"PR #{number}: waiting for {workflow} on the current head and base")
            return

    # Re-read after inspecting CI to reject concurrent PR edits and file changes.
    current = api.request(f"pulls/{number}")
    if current["head"]["sha"] != pr["head"]["sha"] or current["base"]["sha"] != pr["base"]["sha"]:
        print(f"PR #{number}: changed while checking CI")
        return
    if not eligible(current, list(api.pages(f"pulls/{number}/files"))):
        return

    result = api.request(f"pulls/{number}/merge", "PUT", {
        "sha": pr["head"]["sha"], "merge_method": "squash",
    })
    if not result["merged"]:
        raise RuntimeError(f"PR #{number}: GitHub refused the merge")
    print(f"PR #{number}: merged as {result['sha']}")
    dispatch_master(api)


def main():
    event = json.loads(Path(os.environ["GITHUB_EVENT_PATH"]).read_text())
    run = event["workflow_run"]
    if (
        os.environ["GITHUB_REPOSITORY"] != REPOSITORY
        or run["event"] != "pull_request"
        or run["conclusion"] != "success"
        or run["repository"]["full_name"] != REPOSITORY
    ):
        return
    api = GitHub(os.environ["GH_TOKEN"])
    for number in sorted({pr["number"] for pr in run["pull_requests"]}):
        recover_head = run["head_sha"] if int(os.environ.get("GITHUB_RUN_ATTEMPT", "1")) > 1 else None
        merge(api, number, recover_head)


if __name__ == "__main__":
    main()
