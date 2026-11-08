import subprocess
import unittest
from unittest.mock import Mock, patch

from ci.matrix import query_requisites, split_matrix


def row(attr, drv, system="x86_64-linux", *additional_drvs):
    return {
        "attr": attr,
        "name": attr,
        "system": system,
        "os": ["runner"],
        "drvPath": drv,
        "installables": " ".join(f"{path}^*" for path in (drv, *additional_drvs)),
    }


class MatrixTests(unittest.TestCase):
    def test_only_transitive_dependencies_block_configurations(self):
        direct = row("packages.x86_64-linux.direct", "/nix/store/direct.drv")
        transitive = row("packages.x86_64-linux.transitive", "/nix/store/transitive.drv")
        unused = row("packages.x86_64-linux.unused", "/nix/store/unused.drv")
        # An overridden package with the same name has a different derivation.
        overridden = row("packages.x86_64-linux.overridden", "/nix/store/original.drv")
        check = row("checks.x86_64-linux.test", "/nix/store/check.drv")
        config = row("homeConfigurations.user@host", "/nix/store/home.drv")
        query = Mock(return_value={
            "/nix/store/home.drv", "/nix/store/direct.drv",
            "/nix/store/transitive.drv", "/nix/store/overridden.drv",
        })
        platform = split_matrix({"include": [direct, transitive, unused, overridden, check, config]}, query)["include"][0]
        self.assertEqual(platform["packages"]["include"], [direct, transitive])
        self.assertEqual(platform["other-packages"]["include"], [unused, overridden, check])
        self.assertEqual(platform["configurations"]["include"], [config])
        self.assertTrue(platform["any-packages"])
        self.assertTrue(platform["any-other-packages"])
        self.assertTrue(platform["any-configurations"])
        query.assert_called_once_with(["/nix/store/home.drv"])

    def test_all_grouped_derivations_are_considered(self):
        grouped = row("packages.x86_64-linux.unused-first", "/nix/store/unused.drv", "x86_64-linux", "/nix/store/needed.drv")
        config = row("nixosConfigurations.first", "/nix/store/first.drv", "x86_64-linux", "/nix/store/second.drv")
        query = Mock(return_value={"/nix/store/needed.drv"})
        platform = split_matrix({"include": [grouped, config]}, query)["include"][0]
        self.assertEqual(platform["packages"]["include"], [grouped])
        self.assertFalse(platform["any-other-packages"])
        query.assert_called_once_with(["/nix/store/first.drv", "/nix/store/second.drv"])

    def test_platforms_query_their_own_configurations(self):
        linux = row("packages.x86_64-linux.linux", "/nix/store/linux.drv")
        arm = row("packages.aarch64-linux.arm", "/nix/store/arm.drv", "aarch64-linux")
        darwin = row("packages.aarch64-darwin.mac", "/nix/store/mac.drv", "aarch64-darwin")
        home = row("homeConfigurations.home", "/nix/store/home.drv")
        nixos = row("nixosConfigurations.arm", "/nix/store/nixos.drv", "aarch64-linux")
        mac = row("darwinConfigurations.mac", "/nix/store/darwin.drv", "aarch64-darwin")
        dependencies = {
            "/nix/store/home.drv": {"/nix/store/linux.drv"},
            "/nix/store/nixos.drv": set(),
            "/nix/store/darwin.drv": {"/nix/store/mac.drv"},
        }
        query = Mock(side_effect=lambda roots: dependencies[roots[0]])
        result = split_matrix({"include": [linux, arm, darwin, home, nixos, mac]}, query)
        platforms = {platform["system"]: platform for platform in result["include"]}
        self.assertEqual(platforms["x86_64-linux"]["packages"]["include"], [linux])
        self.assertEqual(platforms["aarch64-darwin"]["packages"]["include"], [darwin])
        self.assertFalse(platforms["aarch64-linux"]["any-packages"])
        self.assertEqual(platforms["aarch64-linux"]["other-packages"]["include"], [arm])
        self.assertCountEqual(query.call_args_list, [unittest.mock.call([root]) for root in dependencies])

    def test_empty_or_cached_categories_need_no_query(self):
        package = row("packages.x86_64-linux.package", "/nix/store/package.drv")
        config = row("nixosConfigurations.host", "/nix/store/host.drv")
        for rows in ([], [package], [config]):
            with self.subTest(rows=rows):
                query = Mock(side_effect=AssertionError("unexpected store query"))
                result = split_matrix({"include": rows}, query)
                if rows:
                    platform = result["include"][0]
                    self.assertFalse(platform["any-packages"])
                    self.assertEqual(platform["any-other-packages"], rows == [package])
                    self.assertEqual(platform["any-configurations"], rows == [config])
                else:
                    self.assertEqual(result, {"include": []})
                query.assert_not_called()

    def test_query_failure_stops_matrix_generation(self):
        package = row("packages.x86_64-linux.package", "/nix/store/package.drv")
        config = row("nixosConfigurations.host", "/nix/store/host.drv")
        query = Mock(side_effect=subprocess.CalledProcessError(1, ["nix-store"]))
        with self.assertRaises(subprocess.CalledProcessError):
            split_matrix({"include": [package, config]}, query)

    @patch("ci.matrix.subprocess.run")
    def test_query_reads_derivation_closure_without_realising_outputs(self, run):
        run.return_value.stdout = "/nix/store/root.drv\n/nix/store/dependency.drv\n"
        self.assertEqual(query_requisites(["/nix/store/root.drv"]), {"/nix/store/root.drv", "/nix/store/dependency.drv"})
        run.assert_called_once_with(
            ["nix-store", "--query", "--requisites", "/nix/store/root.drv"],
            check=True, stdout=subprocess.PIPE, text=True,
        )


if __name__ == "__main__":
    unittest.main()
