"""Run a bounded scenario with real local Factorio clients."""

from __future__ import annotations

import json
import os
from pathlib import Path
import signal
import socket
import subprocess
import time


def prepare_support_overlay(run_directory: Path, scenario: Path, until_tick: int,
                            multiplayer: bool) -> None:
    """Stage declared startup settings and the multiplayer tick deadline."""
    from tools.run_factorio_tests import TestFailure

    settings_fixture = scenario / "settings-updates.lua"
    if not multiplayer and not settings_fixture.is_file():
        return
    support = run_directory / "mods" / "factorio-test-support"
    source = support.resolve()
    if multiplayer and (source / "control.lua").exists():
        raise TestFailure("multiplayer deadline conflicts with the test-support runtime entry point")
    if settings_fixture.is_file() and (source / "settings-updates.lua").exists():
        raise TestFailure("scenario settings conflict with test-support settings")
    support.unlink()
    support.mkdir()
    for entry in source.iterdir():
        (support / entry.name).symlink_to(entry, target_is_directory=entry.is_dir())
    if settings_fixture.is_file():
        (support / "settings-updates.lua").symlink_to(settings_fixture.resolve())
    if multiplayer:
        # Server mode does not enforce --until-tick. All peers load this guard.
        # on_nth_tick also fires at tick zero, before the deadline.
        (support / "control.lua").write_text(
            f"script.on_nth_tick({until_tick + 1}, function()\n"
            f"  if game.tick > {until_tick} then\n"
            '    error("multiplayer scenario exceeded its tick deadline")\n'
            "  end\nend)\n"
        )


def execute_multiplayer(args, common: list[str], save: Path, run_directory: Path) -> None:
    # Imported here because the scenario runner imports this executor on demand.
    from tools.run_factorio_tests import TestFailure, prepare_config, tail

    display = os.environ.get("FACTORIO_CLIENT_DISPLAY", os.environ.get("DISPLAY"))
    if not display:
        raise TestFailure("real multiplayer clients require DISPLAY or FACTORIO_CLIENT_DISPLAY")
    settings = run_directory / "server-settings.json"
    server_settings = json.loads((Path(common[0]).resolve().parents[2] /
                                "data/server-settings.example.json").read_text())
    server_settings.update({
        "name": "Nullius scenario test", "visibility": {"public": False, "lan": False},
        "require_user_verification": False, "auto_pause": False,
        "autosave_interval": 0, "allow_commands": "true",
    })
    settings.write_text(json.dumps(server_settings))
    # Select a free loopback port; a bind conflict is a reported server failure.
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as port_socket:
        port_socket.bind(("127.0.0.1", 0))
        port = port_socket.getsockname()[1]
    processes: list[subprocess.Popen] = []
    streams = []
    clients = {}
    client_logs = {}
    client_attempts = {}
    generation = 0
    deadline = time.monotonic() + args.timeout_seconds

    def launch(command, log, **kwargs):
        stream = log.open("w")
        streams.append(stream)
        process = subprocess.Popen(command, stdout=stream, stderr=subprocess.STDOUT, **kwargs)
        processes.append(process)
        return process

    def stop(process):
        if process.poll() is None:
            process.send_signal(signal.SIGINT)
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()

    def start_server(source):
        return launch([
            *common, "--start-server", str(source), "--bind", f"127.0.0.1:{port}",
            "--server-settings", str(settings),
        ], run_directory / f"server-{generation}.log", stdin=subprocess.PIPE, text=True)

    def start_client(name):
        client_dir = run_directory / name
        if not client_dir.exists():
            client_dir.mkdir()
            prepare_config(client_dir, Path(common[0]))
            (client_dir / "player-data.json").write_text(json.dumps({"service-username": name}))
        client_attempts[name] = client_attempts.get(name, 0) + 1
        client_logs[name] = run_directory / f"{name}-{client_attempts[name]}.log"
        environment = dict(os.environ, DISPLAY=display, SDL_VIDEODRIVER="x11")
        clients[name] = launch([
            common[0], "--config", str(client_dir / "config.ini"),
            "--mod-directory", str(run_directory / "mods"), "--disable-audio",
            "--force-graphics-preset", "very-low", "--window-size", "640x480",
            "--mp-connect", f"127.0.0.1:{port}",
        ], client_logs[name], env=environment)

    def wait_for(predicate, label):
        while not predicate():
            if server.poll() is not None:
                raise TestFailure(f"multiplayer server exited while {label}:\n" +
                                  tail(run_directory / f"server-{generation}.log"))
            for name, client in clients.items():
                contents = client_logs[name].read_text()
                if (client.poll() is not None or "Error " in contents or
                        "Desync" in contents or "InitializationFailed" in contents):
                    raise TestFailure(f"multiplayer client failed while {label}: {name}\n" +
                                      tail(client_logs[name]))
            if time.monotonic() >= deadline:
                raise TestFailure(f"multiplayer wall deadline while {label}")
            time.sleep(0.1)

    def ready():
        log = run_directory / f"server-{generation}.log"
        return "InGame" in log.read_text()

    action_path = run_directory / "script-output" / "factorio-tests" / "multiplayer-action.json"
    result_path = run_directory / "script-output" / "factorio-tests" / f"{save.stem}.json"
    action_id = 0
    try:
        server = start_server(save)
        wait_for(ready, "starting server")
        start_client("nullius-test-a")
        while not result_path.exists():
            wait_for(lambda: action_path.exists() or result_path.exists(), "waiting for scenario")
            if result_path.exists():
                break
            try:
                action = json.loads(action_path.read_text())
            except json.JSONDecodeError as error:
                raise TestFailure(f"invalid multiplayer action JSON: {error}") from error
            if (not isinstance(action, dict) or
                    set(action) - {"id", "action", "player"} or
                    not isinstance(action.get("id"), int) or
                    action.get("action") not in {"join", "leave", "reload"} or
                    (action["action"] != "reload" and not isinstance(action.get("player"), str))):
                raise TestFailure(f"invalid multiplayer action: {action!r}")
            if action["id"] <= action_id:
                raise TestFailure("multiplayer action ID did not advance")
            action_id = action["id"]
            action_path.unlink()
            operation = action["action"]
            if operation == "join":
                name = action["player"]
                if name not in ("nullius-test-a", "nullius-test-b") or name in clients:
                    raise TestFailure(f"invalid multiplayer join: {name}")
                start_client(name)
            elif operation == "leave":
                name = action["player"]
                if name not in clients:
                    raise TestFailure(f"multiplayer client is not running: {name}")
                stop(clients.pop(name))
            elif operation == "reload":
                resumed = run_directory / "saves" / "multiplayer-resume.zip"
                server.stdin.write("/server-save multiplayer-resume\n")
                server.stdin.flush()
                wait_for(resumed.is_file, "saving scenario")
                for client in clients.values():
                    stop(client)
                clients.clear()
                stop(server)
                generation += 1
                server = start_server(resumed)
                wait_for(ready, "reloading server")
                start_client("nullius-test-a")
                start_client("nullius-test-b")
            else:
                raise TestFailure(f"unknown multiplayer action: {operation}")
        try:
            result = json.loads(result_path.read_text())
        except json.JSONDecodeError as error:
            raise TestFailure(f"invalid multiplayer result JSON: {error}") from error
        if result.get("tick", 0) > args.multiplayer_until_tick:
            raise TestFailure("multiplayer scenario exceeded its tick deadline")
        for name, client in clients.items():
            peer_result = run_directory / name / "script-output" / "factorio-tests" / f"{save.stem}.json"
            wait_for(peer_result.is_file, f"waiting for {name} final assertions")
            try:
                peer = json.loads(peer_result.read_text())
            except json.JSONDecodeError as error:
                raise TestFailure(f"invalid multiplayer client result: {name}: {error}") from error
            if peer != result:
                raise TestFailure(f"multiplayer client result differs from server: {name}")
            if client.poll() is not None:
                raise TestFailure(f"multiplayer client exited: {name}")
        # The server owns the authoritative result. Each client's log must also
        # show that it joined without a desync or simulation failure.
        for log in run_directory.glob("nullius-test-*.log"):
            contents = log.read_text()
            if "InGame" not in contents or "Desync" in contents or "Error " in contents:
                raise TestFailure(f"multiplayer client did not run cleanly: {log}\n{tail(log)}")
    finally:
        for process in reversed(processes):
            stop(process)
        for process in processes:
            if process.stdin is not None:
                process.stdin.close()
        for stream in streams:
            stream.close()
