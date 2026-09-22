"""Native dependency source staging must preserve committed manifests and files."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from assess_factorio_port import stage_source_dependency


class DependencySourceTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        root = Path(self.temporary.name)
        self.repository = root / "source"
        self.repository.mkdir()
        self.output = root / "mods"
        self.output.mkdir()
        self.git("init", "-q")
        self.manifest = {"name": "configurable-valves", "version": "2.0.2",
                         "factorio_version": "2.1"}
        (self.repository / "info.json").write_text(json.dumps(self.manifest))
        (self.repository / "control.lua").write_text("return 'committed'\n")
        self.git("add", ".")
        self.git("-c", "user.name=Test", "-c", "user.email=test@example.invalid",
                 "-c", "core.hooksPath=/dev/null", "commit", "-qm", "fixture")

    def git(self, *args):
        return subprocess.check_output(["git", "-C", str(self.repository), *args])

    def test_committed_contents_and_provenance(self):
        (self.repository / "control.lua").write_text("uncommitted change")
        (self.repository / "untracked.lua").write_text("untracked")
        result = stage_source_dependency("configurable-valves", self.repository,
                                         "2.1", self.output)
        self.assertEqual(result["source_commit"], self.git("rev-parse", "HEAD").decode().strip())
        archive = self.output / "configurable-valves_2.0.2.zip"
        with zipfile.ZipFile(archive) as contents:
            prefix = "configurable-valves_2.0.2/"
            self.assertEqual(json.loads(contents.read(prefix + "info.json")), self.manifest)
            self.assertEqual(contents.read(prefix + "control.lua"), b"return 'committed'\n")
            self.assertNotIn(prefix + "untracked.lua", contents.namelist())
        with self.assertRaises(FileExistsError):
            stage_source_dependency("configurable-valves", self.repository, "2.1", self.output)

    def test_native_version_required(self):
        with self.assertRaisesRegex(ValueError, "does not target"):
            stage_source_dependency("configurable-valves", self.repository, "2.0", self.output)
        self.assertEqual(list(self.output.iterdir()), [])

    def test_name_required(self):
        with self.assertRaisesRegex(ValueError, "name mismatch"):
            stage_source_dependency("boblibrary", self.repository, "2.1", self.output)
        self.assertEqual(list(self.output.iterdir()), [])


if __name__ == "__main__":
    unittest.main()
