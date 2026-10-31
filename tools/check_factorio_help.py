#!/usr/bin/env python3
"""Check tip text, translated keys, and rich-text prototype links against Factorio."""
import argparse
from pathlib import Path
import re
import analyze_factorio_prereqs as prereqs
from check_factorio_locale import parse_locale_catalog, read_prototype_type_domains, resolved_prototype_tables
from run_factorio_tests import default_factorio, default_dependency_mods, MOD_UNDER_TEST


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--factorio', type=Path, default=default_factorio())
    parser.add_argument('--dependency-mod-directory', type=Path, default=default_dependency_mods())
    args = parser.parse_args()
    args.data_raw = None
    args.mod_under_test = MOD_UNDER_TEST
    args.timeout_seconds = 120
    data, work = prereqs.dump_resolved_data(args)
    domains = read_prototype_type_domains(args.factorio)
    names = {}
    for kind, prototypes in resolved_prototype_tables(data).items():
        names.setdefault(domains.get(kind, kind), set()).update(prototypes)
    names['tip'] = names['tips-and-tricks-item']
    catalogs = {language: parse_locale_catalog(MOD_UNDER_TEST/'locale'/language) for language in ('en','de')}
    errors = []
    for language, catalog in catalogs.items():
        for key, entry in catalog.items():
            if language == 'de' and key not in catalogs['en']:
                errors.append(f'{language}: unused translation {key}')
            if language != 'de' and not key.startswith('tips-and-tricks-'):
                continue
            text = entry.path.read_text().splitlines()[entry.line-1].split('=',1)[1]
            for kind, name in re.findall(r'\[(item|entity|fluid|recipe|technology|tile|achievement|tip)=([^\]]+)\]', text):
                if re.fullmatch(r'__\d+__', name):
                    continue
                if name not in names[kind]:
                    errors.append(f'{language}: {key}: unknown {kind} {name}')
            for name in re.findall(r'__CONTROL__(nullius-[\w-]+|configurable-valves-[\w-]+)__', text):
                if name not in names['custom-input']:
                    errors.append(f'{language}: {key}: unknown control {name}')
    tips = [name for name in names['tip'] if name.startswith('nullius-')]
    for name in tips:
        for section in ('tips-and-tricks-item-name','tips-and-tricks-item-description'):
            if section+'.'+name not in catalogs['en']:
                errors.append('missing '+section+'.'+name)
    for name in names['tips-and-tricks-item-category']:
        if name.startswith('nullius-') and 'tips-and-tricks-item-category-name.'+name not in catalogs['en']:
            errors.append('missing category name '+name)
    for error in errors: print(error)
    print(f'{len(tips)} tips; {len(catalogs["de"])} German keys; {len(errors)} errors; dump: {work}')
    raise SystemExit(bool(errors))


if __name__ == '__main__':
    main()
