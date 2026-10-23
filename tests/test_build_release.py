import hashlib
import json
from pathlib import Path
import tempfile
import unittest
import zipfile
from unittest.mock import patch

from tools.build_release import (build_archive, read_metadata, run_progression_contracts,
                                 run_bootstrap_checks, TestFailure)


class ReleaseBuilderTests(unittest.TestCase):
    def test_progression_runs_declared_contracts_only(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "release.json").write_text(json.dumps({"contracts": ["endpoint.args"]}))
            (root / "endpoint.args").touch()
            (root / "arrival-diagnostic.args").touch()
            with patch("tools.build_release.PROGRESSION_CONTRACTS", root), \
                 patch("tools.build_release.run_checked") as run:
                self.assertEqual(run_progression_contracts(root / "dump.json", 10), 1)
                self.assertIn("@" + str(root / "endpoint.args"), run.call_args.args[0])
                self.assertEqual(run.call_count, 1)
                run.side_effect = TestFailure("blocked endpoint")
                with self.assertRaisesRegex(TestFailure, "blocked endpoint"):
                    run_progression_contracts(root / "dump.json", 10)

    def test_bootstrap_rejects_blocked_research_and_uses_packaged_dump(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "release.json").write_text(json.dumps({"bootstrap": [
                {"name": "planet", "planner": "plan.json", "config": "bootstrap.json"}]}))
            (root / "planet-bootstrap.json").write_text(json.dumps({
                "blocked_targets": [], "unreached_research": ["physics"]}))
            with patch("tools.build_release.PROGRESSION_CONTRACTS", root), \
                 patch("tools.build_release.run_checked") as run:
                with self.assertRaisesRegex(TestFailure, "blocked targets or research"):
                    run_bootstrap_checks(root / "packaged.json", 10, root)
                self.assertEqual(run.call_count, 2)
                for call in run.call_args_list:
                    command = call.args[0]
                    self.assertEqual(command[command.index("--data-raw") + 1], str(root / "packaged.json"))

    def test_release_metadata_requires_2_1(self):
        with tempfile.TemporaryDirectory() as temporary:
            mod = Path(temporary)
            (mod / "changelog.txt").write_text("Version: 1.0.0\n")
            metadata = {"name": "nullius-star", "version": "1.0.0", "dependencies": ["! nullius"]}
            with patch("tools.build_release.MOD_DIRECTORY", mod):
                for version in ("2.0", "2.1", "2.2"):
                    metadata["factorio_version"] = version
                    (mod / "info.json").write_text(json.dumps(metadata))
                    if version != "2.1":
                        with self.assertRaisesRegex(TestFailure, "factorio_version"):
                            read_metadata()
                    else:
                        self.assertEqual(read_metadata()["factorio_version"], version)

    def test_archive_contains_only_distributable_root(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            archive_path = build_archive(Path(temporary), read_metadata())
            with zipfile.ZipFile(archive_path) as archive:
                names = archive.namelist()
            self.assertIn("nullius-star/info.json", names)
            self.assertTrue(names)
            self.assertTrue(all(name.startswith("nullius-star/") for name in names))
            self.assertFalse(any(name.startswith("tests/") for name in names))
            self.assertFalse(any(name.startswith("tools/") for name in names))
            self.assertFalse(any("/migrations/" in name for name in names))
            self.assertNotIn("nullius-star/scripts/migrate.lua", names)
            self.assertNotIn("nullius-star/legacyMirror.lua", names)
            self.assertNotIn("nullius-star/legacyValves.lua", names)

    def test_archive_is_reproducible(self) -> None:
        with (
            tempfile.TemporaryDirectory() as first,
            tempfile.TemporaryDirectory() as second,
        ):
            first_archive = build_archive(Path(first), read_metadata())
            second_archive = build_archive(Path(second), read_metadata())
            self.assertEqual(
                hashlib.sha256(first_archive.read_bytes()).digest(),
                hashlib.sha256(second_archive.read_bytes()).digest(),
            )


if __name__ == "__main__":
    unittest.main()
