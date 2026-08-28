from contextlib import redirect_stdout
from io import StringIO
import unittest

from tools.run_factorio_tests import format_duration, print_case_result


class FactorioTestRunnerTests(unittest.TestCase):
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
