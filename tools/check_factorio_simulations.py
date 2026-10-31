#!/usr/bin/env python3
"""Run menu and tip simulations in Factorio's native simulation environment."""
import argparse
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import time

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from tools.check_factorio_locale import prepare_mods
from tools.run_factorio_tests import (default_factorio, default_dependency_mods,
    prepare_config, tail, MOD_UNDER_TEST, TestFailure)
from tools.factorio_multiplayer import virtual_display, stop_process


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--factorio', type=Path, default=default_factorio())
    parser.add_argument('--dependency-mod-directory', type=Path, default=default_dependency_mods())
    parser.add_argument('--group', choices=['tips', 'menu', 'all'], default='all')
    args = parser.parse_args()
    work = Path(tempfile.mkdtemp(prefix='factorio-simulation-check-'))
    print('Artifacts:', work, flush=True)
    for name in ('saves', 'script-output', 'temp'):
        (work / name).mkdir()
    config = prepare_config(work, args.factorio)
    prepare_mods(work / 'mods', args.dependency_mod_directory, MOD_UNDER_TEST)
    mod = work / 'mods/nullius-star'
    mod.unlink(); mod.mkdir()
    for source in MOD_UNDER_TEST.iterdir():
        if source.name != 'data-final-fixes.lua':
            (mod / source.name).symlink_to(source.resolve(), target_is_directory=source.is_dir())
    injection = '''
local simulations = {}
if GROUP ~= "tips" then
  for name, definition in pairs(data.raw["utility-constants"].default.main_menu_simulations) do
    simulations[name] = table.deepcopy(definition)
  end
end
if GROUP ~= "menu" then
  for name, tip in pairs(data.raw["tips-and-tricks-item"]) do
    if string.sub(name,1,8)=="nullius-" and tip.simulation then
      simulations[name] = table.deepcopy(tip.simulation)
    end
  end
end
for name, definition in pairs(simulations) do
  log("SIMULATION_EXPECTED " .. name)
  definition.length = 90
  definition.init_update_count = 60
  assert(not definition.init_file, "simulation audit requires inline initialization: "..name)
  definition.init = (definition.init or "") .. '\\nassert(game.simulation)\\n' ..
    'storage.nullius_simulation_audit_start=game.tick\\ngame.tick_paused=false\\n'
  definition.update = (definition.update or "") .. '\\n' ..
    'if game.tick >= storage.nullius_simulation_audit_start+60 then log("SIMULATION_PASS '..name..'") end'
end
data.raw["utility-constants"].default.main_menu_simulations = simulations
'''.replace('GROUP', '"'+args.group+'"')
    (mod / 'data-final-fixes.lua').write_text((MOD_UNDER_TEST / 'data-final-fixes.lua').read_text()+injection)
    log = work / 'client.log'
    with virtual_display(work, 10) as (_, environment), log.open('w') as output:
        process = subprocess.Popen([str(args.factorio), '--config', str(config),
            '--mod-directory', str(work / 'mods'), '--disable-audio',
            '--force-graphics-preset', 'very-low', '--window-size', '640x480'],
            env=environment, stdout=output, stderr=subprocess.STDOUT)
        try:
            deadline = time.monotonic()+90
            while time.monotonic() < deadline:
                contents = log.read_text()
                expected = set(re.findall(r'SIMULATION_EXPECTED ([\w-]+)', contents))
                passed = set(re.findall(r'SIMULATION_PASS ([\w-]+)', contents))
                if 'Error ' in contents or process.poll() is not None:
                    raise TestFailure(tail(log))
                if expected and passed == expected:
                    print('PASS:', ', '.join(sorted(passed)), flush=True)
                    break
                time.sleep(.2)
            else:
                raise TestFailure('Simulation deadline; missing '+str(sorted(expected-passed))+'\n'+tail(log))
        finally:
            stop_process(process)


if __name__ == '__main__':
    main()
