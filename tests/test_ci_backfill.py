import io
import json
import subprocess
import unittest
from unittest.mock import Mock, call, patch
from urllib.error import HTTPError

from ci.backfill import backfill, narinfo_key, query_present


def store_path(index):
    return f"/nix/store/{index:032d}-output"


class PresenceTests(unittest.TestCase):
    @patch("ci.backfill.urlopen")
    @patch("ci.backfill.subprocess.run")
    def test_bulk_query_uses_oidc_and_narinfo_keys(self, run, urlopen):
        run.return_value.stdout = json.dumps({"token": "test-token"})
        key = narinfo_key(store_path(1))
        urlopen.return_value.__enter__.return_value = io.StringIO(json.dumps({"present": [key]}))
        self.assertEqual(query_present("https://cache.invalid/", "node '/tmp/token script'", [key]), {key})
        request = urlopen.call_args.args[0]
        self.assertEqual(request.full_url, "https://cache.invalid/api/objects/present")
        self.assertEqual(request.method, "POST")
        self.assertEqual(json.loads(request.data), {"keys": [key]})
        self.assertEqual(request.get_header("Authorization"), "Bearer test-token")
        self.assertEqual(run.call_args.args[0], ["node", "/tmp/token script"])

    @patch("ci.backfill.time.sleep")
    @patch("ci.backfill.urlopen")
    @patch("ci.backfill.subprocess.run")
    def test_transient_errors_retry_with_a_fresh_token(self, run, urlopen, sleep):
        run.return_value.stdout = '{"token":"test-token"}'
        response = Mock()
        response.__enter__ = Mock(return_value=io.StringIO('{"present":[]}'))
        response.__exit__ = Mock(return_value=False)
        urlopen.side_effect = [HTTPError("https://cache.invalid", 503, "unavailable", {}, None), response]
        self.assertEqual(query_present("https://cache.invalid", "node token", []), set())
        self.assertEqual(run.call_count, 2)
        sleep.assert_called_once()

    @patch("ci.backfill.urlopen")
    @patch("ci.backfill.subprocess.run")
    def test_authentication_and_malformed_responses_fail_closed(self, run, urlopen):
        run.return_value.stdout = '{"token":"test-token"}'
        urlopen.side_effect = HTTPError("https://cache.invalid", 403, "forbidden", {}, None)
        with self.assertRaises(HTTPError):
            query_present("https://cache.invalid", "node token", [])
        self.assertEqual(urlopen.call_count, 1)
        urlopen.side_effect = None
        for present in (None, "not-a-list", ["unexpected.narinfo"], [None]):
            with self.subTest(present=present):
                urlopen.return_value.__enter__.return_value = io.StringIO(json.dumps({"present": present}))
                with self.assertRaises(ValueError):
                    query_present("https://cache.invalid", "node token", [])

    def test_invalid_paths_are_rejected(self):
        for path in ("/tmp/output", "/nix/store/invalid-output", store_path(1) + "/child"):
            with self.subTest(path=path), self.assertRaises(ValueError):
                narinfo_key(path)

    def test_hash_uses_nix_base32_but_package_name_does_not(self):
        alphabet = "0123456789abcdfghijklmnpqrsvwxyz"
        self.assertEqual(narinfo_key(f"/nix/store/{alphabet}-eotu"), alphabet + ".narinfo")
        for letter in "eotuA":
            with self.subTest(letter=letter), self.assertRaises(ValueError):
                narinfo_key(f"/nix/store/{letter}{alphabet[1:]}-output")


class BackfillTests(unittest.TestCase):
    @patch("ci.backfill.subprocess.run")
    @patch("ci.backfill.query_present")
    def test_present_closures_are_refreshed_without_download_or_gc(self, query, run):
        path = store_path(1)
        query.return_value = {narinfo_key(path)}
        backfill([path, path], "https://cache.invalid", "node token", "niks3")
        query.assert_called_once_with("https://cache.invalid", "node token", [narinfo_key(path)])
        run.assert_not_called()

    @patch("ci.backfill.shutil.disk_usage", return_value=Mock(free=1024 ** 3))
    @patch("ci.backfill.subprocess.run")
    @patch("ci.backfill.query_present")
    def test_only_missing_roots_are_restored_and_gc_follows_each_upload(self, query, run, disk):
        paths = [store_path(i) for i in range(6)]
        query.return_value = {narinfo_key(paths[0])}
        backfill(paths, "https://cache.invalid", "node token", "niks3", batch_size=3)
        expected = []
        for batch in (paths[1:4], paths[4:]):
            expected.extend([
                call(["nix-store", "--realise", *batch, "--max-jobs", "0", "--option", "builders", ""], check=True),
                call(["niks3", "push", "--auth-token-script", "node token", *batch], check=True),
                call(["nix-store", "--gc"], check=True),
            ])
        self.assertEqual(run.call_args_list, expected)

    @patch("ci.backfill.QUERY_BATCH_SIZE", 2)
    @patch("ci.backfill.subprocess.run")
    @patch("ci.backfill.query_present", side_effect=lambda url, token, keys: set(keys))
    def test_presence_queries_are_bounded(self, query, run):
        paths = [store_path(i) for i in range(5)]
        backfill(paths, "https://cache.invalid", "node token", "niks3")
        self.assertEqual([len(args.args[2]) for args in query.call_args_list], [2, 2, 1])
        run.assert_not_called()

    @patch("ci.backfill.subprocess.run")
    @patch("ci.backfill.query_present")
    def test_query_or_upload_failure_stops_backfill(self, query, run):
        query.side_effect = RuntimeError("query failed")
        with self.assertRaises(RuntimeError):
            backfill([store_path(1)], "https://cache.invalid", "node token", "niks3")
        run.assert_not_called()
        query.side_effect = None
        query.return_value = set()
        run.side_effect = [Mock(), subprocess.CalledProcessError(1, ["niks3", "push"])]
        with self.assertRaises(subprocess.CalledProcessError):
            backfill([store_path(1), store_path(2)], "https://cache.invalid", "node token", "niks3", batch_size=1)
        self.assertEqual(run.call_count, 2)  # No GC or next batch after a failed push.


if __name__ == "__main__":
    unittest.main()
