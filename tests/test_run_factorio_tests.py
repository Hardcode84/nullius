from contextlib import redirect_stdout
from io import StringIO
import json
from pathlib import Path
import tempfile
import unittest
import zipfile

from tools.run_factorio_tests import (
    DEPENDENCY_MODS,
    MAX_UNTIL_TICK,
    MOD_UNDER_TEST,
    SCENARIOS,
    TEST_SUPPORT_MOD,
    TestFailure,
    format_duration,
    prepare_mods,
    print_case_result,
    safe_archive_members,
    validate_until_tick,
    write_result_json,
)


class FactorioTestRunnerTests(unittest.TestCase):
    def test_distributable_mod_excludes_repository_only_content(self) -> None:
        self.assertEqual(list(MOD_UNDER_TEST.glob("*.md")), [])
        self.assertFalse((MOD_UNDER_TEST / "scenarios").exists())
        self.assertFalse((MOD_UNDER_TEST / "progression").exists())

    def test_prepare_mods_loads_test_support_after_nullius_star(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            dependencies = root / "dependencies"
            dependencies.mkdir()
            for name in DEPENDENCY_MODS:
                (dependencies / f"{name}_1.0.0.zip").touch()

            run_mods = root / "mods"
            prepare_mods(run_mods, dependencies)

            staged_mod = run_mods / "nullius-star"
            self.assertTrue(staged_mod.is_dir())
            self.assertFalse(staged_mod.is_symlink())
            self.assertEqual(
                (staged_mod / "info.json").resolve(),
                (MOD_UNDER_TEST / "info.json").resolve(),
            )
            self.assertEqual((staged_mod / "scenarios").resolve(), SCENARIOS.resolve())
            support_link = run_mods / "factorio-test-support"
            self.assertTrue(support_link.is_symlink())
            self.assertEqual(support_link.resolve(), TEST_SUPPORT_MOD.resolve())
            mod_list = json.loads((run_mods / "mod-list.json").read_text())
            enabled = [entry["name"] for entry in mod_list["mods"]]
            self.assertEqual(enabled[-2:], ["nullius-star", "factorio-test-support"])

    def test_prepare_mods_accepts_release_archive(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            dependencies = root / "dependencies"
            dependencies.mkdir()
            for name in DEPENDENCY_MODS:
                (dependencies / f"{name}_1.0.0.zip").touch()
            release = root / "nullius-star_1.2.3.zip"
            with zipfile.ZipFile(release, "w") as archive:
                archive.writestr("nullius-star/info.json", "{}")
                archive.writestr("nullius-star/data.lua", "")

            run_mods = root / "mods"
            prepare_mods(run_mods, dependencies, release)

            self.assertEqual((run_mods / "nullius-star" / "data.lua").read_text(), "")
            self.assertEqual(
                (run_mods / "nullius-star" / "scenarios").resolve(),
                SCENARIOS.resolve(),
            )

    def test_archive_rejects_entries_outside_mod_root(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            release = Path(temporary) / "invalid.zip"
            with zipfile.ZipFile(release, "w") as writer:
                writer.writestr("nullius-star/info.json", "{}")
                writer.writestr("../escape", "")
            with zipfile.ZipFile(release) as archive:
                with self.assertRaisesRegex(TestFailure, "outside nullius-star"):
                    safe_archive_members(archive, "nullius-star")

    def test_format_duration(self) -> None:
        self.assertEqual(format_duration(3.25), "3.2s")
        self.assertEqual(format_duration(60), "1m 0.0s")
        self.assertEqual(format_duration(3661.25), "1h 1m 1.2s")

    def test_result_json_is_written_for_progress_mode(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            destination = Path(temporary) / "nested" / "result.json"
            write_result_json(destination, {"status": "pass", "passed": 2})
            self.assertEqual(
                json.loads(destination.read_text()),
                {"status": "pass", "passed": 2},
            )

    def test_completion_line_includes_duration(self) -> None:
        output = StringIO()
        with redirect_stdout(output):
            print_case_result(
                2,
                3,
                "example",
                {
                    "status": "pass",
                    "assertions": 7,
                    "tick": 42,
                    "factorio_version": "2.0.77",
                    "duration_seconds": 65.5,
                },
            )
        self.assertEqual(
            output.getvalue(),
            "[2/3] PASS example - 7 assertions, completed tick 42, "
            "Factorio 2.0.77, 1m 5.5s\n",
        )

    def test_until_tick_accepts_repository_maximum(self) -> None:
        self.assertEqual(validate_until_tick(MAX_UNTIL_TICK, "test"), MAX_UNTIL_TICK)

    def test_until_tick_rejects_value_above_repository_maximum(self) -> None:
        with self.assertRaisesRegex(
            TestFailure,
            rf"{MAX_UNTIL_TICK + 1} exceeds repository maximum {MAX_UNTIL_TICK}",
        ):
            validate_until_tick(MAX_UNTIL_TICK + 1, "test")


if __name__ == "__main__":
    unittest.main()
