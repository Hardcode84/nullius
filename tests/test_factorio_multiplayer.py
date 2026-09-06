"""Isolation and error cleanup for software-only multiplayer displays."""

import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from tools.factorio_multiplayer import client_environment, validate_client_log, virtual_display
from tools.run_factorio_tests import TestFailure


class MultiplayerDisplayTests(unittest.TestCase):
    def test_hardware_renderer_cannot_pass_a_software_test(self):
        with tempfile.TemporaryDirectory() as directory:
            log = Path(directory) / "client.log"
            log.write_text("Initialised OpenGL:[0] AMD Radeon\nInGame\n")
            with self.assertRaisesRegex(TestFailure, "software rendering"):
                validate_client_log(log)
            log.write_text("Initialised OpenGL:[0] llvmpipe (LLVM 20)\nInGame\n")
            validate_client_log(log)
            log.write_text("Initialised OpenGL:[0] llvmpipe (LLVM 20)\nInGame\nDesync\n")
            with self.assertRaisesRegex(TestFailure, "did not run cleanly"):
                validate_client_log(log)

    def test_display_process_is_stopped_after_body_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            xvfb = root / "Xvfb"
            xvfb.write_text("#!/usr/bin/env python3\nimport os, sys, time\n"
                            "os.write(int(sys.argv[sys.argv.index('-displayfd') + 1]), b'27\\n')\n"
                            "time.sleep(30)\n")
            xvfb.chmod(0o700)
            with patch("tools.factorio_multiplayer.shutil.which", return_value=str(xvfb)), patch(
                    "tools.factorio_multiplayer.subprocess.run") as authorize:
                authorize.return_value.returncode = 0
                with self.assertRaisesRegex(RuntimeError, "scenario failure"):
                    with virtual_display(root, 2) as (process, environment):
                        self.assertEqual(environment["DISPLAY"], ":27")
                        self.assertIsNone(process.poll())
                        raise RuntimeError("scenario failure")
                self.assertIsNotNone(process.poll())
                self.assertFalse((root / "Xauthority").exists())

    def test_display_startup_exit_reports_log(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            xvfb = root / "Xvfb"
            xvfb.write_text("#!/bin/sh\necho 'display startup failed'\nexit 3\n")
            xvfb.chmod(0o700)
            with patch("tools.factorio_multiplayer.shutil.which", return_value=str(xvfb)), patch(
                    "tools.factorio_multiplayer.subprocess.run") as authorize:
                authorize.return_value.returncode = 0
                with self.assertRaisesRegex(TestFailure, "display startup failed"):
                    with virtual_display(root, 2):
                        self.fail("failed display must not launch clients")
                self.assertFalse((root / "Xauthority").exists())

    def test_client_cannot_inherit_desktop_or_hardware_renderer(self):
        with patch.dict(os.environ, {
            "DISPLAY": ":99", "WAYLAND_DISPLAY": "desktop", "XAUTHORITY": "desktop-cookie",
            "FACTORIO_CLIENT_DISPLAY": ":98", "SDL_VIDEODRIVER": "wayland",
            "DRI_PRIME": "1", "LIBGL_ALWAYS_SOFTWARE": "0", "GALLIUM_DRIVER": "radeonsi",
            "MESA_LOADER_DRIVER_OVERRIDE": "iris", "LIBGL_ALWAYS_INDIRECT": "1",
            "__GLX_VENDOR_LIBRARY_NAME": "nvidia",
        }):
            environment = client_environment(":17", Path("private-cookie"))
        self.assertEqual(environment["DISPLAY"], ":17")
        self.assertEqual(environment["XAUTHORITY"], "private-cookie")
        self.assertEqual(environment["SDL_VIDEODRIVER"], "x11")
        self.assertEqual(environment["LIBGL_ALWAYS_SOFTWARE"], "1")
        self.assertEqual(environment["GALLIUM_DRIVER"], "llvmpipe")
        self.assertEqual(environment["__GLX_VENDOR_LIBRARY_NAME"], "mesa")
        for key in ("WAYLAND_DISPLAY", "FACTORIO_CLIENT_DISPLAY", "DRI_PRIME",
                    "MESA_LOADER_DRIVER_OVERRIDE", "LIBGL_ALWAYS_INDIRECT"):
            self.assertNotIn(key, environment)

    def test_missing_display_tools_fail_before_launch(self):
        with tempfile.TemporaryDirectory() as directory, patch(
                "tools.factorio_multiplayer.shutil.which", return_value=None):
            with self.assertRaisesRegex(TestFailure, "Xvfb and xauth"):
                with virtual_display(Path(directory), 1):
                    self.fail("missing dependency must not start a display")

    def test_failed_xauth_does_not_leave_authority_file(self):
        with tempfile.TemporaryDirectory() as directory, patch(
                "tools.factorio_multiplayer.shutil.which", return_value="unused"), patch(
                "tools.factorio_multiplayer.subprocess.run", side_effect=OSError("launch failed")):
            with self.assertRaisesRegex(OSError, "launch failed"):
                with virtual_display(Path(directory), 1):
                    self.fail("failed xauth must not start a display")
            self.assertFalse((Path(directory) / "Xauthority").exists())
