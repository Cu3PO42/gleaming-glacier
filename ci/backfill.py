"""Refresh cached closures in niks3 and restore/upload only missing roots."""

import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import time
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


QUERY_BATCH_SIZE = 500
RESTORE_BATCH_SIZE = 4


def narinfo_key(path):
    match = re.fullmatch(r"/nix/store/([0-9abcdfghijklmnpqrsvwxyz]{32})-[^/\s]+", path)
    if not match:
        raise ValueError(f"Invalid store path: {path!r}")
    return match[1] + ".narinfo"


def query_present(server_url, token_script, keys):
    # Renew the OIDC token for each request/retry; never log it.
    for attempt in range(3):
        token = json.loads(subprocess.run(
            shlex.split(token_script), check=True, capture_output=True, text=True,
        ).stdout)["token"]
        request = Request(
            server_url.rstrip("/") + "/api/objects/present",
            data=json.dumps({"keys": keys}).encode(),
            headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
            method="POST",
        )
        try:
            with urlopen(request, timeout=60) as response:
                present = json.load(response)["present"]
            if (not isinstance(present, list)
                    or any(not isinstance(key, str) or key not in keys for key in present)):
                raise ValueError("Invalid niks3 presence response")
            return set(present)
        except HTTPError as error:
            if error.code != 429 and error.code < 500:
                raise
            if attempt == 2:
                raise
        except (URLError, TimeoutError):
            if attempt == 2:
                raise
        time.sleep(2 ** attempt)


def backfill(paths, server_url, token_script, binary, batch_size=RESTORE_BATCH_SIZE):
    paths = sorted(set(paths))
    keys = [narinfo_key(path) for path in paths]
    missing = []
    for offset in range(0, len(paths), QUERY_BATCH_SIZE):
        batch_keys = keys[offset:offset + QUERY_BATCH_SIZE]
        present = query_present(server_url, token_script, batch_keys)
        missing.extend(path for path, key in zip(paths[offset:], batch_keys) if key not in present)

    print(f"niks3: {len(paths) - len(missing)} cached closures refreshed; "
          f"{len(missing)} missing roots to restore", flush=True)
    for offset in range(0, len(missing), batch_size):
        batch = missing[offset:offset + batch_size]
        # Substitute any platform's outputs; never build locally or remotely.
        subprocess.run([
            "nix-store", "--realise", *batch, "--max-jobs", "0", "--option", "builders", "",
        ], check=True)
        subprocess.run([binary, "push", "--auth-token-script", token_script, *batch], check=True)
        # This job has no builds. Release restored closures only after a successful push.
        subprocess.run(["nix-store", "--gc"], check=True)
        print(f"niks3: uploaded batch; {shutil.disk_usage('/nix/store').free // (1024 ** 2)} MiB free",
              flush=True)


if __name__ == "__main__":
    token_script = os.environ["NIKS3_AUTH_TOKEN_SCRIPT"]
    if not token_script:
        raise ValueError("Missing niks3 auth token script")
    backfill(json.loads(os.environ["CACHED_OUTPUTS"]), os.environ["NIKS3_SERVER_URL"],
             token_script, str(Path(os.environ["NIKS3_BIN"]) / "niks3"))
