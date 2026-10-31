#!/usr/bin/env python3
"""Report selected progression contracts from a fresh Factorio dump."""
import argparse
import json
import math
from pathlib import Path
import analyze_factorio_prereqs as prereqs
from run_factorio_tests import default_dependency_mods

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--factorio', type=Path)
    parser.add_argument('--dependency-mod-directory', type=Path, default=default_dependency_mods())
    parser.add_argument('--config', type=Path)
    parser.add_argument('--output', type=Path)
    parser.add_argument('--read-report', type=Path)
    parser.add_argument('--field', help='Top-level field to print')
    args = parser.parse_args()
    if args.read_report:
        report = json.loads(args.read_report.read_text())
        print(json.dumps(report[args.field] if args.field else report, indent=2))
        return
    if not (args.factorio and args.config and args.output):
        parser.error('Specify --read-report or --factorio, --config and --output')
    args.data_raw = None
    args.mod_under_test = ROOT / 'nullius-star'
    args.timeout_seconds = 120
    config = json.loads(args.config.read_text())
    data, work = prereqs.dump_resolved_data(args)
    entities = []
    for prefix in config['entity_prefixes']:
        entities.extend(prereqs.describe_placeable_entities(data, prefix))
    report = dict(dump=str(work / 'script-output/data-raw-dump.json'),
                  products=prereqs.describe_products(data, config['products']),
                  technologies=prereqs.describe_technologies(data, config['technologies']),
                  entities=entities)
    tanks = []
    for entity in entities:
        if entity['fluid_capacity']:
            box = data['storage-tank'][entity['name']]['selection_box']
            width = box[1][0] - box[0][0]
            height = box[1][1] - box[0][1]
            tanks.append(dict(name=entity['name'], capacity=entity['fluid_capacity'],
                              capacity_per_tile=entity['fluid_capacity'] / (width * height),
                              tanks_for_checkpoint=math.ceil(config['storage_target'] / entity['fluid_capacity'])))
    report['storage'] = tanks
    args.output.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report[args.field] if args.field else report, indent=2))


if __name__ == '__main__':
    main()
