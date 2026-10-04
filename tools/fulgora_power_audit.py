#!/usr/bin/env python3
"""Export current Fulgora load profiles and summarize native storm delivery."""
import argparse
import json
import hashlib
import math
from pathlib import Path
from analyze_fulgora_power import report
import analyze_factorio_prereqs as prereqs
import shutil


def summarize_native(case):
    rows=[]
    for row in case['observations']:
        for phase in ('day','night'):
            v=row[phase]; seconds=v['ticks']/60
            rows.append(dict(name=row['name'],phase=phase,first_trip_tick=row.get('first_trip'),
                grounding_switch_on_percent=100*v.get('switch_on',0)/(v['ticks']/30),
                sensor_mean_percent=v.get('sensor_sum',0)/(v['ticks']/30),
                sensor_above_80_percent=100*v.get('sensor_high',0)/(v['ticks']/30),
                secondary_delivered_percent=100*v['secondary_J']/(row['secondary_MW']*1e6*seconds),
                surge_delivered_percent=100*v['surge_J']/(row['surge_MW']*1e6*seconds) if row['surge_MW'] else None,
                capture_per_minute=v['captures']/seconds*60,
                collector_output_MW=v['collector_J']/seconds/1e6,
                grounding_MW=v['coil_J']/seconds/1e6,
                trip_samples=v['trips'],secondary_gap_seconds=v['secondary_gaps']/2,
                surge_gap_seconds=v['surge_gaps']/2,end_battery_MJ=v['battery_MJ']))
    return dict(factorio=case['factorio_version'],rows=rows)


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--bootstrap',type=Path)
    p.add_argument('--industry',type=Path)
    p.add_argument('--fixture',type=Path)
    p.add_argument('--results',type=Path)
    p.add_argument('--case',default='fulgora-power-audit')
    p.add_argument('--output',type=Path,required=True)
    args=p.parse_args()
    if args.results:
        run=json.loads(args.results.read_text())
        if run['status']!='pass': raise ValueError('Native audit failed')
        case=next(r for r in run['results'] if r['case']==args.case)
        result=summarize_native(case)
    else:
        if not args.bootstrap or not args.industry:
            p.error('--bootstrap and --industry are required without --results')
        data,work=prereqs.dump_resolved_data(prereqs.parse_arguments([]))
        try:
            budget=report(data,json.loads(Path('tests/progression/planner/fulgora-power.json').read_text()))
            for machine in budget['machines']:
                entity_name=data['item'][machine['name']]['place_result']
                proto=next(table[entity_name] for table in data.values() if isinstance(table,dict) and entity_name in table
                           and isinstance(table[entity_name],dict) and 'energy_source' in table[entity_name])
                machine['priority']=proto['energy_source']['usage_priority']
            bootstrap=json.loads(args.bootstrap.read_text())
            batch=next(t for t in bootstrap['targets'] if t['name']=='first-science')
            case=next(c for c in batch['cases'] if c['name']=='starter')
            # Machine energy excludes idle drain; keep the whole placed fleet powered.
            average=case['active_energy_mj']/(case['production_minutes_lower_bound']*60)+budget['fleet_idle_MW']
            industry=json.loads(args.industry.read_text())
            science=next(r for r in industry['rows'] if r['stage']=='first-physics' and r['rate']==60)
            secondary=science['battery_supported_mw']; surge=science['priority_mw'].get('tertiary',0)
            full_secondary=sum(r['active_MW']+r['drain_MW'] for r in budget['machines'] if r['priority']!='tertiary')
            full_surge=sum(r['active_MW']+r['drain_MW'] for r in budget['machines'] if r['priority']=='tertiary')
            if full_surge: raise ValueError('Starter mean profile needs a separate surge-energy calculation')
            profiles=[dict(name='starter-mean',layout='starter',batteries=4,secondary_MW=average,surge_MW=0),
                      dict(name='starter-full',layout='starter',batteries=4,secondary_MW=full_secondary,surge_MW=full_surge),
                      dict(name='starter-full-storage',layout='starter',batteries=0,secondary_MW=full_secondary,surge_MW=full_surge),
                      dict(name='science-60-compact',layout='compact',batteries=science['storage']['30']['minimum_full_batteries'],secondary_MW=secondary,surge_MW=surge),
                      dict(name='science-60-spread',layout='spread',batteries=science['storage']['30']['minimum_full_batteries'],secondary_MW=secondary,surge_MW=surge)]
            # Derive discharge counts from the resolved battery, not a fixed tier assumption.
            discharge=budget['battery']['total_discharge_MW']/budget['battery']['count']
            profiles[2]['batteries']=math.ceil(full_secondary/discharge)
            for profile in profiles:
                profile['poles']=36 if profile['layout']=='starter' else 256 if profile['layout']=='spread' else 32
                profile['coils']=4 if profile['layout']!='spread' else 32
                profile['grounding_MW']=profile['coils']*budget['grounding']['per_coil_MW']
                profile['generation_for_full_demand_MW']=profile['secondary_MW']+profile['surge_MW']+profile['grounding_MW']
                profile['surge_share_of_tertiary_demand']=profile['surge_MW']/(profile['surge_MW']+profile['grounding_MW'])
            result=dict(input_hashes={str(path):hashlib.sha256(path.read_bytes()).hexdigest()
                                      for path in (args.bootstrap,args.industry)},
                        starter=budget,first_science_mean_MW=average,
                        minimum_batteries_for_mean_discharge=math.ceil(average/discharge),profiles=profiles,
                        starter_worst_case_coils=math.ceil(36*budget['collector']['output_MW']/2/budget['grounding']['per_coil_MW']))
            if args.fixture:
                def lua(value):
                    if isinstance(value,dict):return '{'+','.join('['+json.dumps(k)+']='+lua(v) for k,v in value.items())+'}'
                    if isinstance(value,list):return '{'+','.join(map(lua,value))+'}'
                    return json.dumps(value)
                args.fixture.write_text('-- Generated by tools/fulgora_power_audit.py. Declared constant-load experiments.\nreturn '+lua(profiles)+'\n')
        finally:
            if work:shutil.rmtree(work)
    args.output.write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result if args.results else {k:v for k,v in result.items() if k!='starter'},indent=2))


if __name__=='__main__':main()
