#!/usr/bin/env python3
"""Measure native 2.0 loot rounding with fixed and fractional count bounds."""
import argparse
import json
from pathlib import Path
import tempfile
from run_factorio_tests import prepare_config, run_factorio, TestFailure

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--factorio', type=Path, required=True)
    args = parser.parse_args()
    work = Path(tempfile.mkdtemp(prefix='loot-fractions-'))
    mod = work / 'mods/loot-probe'
    mod.mkdir(parents=True)
    (mod / 'info.json').write_text(json.dumps(dict(name='loot-probe', version='0.0.1', title='Loot probe', author='tests', factorio_version='2.0', dependencies=['base'])))
    (mod / 'data.lua').write_text('''
for i, bounds in ipairs({{0.5,1.8},{2.5,4.2},{0,1.2},{1.5,1.5}}) do
  local rock=table.deepcopy(data.raw["simple-entity"]["huge-rock"])
  rock.name="loot-fraction-" .. i
  rock.autoplace=nil
  rock.loot={{item="stone", count_min=bounds[1], count_max=bounds[2]}}
  data:extend({rock})
end
''')
    (mod / 'scenarios').mkdir()
    (mod / 'scenarios/probe').symlink_to(Path(__file__).resolve().parents[1] / 'tests/compatibility/rock-loot-fractions', target_is_directory=True)
    (work / 'mods/mod-list.json').write_text(json.dumps({'mods':[{'name':n,'enabled':n in ('base','loot-probe')} for n in ('base','loot-probe','space-age','quality','elevated-rails')]}))
    config=prepare_config(work,args.factorio)
    common=[str(args.factorio),'--config',str(config),'--mod-directory',str(work/'mods')]
    for label, options in [('compile',['--scenario2map','loot-probe/probe']),('run',['--load-game',str(work/'saves/loot-probe/probe.zip'),'--until-tick','2'])]:
        result=run_factorio(common+options,work/f'{label}.log',180)
        if result.returncode: raise TestFailure(result.stdout[-4000:])
    print(json.dumps({'artifacts':str(work),'histograms':json.loads((work/'script-output/loot-fractions.json').read_text())},indent=2))
if __name__ == '__main__':
    main()
