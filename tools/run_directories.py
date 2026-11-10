"""Directories for Factorio tool runs.

Every run gets a directory under one repository-owned root. Runs may keep their
directory as evidence; creating a run deletes entries in the root older than
the retention window, so kept runs cannot accumulate without bound. A live run
is never that old, so concurrent runs are safe, and nothing outside the root is
touched.
"""
import shutil
import tempfile
import time
from pathlib import Path

ROOT = Path(tempfile.gettempdir()) / "nullius-runs"
RETENTION_SECONDS = 3 * 24 * 60 * 60


def _ignore_vanished(function, path, error):
    """Let a concurrent run delete the same stale entry first."""
    if not isinstance(error, FileNotFoundError):
        raise error


def prune(root: Path = ROOT, now: float | None = None) -> list[Path]:
    """Delete root entries older than the retention window and return them."""
    cutoff = (time.time() if now is None else now) - RETENTION_SECONDS
    removed = []
    for entry in sorted(root.iterdir()) if root.is_dir() else []:
        try:
            stale = entry.lstat().st_mtime < cutoff
        except FileNotFoundError:
            continue
        if not stale:
            continue
        if entry.is_dir() and not entry.is_symlink():
            shutil.rmtree(entry, onexc=_ignore_vanished)
        else:
            entry.unlink(missing_ok=True)
        removed.append(entry)
    return removed


def create(prefix: str, root: Path = ROOT) -> Path:
    """Prune stale runs, then create and return a new run directory."""
    root.mkdir(parents=True, exist_ok=True)
    prune(root)
    return Path(tempfile.mkdtemp(prefix=prefix, dir=root))

