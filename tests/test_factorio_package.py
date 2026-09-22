import json
from pathlib import Path
import tempfile
import unittest
import zipfile

from tools.factorio_package import build_packages, engine_series, package_metadata, workspace_target
from tools.run_factorio_tests import DEPENDENCY_MODS, MOD_UNDER_TEST, TestFailure, prepare_mods


class FactorioPackageTests(unittest.TestCase):
    def test_both_packages_share_payload_and_preserve_source(self):
        manifest = MOD_UNDER_TEST / "info.json"
        before = manifest.read_bytes()
        self.assertEqual(package_metadata(json.loads(before), "2.1"), json.loads(before))
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            archives = build_packages(root, "both")
            payloads = []
            for target, archive in zip(("2.0", "2.1"), archives):
                self.assertEqual(archive.parent, root / target)
                with zipfile.ZipFile(archive) as reader:
                    payload = {name: reader.read(name) for name in reader.namelist()}
                metadata = json.loads(payload.pop("nullius-star/info.json"))
                self.assertEqual(metadata["factorio_version"], target)
                self.assertEqual(archive.name, f'nullius-star_{metadata["version"]}.zip')
                for requirement in ({"base >= 2.0.73", "boblogistics >= 2.0.6",
                                     "configurable-valves >= 0.3.3", "(?) boblibrary >= 1.1.4"}
                                    if target == "2.0" else
                                    {"base >= 2.1.19", "boblogistics >= 3.0.1",
                                     "configurable-valves >= 2.0.2", "(?) boblibrary >= 3.0.0"}):
                    self.assertIn(requirement, metadata["dependencies"])
                payloads.append(payload)
            self.assertEqual(payloads[0], payloads[1])
            default = build_packages(root / "default")
            self.assertEqual(len(default), 1)
            self.assertEqual(default[0].read_bytes(), archives[1].read_bytes())
        self.assertEqual(manifest.read_bytes(), before)
        self.assertEqual(json.loads(before)["factorio_version"], "2.1")

    def test_staging_changes_only_private_manifest(self):
        before = (MOD_UNDER_TEST / "info.json").read_bytes()
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            dependencies = root / "dependencies"
            dependencies.mkdir()
            for name in DEPENDENCY_MODS:
                (dependencies / f"{name}_1.0.0.zip").touch()
            for target in ("2.0", "2.1"):
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
            for version in ("2.0.77", "2.1.19"):
                info.write_text(json.dumps({"version": version}))
                self.assertEqual(engine_series(root / "bin/x64/factorio"), version[:3])
                self.assertEqual(workspace_target(root / "bin/x64/factorio", MOD_UNDER_TEST), version[:3])
                self.assertIsNone(workspace_target(root / "bin/x64/factorio", root / "external"))
                self.assertIsNone(workspace_target(root / "bin/x64/factorio", root / "release.zip"))
            info.write_text(json.dumps({"version": "2.2.0"}))
            with self.assertRaisesRegex(ValueError, "Unsupported"):
                engine_series(root / "bin/x64/factorio")
        with self.assertRaisesRegex(ValueError, "Unsupported"):
            package_metadata({}, "2.2")
