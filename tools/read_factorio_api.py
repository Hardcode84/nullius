#!/usr/bin/env python3
"""Print a member contract from the installed Factorio runtime or prototype API."""
import argparse
import json
from run_factorio_tests import default_factorio

# Each API names its owners, their member lists, and its standalone types.
STAGES = {
    'runtime': ('runtime-api.json', 'classes', ('methods', 'attributes'), 'concepts'),
    'prototype': ('prototype-api.json', 'prototypes', ('properties',), 'types'),
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('class_name')
    parser.add_argument('member', nargs='*')
    parser.add_argument('--search', help="list members of the class, or of every class with '*', whose name or description contains this text")
    parser.add_argument('--stage', choices=sorted(STAGES), default='runtime')
    args = parser.parse_args()
    filename, owners, fields, types = STAGES[args.stage]
    path = default_factorio().resolve().parents[2] / 'doc-html' / filename
    api = json.loads(path.read_text())
    if args.search:
        needle = args.search.lower()
        print(json.dumps(sorted(f"{c['name']}.{m['name']}" for c in api[owners]
                                if args.class_name in ('*', c['name'])
                                for field in fields for m in c.get(field, [])
                                if needle in m['name'].lower() or needle in m.get('description', '').lower()),
                         indent=2))
        return
    if not args.member:
        matches = [c for c in [*api[types], *api.get('events', [])] if c['name'] == args.class_name]
        if not matches:
            parser.error('Supply a class and member names, or a type or event name')
        print(json.dumps(matches[0], indent=2))
        return
    classes = {c['name']: c for c in api[owners]}
    if args.class_name not in classes:
        parser.error('Unknown class: ' + args.class_name)
    cls = classes[args.class_name]
    members = {m['name']: m for field in fields for m in cls.get(field, [])}
    if any(name not in members for name in args.member):
        parser.error('Unknown members: ' + ', '.join(n for n in args.member if n not in members))
    print(json.dumps({'version': api['application_version'], 'members':
                     {name: members[name] for name in args.member}}, indent=2))


if __name__ == '__main__':
    main()
