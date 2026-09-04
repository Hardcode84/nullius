import hashlib
from pathlib import Path
import tempfile
import unittest
import zipfile

from tools.build_release import build_archive


class ReleaseBuilderTests(unittest.TestCase):
    def test_archive_contains_only_distributable_root(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            archive_path = build_archive(Path(temporary), {"version": "0.0.1"})
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
            first_archive = build_archive(Path(first), {"version": "0.0.1"})
            second_archive = build_archive(Path(second), {"version": "0.0.1"})
            self.assertEqual(
                hashlib.sha256(first_archive.read_bytes()).digest(),
                hashlib.sha256(second_archive.read_bytes()).digest(),
            )


if __name__ == "__main__":
    unittest.main()
