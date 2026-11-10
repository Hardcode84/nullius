import contextlib
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
from types import SimpleNamespace
import unittest
import zipfile
from unittest.mock import patch

import tools.build_release as build_release

from tools.build_release import (build_archive, historical_engine, read_metadata, run_progression_contracts,
                                 run_bootstrap_checks, run_unlock_audits, prepare_release_mods,
                                 TestFailure)


def engine_archive(root: Path, name: str, binary: bool) -> Path:
    staging = root / ("staging-" + name)
    (staging / "factorio" / "bin" / "x64").mkdir(parents=True)
    if binary:
        (staging / "factorio" / "bin" / "x64" / "factorio").write_text("engine")
    archive = root / (name + ".tar.xz")
    subprocess.run(["tar", "-cJf", str(archive), "-C", str(staging), "factorio"], check=True)
    return archive


class HistoricalEngineTests(unittest.TestCase):
    def test_archive_unpacks_once_into_the_cache(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            archive = engine_archive(root, "factorio-space-age_linux_2.1.19", True)
            binary = historical_engine(archive, root / "cache")
            self.assertEqual(binary, root / "cache/factorio-space-age_linux_2.1.19/factorio/bin/x64/factorio")
            self.assertEqual(binary.read_text(), "engine")
            archive.unlink()
            self.assertEqual(historical_engine(archive, root / "cache"), binary)
            self.assertEqual(sorted(path.name for path in (root / "cache").iterdir()),
                             ["factorio-space-age_linux_2.1.19"])

    def test_binary_is_used_as_given(self):
        with tempfile.TemporaryDirectory() as temporary:
            binary = Path(temporary) / "factorio"
            binary.write_text("engine")
            self.assertEqual(historical_engine(binary, Path(temporary) / "cache"), binary.resolve())
            self.assertFalse((Path(temporary) / "cache").exists())

    def test_archive_without_engine_leaves_no_cache_entry(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            archive = engine_archive(root, "broken", False)
            with self.assertRaises(TestFailure):
                historical_engine(archive, root / "cache")
            self.assertEqual(list((root / "cache").iterdir()), [])


class ReleaseBuilderTests(unittest.TestCase):
    def test_release_disables_quality_but_historical_fixtures_enable_it(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            archive = root / "nullius-star_0.0.6.zip"
            archive.touch()
            with patch("tools.build_release.DEPENDENCY_MODS", []):
                for historical in (False, True):
                    mods = root / str(historical)
                    prepare_release_mods(mods, root, archive, historical_quality=historical)
                    entries = json.loads((mods / "mod-list.json").read_text())["mods"]
                    self.assertEqual([row for row in entries if row["name"] == "quality"],
                                     [{"name": "quality", "enabled": historical}])

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

    def test_unlock_audits_check_declared_configs_against_packaged_dump(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "release.json").write_text(json.dumps({"unlock_audits": ["planet.json"]}))
            with patch("tools.build_release.PROGRESSION_CONTRACTS", root), \
                 patch("tools.build_release.run_checked") as run:
                self.assertEqual(run_unlock_audits(root / "packaged.json", 10, root), 1)
                command = run.call_args.args[0]
                self.assertIn("--check", command)
                self.assertEqual(command[command.index("--data-raw") + 1], str(root / "packaged.json"))
                self.assertEqual(command[command.index("--config") + 1], str(root / "planet.json"))
                run.side_effect = TestFailure("bulk bypass")
                with self.assertRaisesRegex(TestFailure, "bulk bypass"):
                    run_unlock_audits(root / "packaged.json", 10, root)

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
            self.assertEqual({name for name in names if "/migrations/" in name}, {
                "nullius-star/migrations/antiproton-capture.lua",
                "nullius-star/migrations/nuclear-reactor.lua",
                "nullius-star/migrations/radio-astronomy.lua",
                "nullius-star/migrations/upstream-progression.json",
                "nullius-star/migrations/upstream-progression.lua",
                "nullius-star/migrations/uranium-enrichment.lua",
            })
            self.assertNotIn("nullius-star/scripts/migrate.lua", names)
            self.assertNotIn("nullius-star/legacyMirror.lua", names)
            self.assertNotIn("nullius-star/legacyValves.lua", names)

    def test_dry_run_builds_in_a_removed_directory(self) -> None:
        with contextlib.ExitStack() as stack:
            directory = build_release.output_directory(
                SimpleNamespace(dry_run=True, output_directory=None), stack)
            self.assertTrue(directory.is_dir())
            self.assertNotEqual(directory, build_release.REPOSITORY / "release")
        self.assertFalse(directory.exists())
        with contextlib.ExitStack() as stack:
            self.assertEqual(build_release.output_directory(
                SimpleNamespace(dry_run=False, output_directory=None), stack),
                (build_release.REPOSITORY / "release").resolve())

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
