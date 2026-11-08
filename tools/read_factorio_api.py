#!/usr/bin/env python3
"""Print a member contract from the installed Factorio runtime API."""
import argparse
import json
from run_factorio_tests import default_factorio


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('class_name')
    parser.add_argument('member', nargs='*')
    args = parser.parse_args()
    path = default_factorio().resolve().parents[2] / 'doc-html/runtime-api.json'
    api = json.loads(path.read_text())
    if not args.member:
        matches = [c for c in api['concepts'] if c['name'] == args.class_name]
        if not matches:
            parser.error('Supply a class and member names, or a concept name')
        print(json.dumps(matches[0], indent=2))
        return
    classes = {c['name']: c for c in api['classes']}
    if args.class_name not in classes:
        parser.error('Unknown class: ' + args.class_name)
    cls = classes[args.class_name]
    members = {m['name']: m for field in ('methods', 'attributes') for m in cls.get(field, [])}
    if any(name not in members for name in args.member):
        parser.error('Unknown members: ' + ', '.join(n for n in args.member if n not in members))
    print(json.dumps({'version': api['application_version'], 'members':
                     {name: members[name] for name in args.member}}, indent=2))

if __name__ == '__main__':
    main()
