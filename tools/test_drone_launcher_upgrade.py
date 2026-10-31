#!/usr/bin/env python3
"""Check loaded launcher inventories after the upstream slot-count change."""
import argparse
import json
from pathlib import Path
import shutil
import socket
import subprocess
import time
import tempfile
from run_factorio_tests import (MOD_UNDER_TEST, REPOSITORY, default_factorio,
    default_dependency_mods, prepare_config, prepare_mods, run_factorio, tail)
from factorio_package import workspace_target


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--factorio',type=Path,default=default_factorio())
    parser.add_argument('--dependency-mod-directory',type=Path,default=default_dependency_mods())
    args=parser.parse_args()
    work=Path(tempfile.mkdtemp(prefix='factorio-launcher-upgrade-'))
    print('Artifacts:',work,flush=True)
    for name in ('saves','script-output','temp'): (work/name).mkdir()
    config=prepare_config(work,args.factorio)
    prepare_mods(work/'mods',args.dependency_mod_directory,MOD_UNDER_TEST,
                 workspace_target(args.factorio,MOD_UNDER_TEST))
    mod=work/'mods'/'nullius-star'
    (mod/'scenarios').unlink()
    (mod/'scenarios').mkdir()
    for entry in (REPOSITORY/'tests/scenarios').iterdir():
        (mod/'scenarios'/entry.name).symlink_to(entry.resolve(),target_is_directory=entry.is_dir())
    scenario=mod/'scenarios'/'upstream-launcher-upgrade';scenario.mkdir()
    shutil.copyfile(REPOSITORY/'tests/scenarios/drone-launcher-upgrade.lua',scenario/'control.lua')
    final=mod/'data-final-fixes.lua';source=final.read_text();final.unlink()
    final.write_text(source+'''\nfor tier=1,2 do
  local p=data.raw['artillery-turret']['nullius-drone-launcher-'..tier]
  p.inventory_size=tier==1 and 3 or 5;p.ammo_stack_limit=10
end
''')
    common=[str(args.factorio),'--config',str(config),'--mod-directory',str(work/'mods'),'--disable-audio']
    def run(name,extra):
        log=work/(name+'.log')
        result=run_factorio(common+extra,log,60)
        if result.returncode: raise RuntimeError(tail(log))
        return log
    run('compile',['--scenario2map','nullius-star/upstream-launcher-upgrade'])
    server=work/'server-settings.json'
    settings=json.loads((args.factorio.resolve().parents[2]/'data/server-settings.example.json').read_text())
    settings.update(dict(name='Launcher upgrade test',visibility=dict(public=False,lan=False),
        require_user_verification=False,auto_pause=False,autosave_interval=0))
    server.write_text(json.dumps(settings))
    with socket.socket(socket.AF_INET,socket.SOCK_DGRAM) as sock:
        sock.bind(('127.0.0.1',0));port=sock.getsockname()[1]
    save=work/'saves/launcher-slots.zip'
    with (work/'prepare.log').open('w') as stream:
        process=subprocess.Popen(common+['--start-server',str(work/'saves/nullius-star/upstream-launcher-upgrade.zip'),
            '--server-settings',str(server),'--bind',f'127.0.0.1:{port}'],stdout=stream,stderr=subprocess.STDOUT)
        try:
            deadline=time.monotonic()+30
            while not save.is_file():
                if process.poll() is not None or time.monotonic()>deadline:
                    raise RuntimeError('Legacy fixture did not save: '+tail(work/'prepare.log'))
                time.sleep(.1)
        finally:
            process.terminate()
            try: process.wait(timeout=10)
            except subprocess.TimeoutExpired: process.kill();process.wait()
    final.write_text(source)
    info=mod/'info.json';value=json.loads(info.read_text());info.unlink()
    # A private test version forces the normal configuration-change path.
    value['version']='999.0.0';info.write_text(json.dumps(value))
    support=work/'mods/factorio-test-support/info.json'
    value=json.loads(support.read_text());value['dependencies']=['nullius-star = 999.0.0']
    support.write_text(json.dumps(value))
    log=run('upgrade',['--load-game',str(save),'--until-tick','120'])
    if 'LAUNCHER_UPGRADE_PASS' not in log.read_text(): raise RuntimeError('Upgrade witness did not finish')
    print('PASS: all 80 drones preserved')


if __name__=='__main__':main()
