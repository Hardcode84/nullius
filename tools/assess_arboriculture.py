#!/usr/bin/env python3
"""Compare baseline and upstream arboriculture on native Factorio surfaces."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import statistics
import subprocess
import tempfile
from generate_factorio_scenario_manifest import lua
from run_factorio_tests import (REPOSITORY, MOD_UNDER_TEST, default_factorio,
    default_dependency_mods, prepare_config, prepare_mods, run_factorio, tail, TestFailure)


def effect(source):
    start = source.index('function arboriculture_effect(event)')
    end = source.index('\nfunction entomology_effect(', start)
    body = source[start:end].replace('function arboriculture_effect(event)', 'return function(event)', 1)
    return ('return function(surface, random)\n'
            '  local game = {surfaces={[surface.index]=surface}}\n'
            '  local math = setmetatable({random=random}, {__index=math})\n'+body+'\nend\n')


def summarize(report, log, contract):
    timings = {}
    for line in log.splitlines():
        match = re.search(r'ARB_TIME (\d+) (baseline|upstream) (\d+) Duration: ([\d.]+)ms', line)
        if match:
            row, variant, repetition, milliseconds = match.groups()
            key = (int(row), variant)
            timings.setdefault(key, []).append(float(milliseconds))
    for i, row in enumerate(report['rows'], 1):
        for variant in ('baseline', 'upstream'):
            samples = timings.get((i, variant), [])
            if len(samples) != contract['repetitions']:
                raise TestFailure(f'missing timing samples for row {i} {variant}: {samples}')
            row[variant]['milliseconds'] = samples
            row[variant]['median_ms'] = statistics.median(samples)
    report['summary'] = []
    for case in contract['cases']:
        rows = [row for row in report['rows'] if row['case'] == case['name']]
        result = dict(case=case['name'], comparisons=len(rows),
                      changed_forests=sum(row['difference']['changed'] for row in rows),
                      changed_species=sum(row['difference']['changed_species'] for row in rows),
                      removed_positions=sum(row['difference']['removed_positions'] for row in rows),
                      added_positions=sum(row['difference']['added_positions'] for row in rows))
        for variant in ('baseline', 'upstream'):
            result[variant] = dict(trees=sum(len(row[variant]['trees']) for row in rows),
                queries=sum(row[variant]['queries'] for row in rows),
                sampled_positions=sum(row[variant]['sampled_positions'] for row in rows),
                median_ms=statistics.median([sample for row in rows for sample in row[variant]['milliseconds']]))
        result['speedup'] = result['baseline']['median_ms']/result['upstream']['median_ms']
        report['summary'].append(result)
    report['totals'] = dict(comparisons=len(report['rows']),
        changed_forests=sum(row['difference']['changed'] for row in report['rows']),
        changed_species=sum(row['difference']['changed_species'] for row in report['rows']),
        removed_positions=sum(row['difference']['removed_positions'] for row in report['rows']),
        added_positions=sum(row['difference']['added_positions'] for row in report['rows']))
    report['acceptance'] = dict(exact_forests=all(not row['difference']['changed'] for row in report['rows']),
        minimum_speedup=contract['minimum_speedup'],
        productive_cases_meet_speedup=all(row['speedup'] >= contract['minimum_speedup']
            for row in report['summary'] if row['baseline']['trees'] > 0))
    report['acceptance']['adopt'] = (report['acceptance']['exact_forests'] and
        report['acceptance']['productive_cases_meet_speedup'])
    return report


def display(report, overview):
    if not overview:
        print(json.dumps({key:report[key] for key in ('summary','totals','acceptance')}, indent=2))
        return
    print('case | changed forests | trees baseline/upstream | queries baseline/upstream | median ms baseline/upstream | speedup')
    for row in report['summary']:
        old, new = row['baseline'], row['upstream']
        print(f"{row['case']} | {row['changed_forests']}/{row['comparisons']} | "
              f"{old['trees']}/{new['trees']} | {old['queries']}/{new['queries']} | "
              f"{old['median_ms']:.3f}/{new['median_ms']:.3f} | {row['speedup']:.2f}")
    print(json.dumps(report['totals']))
    print(json.dumps(report['acceptance']))


def write_summary(report, path):
    if path is None:
        return
    keys = ('schema', 'factorio_version', 'contract', 'source_hashes', 'assertions',
            'summary', 'totals', 'acceptance')
    path.write_text(json.dumps({key:report[key] for key in keys},indent=2)+'\n')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config', type=Path, default=REPOSITORY/'tests/experiments/arboriculture.json')
    parser.add_argument('--output', type=Path)
    parser.add_argument('--overview', action='store_true')
    parser.add_argument('--baseline-ref', help='Use a committed baseline instead of the working tree')
    parser.add_argument('--summary-output', type=Path, help='Write compact evidence without local artifact paths')
    parser.add_argument('--factorio', type=Path, default=default_factorio())
    parser.add_argument('--dependency-mod-directory', type=Path, default=default_dependency_mods())
    parser.add_argument('--read-report', type=Path)
    args = parser.parse_args()
    if args.read_report:
        report = json.loads(args.read_report.read_text())
        display(report, args.overview)
        write_summary(report, args.summary_output)
        return
    if not args.output:
        parser.error('--output is required when running an experiment')
    contract = json.loads(args.config.read_text())
    work = Path(tempfile.mkdtemp(prefix='factorio-arboriculture-'))
    print('Artifacts:', work, flush=True)
    for name in ('saves','script-output','temp'): (work/name).mkdir()
    config = prepare_config(work,args.factorio)
    prepare_mods(work/'mods',args.dependency_mod_directory,MOD_UNDER_TEST)
    scenarios = work/'mods/nullius-star/scenarios'
    scenarios.unlink();scenarios.mkdir()
    for source in (REPOSITORY/"tests/scenarios").iterdir():
        (scenarios/source.name).symlink_to(source.resolve(), target_is_directory=source.is_dir())
    scenario = scenarios/'arboriculture-assessment';scenario.mkdir()
    shutil.copyfile(REPOSITORY/'tests/scenarios/arboriculture-assessment.lua',scenario/'control.lua')
    baseline = (subprocess.check_output(['git', 'show', args.baseline_ref +
        ':nullius-star/scripts/drone.lua'], cwd=REPOSITORY, text=True)
        if args.baseline_ref else (MOD_UNDER_TEST/'scripts/drone.lua').read_text())
    sources = {'baseline':baseline,
        'upstream':subprocess.check_output(['git','show',contract['upstream_ref']+':nullius/scripts/drone.lua'],cwd=REPOSITORY,text=True)}
    for variant, source in sources.items(): (scenario/(variant+'.lua')).write_text(effect(source))
    (scenario/'contract.lua').write_text('return '+lua(contract)+'\n')
    common = [str(args.factorio),'--config',str(config),'--mod-directory',str(work/'mods'),'--disable-audio']
    for stage, extra in [('compile',['--scenario2map','nullius-star/arboriculture-assessment']),
        ('run',['--load-game',str(work/'saves/nullius-star/arboriculture-assessment.zip'),'--until-tick',str(contract['until_tick'])])]:
        result = run_factorio(common+extra,work/(stage+'.log'),contract['timeout_seconds'])
        if result.returncode: raise TestFailure(tail(work/(stage+'.log')))
    report = json.loads((work/'script-output/arboriculture.json').read_text())
    report.update(contract=contract, source_hashes={key:hashlib.sha256(effect(value).encode()).hexdigest() for key,value in sources.items()}, artifacts=str(work))
    report = summarize(report,(work/'run.log').read_text(),contract)
    args.output.write_text(json.dumps(report,indent=2)+'\n')
    write_summary(report, args.summary_output)
    display(report, args.overview)


if __name__ == '__main__': main()
