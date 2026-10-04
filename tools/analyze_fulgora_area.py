#!/usr/bin/env python3
"""Measure native island capacity and estimate factory space from a matching plan."""

import argparse
import hashlib
import json
import math
from pathlib import Path
import shutil

import numpy as np
from scipy import ndimage
import analyze_factorio_prereqs as prereqs
import plan_factorio_factory as planner
from analyze_fulgora_industry import power_requirement


def dimensions(proto):
    box = proto["collision_box"]
    return tuple(math.ceil(box[1][axis] - box[0][axis]) for axis in (0, 1))


def blocks(mask, labels, size):
    h, w = mask.shape
    if h % size or w % size:
        raise ValueError("survey dimensions must be multiples of block size")
    fits = mask.reshape(h // size, size, w // size, size).all(axis=(1, 3))
    owners = labels[::size, ::size][fits]
    return np.bincount(owners, minlength=int(labels.max()) + 1) * size * size


def terrain(row, config):
    size = row["size"]
    land = np.zeros((size, size), dtype=bool)
    if len(row["land_rows"]) != size:
        raise ValueError("incomplete terrain mask")
    for y, spans in enumerate(row["land_rows"]):
        previous = 0
        for left, right in spans:
            if not previous <= left < right <= size:
                raise ValueError("invalid land span")
            land[y, left:right] = True
            previous = right
    cliffs = np.zeros_like(land)
    for left, top, right, bottom in row["cliffs"]:
        cliffs[
            max(0, min(size, math.floor(top))) : max(0, min(size, math.ceil(bottom))),
            max(0, min(size, math.floor(left))) : max(0, min(size, math.ceil(right))),
        ] = True
    clear = land & ~cliffs
    labels, count = ndimage.label(land)
    areas = np.bincount(labels.ravel(), minlength=count + 1)
    areas[0] = 0
    clear_areas = np.bincount(labels[clear], minlength=count + 1)
    packed = blocks(land, labels, config["block_size"])
    packed_clear = blocks(clear, labels, config["block_size"])
    edges = set(
        np.concatenate((labels[0, :], labels[-1, :], labels[:, 0], labels[:, -1]))
    )
    islands = [
        dict(
            id=i,
            tiles=int(areas[i]),
            cliff_free_tiles=int(clear_areas[i]),
            block_tiles=int(packed[i]),
            cliff_free_block_tiles=int(packed_clear[i]),
            clipped=i in edges,
        )
        for i in range(1, count + 1)
    ]
    islands.sort(key=lambda r: r["tiles"], reverse=True)
    complete = [
        r["tiles"]
        for r in islands
        if not r["clipped"] and r["tiles"] >= config["minimum_island_tiles"]
    ]
    landing = None
    if "landing" in row:
        x, y = map(math.floor, row["landing"])
        owner = int(labels[y, x])
        if owner == 0:
            raise ValueError("landing is on sediment")
        landing = next(r for r in islands if r["id"] == owner)
    summary = dict(
        seed=row["seed"],
        center=row["center"],
        sample_tiles=size * size,
        land_tiles=int(land.sum()),
        land_percent=float(100 * land.mean()),
        cliff_free_tiles=int(clear.sum()),
        cliff_count=len(row["cliffs"]),
        vents=row["vents"],
        block_tiles=int(packed.sum()),
        cliff_free_block_tiles=int(packed_clear.sum()),
        islands_above_minimum=sum(
            r["tiles"] >= config["minimum_island_tiles"] for r in islands
        ),
        complete_island_median=float(np.median(complete)) if complete else None,
        complete_island_p90=float(np.quantile(complete, 0.9)) if complete else None,
        largest=islands[0],
        landing=landing,
        islands=islands,
    )
    return summary, land, cliffs


def factories(data, plan, config):
    stage = next(s for s in plan["stages"] if s["name"] == config["stage"])
    if stage["unreachable_targets"]:
        raise ValueError("unreachable factory targets")
    battery = data["accumulator"][config["battery"]]
    bw, bh = dimensions(battery)
    source = battery["energy_source"]
    capacity = prereqs.parse_energy(source["buffer_capacity"], "J") / 1e6
    discharge = prereqs.parse_energy(source["output_flow_limit"], "W") / 1e6
    rows = []
    for p in stage["plans"]:
        if (
            p["flow"]["status"] != "optimal"
            or p["construction"]["flow"]["status"] != "optimal"
        ):
            raise ValueError("factory production or construction is infeasible")
        factory = p["factory"]
        entries = []
        for name, machine in factory["machines"].items():
            _, proto = planner.entity(data, name)
            w, h = dimensions(proto)
            island = bool(
                proto.get("collision_mask", {})
                .get("layers", {})
                .get("nullius_fulgora_sand")
            )
            entries.append(
                dict(
                    name=name,
                    count=machine["count"],
                    width=w,
                    height=h,
                    island=island,
                    tiles=w * h * machine["count"],
                )
            )
        priority = factory["electric_mw_by_priority"]
        ordinary = sum(priority.get(k, 0) for k in ("primary-input", "secondary-input"))
        batteries = power_requirement(
            ordinary, capacity, discharge, 1, config["storage_seconds"]
        )["minimum_full_batteries"]
        layouts = {}
        for name, layout in config["layouts"].items():
            margin = layout["machine_margin"]
            reserve = layout["shared_space_fraction"]
            cells = sum(
                e["count"] * (e["width"] + 2 * margin) * (e["height"] + 2 * margin)
                for e in entries
                if e["island"]
            )
            gross = math.ceil((cells + batteries * bw * bh) / (1 - reserve))
            layouts[name] = dict(
                process_cells=cells,
                island_site_tiles=gross,
                equivalent_square_side=math.ceil(math.sqrt(gross)),
                required_blocks=math.ceil(gross / config["block_size"] ** 2),
            )
        rows.append(
            dict(
                rate=p["rate_per_minute"],
                machines=factory["process_machines"],
                labs=p["research_schedule"]["lab_count"],
                electric_mw=factory["electric_grid_mw"],
                surge_mw=priority.get("tertiary", 0),
                batteries=batteries,
                battery_tiles=batteries * bw * bh,
                island_machine_tiles=sum(e["tiles"] for e in entries if e["island"]),
                sand_machine_tiles=sum(e["tiles"] for e in entries if not e["island"]),
                layouts=layouts,
                machines_by_area=sorted(entries, key=lambda e: -e["tiles"]),
            )
        )
    return rows


def compare(factory, surveys, block_size):
    result = []
    for site in surveys:
        for layout, space in factory["layouts"].items():
            required = space["required_blocks"]
            capacities = sorted(
                (r["block_tiles"] // block_size**2 for r in site["islands"]),
                reverse=True,
            )
            total = 0
            needed = None
            for i, capacity in enumerate(capacities, 1):
                total += capacity
                if total >= required:
                    needed = i
                    break
            result.append(
                dict(
                    seed=site["seed"],
                    center=site["center"],
                    layout=layout,
                    minimum_islands_by_blocks=needed,
                    share_of_window_land_percent=100
                    * space["island_site_tiles"]
                    / site["land_tiles"],
                    landing_fits_by_area=(
                        (site["landing"]["block_tiles"] >= required * block_size**2)
                        if site["landing"]
                        else None
                    ),
                )
            )
    return result


def markdown(report):
    lines = [
        "| Seed / center | Land % | Clearable land | Cliff-free land | Largest island* | Landing island |",
        "|---|---:|---:|---:|---:|---:|",
    ]
    for s in report["terrain"]:
        lines.append(
            f"| {s['seed']} / {s['center']} | {s['land_percent']:.1f} | {s['land_tiles']:,} | {s['cliff_free_tiles']:,} | {s['largest']['tiles']:,}{'*' if s['largest']['clipped'] else ''} | {s['landing']['tiles'] if s['landing'] else '—'} |"
        )
    lines += [
        "",
        "*Boundary islands can extend beyond the survey. Areas are square tiles.",
        "",
        "| Packs/min each | Machines incl. labs | Bare island machines | Batteries | Compact site | Roomy site |",
        "|---|---:|---:|---:|---:|---:|",
    ]
    for r in report["factories"]:
        lines.append(
            f"| {r['rate']} | {r['machines']:,} | {r['island_machine_tiles']:,} | {r['batteries']:,} | {r['layouts']['compact']['island_site_tiles']:,} | {r['layouts']['roomy']['island_site_tiles']:,} |"
        )
    lines += [
        "",
        "| Packs/min each | Compact islands by blocks | Roomy islands by blocks |",
        "|---|---:|---:|",
    ]
    for factory in report["factories"]:
        ranges = []
        for layout in ("compact", "roomy"):
            values = [
                r["minimum_islands_by_blocks"]
                for r in factory["terrain_comparison"]
                if r["layout"] == layout
            ]
            fits = [v for v in values if v is not None]
            label = f"{min(fits)}–{max(fits)}" if fits else "none"
            if len(fits) != len(values):
                label += f"; exceeds {len(values)-len(fits)}/{len(values)} windows"
            ranges.append(label)
        lines.append(f"| {factory['rate']} | {ranges[0]} | {ranges[1]} |")
    lines += [
        "",
        "| Seed / center | Clearable block area | Cliff-free blocks | Complete island median / p90 |",
        "|---|---:|---:|---:|",
    ]
    for site in report["terrain"]:
        lines.append(
            f"| {site['seed']} / {site['center']} | {site['block_tiles']:,} | {site['cliff_free_block_tiles']:,} | {site['complete_island_median']} / {site['complete_island_p90']} |"
        )
    return "\n".join(lines)


def plot(surveys, config, destination, report):
    import matplotlib.pyplot as plt
    from matplotlib.colors import ListedColormap
    from matplotlib.patches import Rectangle

    origins = [row for row in surveys if row["center"] == [0, 0]]
    fig, axes = plt.subplots(1, len(origins), figsize=(15, 5), squeeze=False)
    square = next(r for r in report["factories"] if r["rate"] == 60)["layouts"][
        "roomy"
    ]["equivalent_square_side"]
    for ax, row in zip(axes[0], origins):
        summary, land, cliffs = terrain(row, config)
        pixels = np.where(land, 1, 0)
        pixels[land & cliffs] = 2
        ax.imshow(
            pixels,
            cmap=ListedColormap(["#a25745", "#ead3a0", "#383532"]),
            origin="lower",
            extent=(
                -row["size"] / 2,
                row["size"] / 2,
                -row["size"] / 2,
                row["size"] / 2,
            ),
        )
        ax.add_patch(
            Rectangle(
                (-row["size"] / 2 + 32, row["size"] / 2 - 32 - square),
                square,
                square,
                fill=False,
                edgecolor="#00a9ff",
                linewidth=2,
            )
        )
        ax.set_title(f"Seed {row['seed']} · {summary['land_percent']:.1f}% island")
        ax.set_xlabel("Tiles")
        ax.set_ylabel("Tiles")
    fig.suptitle(
        "Fulgora: islands (cream), cliff bounds (dark), sediment (red)\nBlue: 60/min roomy area-equivalent square, not a placed layout"
    )
    fig.tight_layout()
    fig.savefig(destination, dpi=160)
    plt.close(fig)


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--plan", type=Path)
    p.add_argument("--survey", type=Path)
    p.add_argument(
        "--config",
        type=Path,
        default=Path("tests/progression/planner/fulgora-area.json"),
    )
    p.add_argument("--output", type=Path)
    p.add_argument("--plot", type=Path)
    p.add_argument("--read-report", type=Path)
    p.add_argument("--field")
    p.add_argument("--rate", type=float)
    args = p.parse_args()
    if args.read_report:
        report = json.loads(args.read_report.read_text())
    else:
        if not args.plan or not args.survey or not args.output:
            p.error("--plan, --survey and --output are required")
        plan = json.loads(args.plan.read_text())
        suite = json.loads(args.survey.read_text())
        config = json.loads(args.config.read_text())
        if suite["status"] != "pass":
            raise ValueError("terrain survey failed")
        native = next(
            r for r in suite["results"] if r["case"] == "fulgora-island-survey"
        )
        data, work = prereqs.dump_resolved_data(prereqs.parse_arguments([]))
        try:
            digest = hashlib.sha256(
                (work / "script-output/data-raw-dump.json").read_bytes()
            ).hexdigest()
            if digest != plan["provenance"]["dump_sha256"]:
                raise ValueError("fresh prototypes differ from plan")
            rows = factories(data, plan, config)
        finally:
            if work:
                shutil.rmtree(work)
        surveys = [terrain(row, config)[0] for row in native["observations"]]
        for row in rows:
            row["terrain_comparison"] = compare(row, surveys, config["block_size"])
        ref = config["power_reference"]
        reference = dict(
            ref,
            allocated_tiles=ref["columns"]
            * ref["pitch"]
            * math.ceil(ref["pylons"] / ref["columns"])
            * ref["pitch"],
        )
        report = dict(
            provenance=dict(
                plan["provenance"],
                survey_sha256=hashlib.sha256(args.survey.read_bytes()).hexdigest(),
                area_config_sha256=hashlib.sha256(args.config.read_bytes()).hexdigest(),
            ),
            factorio=native["factorio_version"],
            config=config,
            terrain=surveys,
            factories=rows,
            power_reference=reference,
        )
        args.output.write_text(json.dumps(report, indent=2) + "\n")
        if args.plot:
            plot(native["observations"], config, args.plot, report)
    value = report
    if args.rate is not None:
        value = next(r for r in report["factories"] if r["rate"] == args.rate)
    if args.field:
        for key in args.field.split("."):
            value = value[key]
        print(json.dumps(value, indent=2))
    elif args.rate is not None:
        print(json.dumps(value, indent=2))
    else:
        print(markdown(report))


if __name__ == "__main__":
    main()
