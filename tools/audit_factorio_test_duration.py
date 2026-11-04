#!/usr/bin/env python3
"""Compare scenario deadlines and measured duration with the suite budget."""
import argparse
import json
from pathlib import Path

if __package__:
    from .run_factorio_tests import SCENARIOS, MAX_UNTIL_TICK
else:
    from run_factorio_tests import SCENARIOS, MAX_UNTIL_TICK


def audit(result, max_ticks, max_seconds):
    measured = {row['case']: row for row in result['results']}
    rows = []
    for path in sorted(SCENARIOS.glob('*/test.json')):
        name = path.parent.name
        metadata = json.loads(path.read_text())
        run = measured.get(name, {})
        rows.append(dict(case=name, deadline=metadata['until_tick'],
                         timeout_seconds=metadata.get('timeout_seconds', 300),
                         multiplayer=metadata.get('multiplayer', False),
                         status=run.get('status', 'not_run'), tick=run.get('tick'),
                         seconds=run.get('duration_seconds')))
    unknown = sorted(set(measured) - {row['case'] for row in rows})
    if unknown:
        raise ValueError('Results contain undiscovered scenarios: ' + ', '.join(unknown))
    return dict(suite_seconds=result['wall_time_seconds'], max_suite_seconds=max_seconds,
                suite_within_budget=result['wall_time_seconds'] <= max_seconds,
                max_ticks=max_ticks, scenarios=len(rows),
                missing=[row['case'] for row in rows if row['status'] == 'not_run'],
                failed=[row['case'] for row in rows if row['status'] == 'fail'],
                long_deadlines=[row for row in rows if row['deadline'] > max_ticks],
                long_runs=sorted([row for row in rows if row['tick'] is not None and row['tick'] > max_ticks],
                                 key=lambda row: -row['tick']),
                slowest=sorted([row for row in rows if row['seconds'] is not None],
                               key=lambda row: -row['seconds'])[:15],
                excessive_timeouts=[row for row in rows if row['timeout_seconds'] > max_seconds])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--result', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--max-ticks', type=int, default=MAX_UNTIL_TICK)
    parser.add_argument('--max-suite-seconds', type=int, default=300)
    args = parser.parse_args()
    report = audit(json.loads(args.result.read_text()), args.max_ticks, args.max_suite_seconds)
    args.output.write_text(json.dumps(report, indent=2) + '\n')
    print(f"Suite: {report['suite_seconds']:.1f}s / {args.max_suite_seconds}s; "
          f"{report['scenarios']} scenarios; {len(report['failed'])} failed; {len(report['missing'])} not run")
    print(f"Over {args.max_ticks} ticks: {len(report['long_runs'])} measured runs, "
          f"{len(report['long_deadlines'])} declared deadlines")
    print('Case | measured ticks | deadline | wall seconds')
    for row in report['long_runs']:
        print(f"{row['case']} | {row['tick']} | {row['deadline']} | {row['seconds']:.1f}")
    print('Over-limit declarations:')
    for row in report['long_deadlines']:
        print(f"{row['case']}: {row['deadline']} ticks (measured {row['tick']})")
    print('Slowest scenarios:')
    for row in report['slowest']:
        print(f"{row['case']}: {row['seconds']:.1f}s, tick={row['tick']}, multiplayer={row['multiplayer']}")
    print('Timeouts over suite budget:', ', '.join(row['case'] for row in report['excessive_timeouts']) or 'none')
    print('Missing:', ', '.join(report['missing']) or 'none')
    print('Failed:', ', '.join(report['failed']) or 'none')


if __name__ == '__main__':
    main()
