from contextlib import redirect_stdout
from io import StringIO
import json
from pathlib import Path
import tempfile
import unittest

from tools.run_factorio_tests import (
    DEPENDENCY_MODS,
    TEST_SUPPORT_MOD,
    format_duration,
    prepare_mods,
    print_case_result,
)


class FactorioTestRunnerTests(unittest.TestCase):
    def test_prepare_mods_loads_test_support_after_nullius_star(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            dependencies = root / "dependencies"
            dependencies.mkdir()
            for name in DEPENDENCY_MODS:
                (dependencies / f"{name}_1.0.0.zip").touch()

            run_mods = root / "mods"
            prepare_mods(run_mods, dependencies)

            support_link = run_mods / "factorio-test-support"
            self.assertTrue(support_link.is_symlink())
            self.assertEqual(support_link.resolve(), TEST_SUPPORT_MOD.resolve())
            mod_list = json.loads((run_mods / "mod-list.json").read_text())
            enabled = [entry["name"] for entry in mod_list["mods"]]
            self.assertEqual(enabled[-2:], ["nullius-star", "factorio-test-support"])

    def test_format_duration(self) -> None:
        self.assertEqual(format_duration(3.25), "3.2s")
        self.assertEqual(format_duration(60), "1m 0.0s")
        self.assertEqual(format_duration(3661.25), "1h 1m 1.2s")

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


if __name__ == "__main__":
    unittest.main()
