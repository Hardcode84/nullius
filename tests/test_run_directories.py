"""Unit tests for bounded Factorio run directories."""
import os
from pathlib import Path
import sys
import tempfile
import time
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import run_directories


def age(path: Path, seconds: float) -> None:
    moment = time.time() - seconds
    os.utime(path, (moment, moment), follow_symlinks=False)


class RunDirectoriesTest(unittest.TestCase):
    def setUp(self):
        self.scratch = tempfile.TemporaryDirectory()
        self.root = Path(self.scratch.name) / "runs"

    def tearDown(self):
        self.scratch.cleanup()

    def test_create_makes_a_prefixed_directory_under_the_root(self):
        run = run_directories.create("factorio-test-case-", self.root)
        self.assertTrue(run.is_dir())
        self.assertEqual(run.parent, self.root)
        self.assertTrue(run.name.startswith("factorio-test-case-"))

    def test_create_prunes_only_entries_past_retention(self):
        stale = run_directories.create("old-", self.root)
        (stale / "artifact.log").write_text("kept as evidence")
        age(stale, run_directories.RETENTION_SECONDS + 60)
        recent = run_directories.create("recent-", self.root)
        age(recent, run_directories.RETENTION_SECONDS - 60)
        current = run_directories.create("current-", self.root)
        self.assertFalse(stale.exists())
        self.assertTrue(recent.is_dir())
        self.assertTrue(current.is_dir())

    def test_stale_symlink_is_unlinked_without_following_it(self):
        target = Path(self.scratch.name) / "outside"
        target.mkdir()
        self.root.mkdir()
        link = self.root / "link"
        link.symlink_to(target, target_is_directory=True)
        age(link, run_directories.RETENTION_SECONDS + 60)
        self.assertEqual(run_directories.prune(self.root), [link])
        self.assertTrue(target.is_dir())

    def test_prune_without_a_root_does_nothing(self):
        self.assertEqual(run_directories.prune(self.root), [])


if __name__ == "__main__":
    unittest.main()
