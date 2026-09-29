import json
from pathlib import Path
import tempfile
import unittest
import zipfile

from tools.factorio_package import build_packages, engine_series, package_metadata, workspace_target
from tools.run_factorio_tests import DEPENDENCY_MODS, MOD_UNDER_TEST, TestFailure, prepare_mods


class FactorioPackageTests(unittest.TestCase):
    def test_package_targets_2_1_and_preserves_source(self):
        manifest = MOD_UNDER_TEST / "info.json"
        before = manifest.read_bytes()
        self.assertEqual(package_metadata(json.loads(before), "2.1"), json.loads(before))
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            archives = build_packages(root)
            self.assertEqual(len(archives), 1)
            self.assertEqual(archives[0].parent, root / "2.1")
            with zipfile.ZipFile(archives[0]) as reader:
                metadata = json.loads(reader.read("nullius-star/info.json"))
            self.assertEqual(metadata, json.loads(before))
            for target in ("2.0", "both", "2.2"):
                with self.assertRaisesRegex(ValueError, "Unsupported"):
                    build_packages(root, target)
                self.assertFalse((root / target).exists())
        self.assertEqual(manifest.read_bytes(), before)

    def test_staging_changes_only_private_manifest(self):
        before = (MOD_UNDER_TEST / "info.json").read_bytes()
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            dependencies = root / "dependencies"
            dependencies.mkdir()
            for name in DEPENDENCY_MODS:
                (dependencies / f"{name}_1.0.0.zip").touch()
            target = "2.1"
            mods = root / target
            prepare_mods(mods, dependencies, MOD_UNDER_TEST, target)
            self.assertFalse((mods / "nullius-star/info.json").is_symlink())
            for name in ("nullius-star", "factorio-test-support"):
                metadata = json.loads((mods / name / "info.json").read_text())
                self.assertEqual(metadata["factorio_version"], target)
            with self.assertRaisesRegex(TestFailure, "ZIPs unchanged"):
                prepare_mods(root / "rejected", dependencies, root / "release.zip", "2.0")
        self.assertEqual((MOD_UNDER_TEST / "info.json").read_bytes(), before)

    def test_engine_selection_and_unsupported_targets(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            info = root / "data/base/info.json"
            info.parent.mkdir(parents=True)
            version = "2.1.19"
            info.write_text(json.dumps({"version": version}))
            self.assertEqual(engine_series(root / "bin/x64/factorio"), version[:3])
            self.assertEqual(workspace_target(root / "bin/x64/factorio", MOD_UNDER_TEST), version[:3])
            self.assertIsNone(workspace_target(root / "bin/x64/factorio", root / "external"))
            self.assertIsNone(workspace_target(root / "bin/x64/factorio", root / "release.zip"))
            for version in ("2.0.77", "2.2.0"):
                info.write_text(json.dumps({"version": version}))
                with self.assertRaisesRegex(ValueError, "Unsupported"):
                    engine_series(root / "bin/x64/factorio")
        with self.assertRaisesRegex(ValueError, "Unsupported"):
            package_metadata({}, "2.2")
