#!/usr/bin/env python3
"""Render native pipe fittings on the astronomy art in an isolated Factorio client."""

import argparse
from concurrent.futures import ThreadPoolExecutor
import json
from pathlib import Path
import shutil
import sys
import tempfile

from PIL import Image, ImageChops, ImageDraw, ImageSequence, ImageStat

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))


def measure_glow(output, result):
    """Check visible glow variation and dark idle states in native captures."""
    metadata = json.loads((output / "render.json").read_text())
    images = [
        Image.open(output / f"lighting-{state}.png").convert("RGB")
        for state in ("night", "night-pulse")
    ]
    names = {
        "nullius-radio-dish": "radio-dish",
        "nullius-radio-dish-pneumatic": "pneumatic-radio-dish",
        "nullius-correlator": "correlator",
    }
    measurements = {}
    for machine in result["machines"]:
        model = names[machine["name"]]
        glow = Image.open(output / (model + "-glow.png")).convert("RGBA")
        zoom = result["zoom"]
        cx = (
            images[0].width / 2
            + (machine["position"]["x"] - result["camera"]["x"]) * 32 * zoom
        )
        cy = (
            images[0].height / 2
            + (machine["position"]["y"] - result["camera"]["y"]) * 32 * zoom
        )
        points = set()
        for index, (r, g, b, alpha) in enumerate(glow.getdata()):
            if max(r, g, b) * alpha < 32 * 255:
                continue
            x = round(
                cx
                + (index % glow.width - metadata["origin"][0])
                * 32
                * zoom
                / metadata["pixels_per_tile"]
            )
            y = round(
                cy
                + (index // glow.width - metadata["origin"][1])
                * 32
                * zoom
                / metadata["pixels_per_tile"]
            )
            points.update((x + dx, y + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1))
        if not points:
            raise RuntimeError(f"No visible glow samples for {model}")
        samples = [[image.getpixel(point) for point in points] for image in images]
        brightness = [
            sum(sum(pixel) for pixel in sample) / (len(points) * 3)
            for sample in samples
        ]
        delta = sum(abs(a - b) for p, q in zip(*samples) for a, b in zip(p, q)) / (
            len(points) * 3
        )
        measurements.setdefault(model, {})[machine["state"]] = {
            "brightness": brightness,
            "pulse_delta": delta,
        }
    (output / "lighting-measurements.json").write_text(
        json.dumps(measurements, indent=2) + "\n"
    )
    for model, states in measurements.items():
        if states["Working"]["pulse_delta"] <= 0.5:
            raise RuntimeError(f"Working glow did not visibly pulse: {model}")
        for state in ("Idle", "Unpowered"):
            if states[state]["pulse_delta"] > 1:
                raise RuntimeError(f"Inactive glow changed intensity: {model} {state}")
            if (
                min(states["Working"]["brightness"])
                <= max(states[state]["brightness"]) + 5
            ):
                raise RuntimeError(
                    f"Working glow does not exceed inactive brightness: {model} {state}"
                )


def make_animation_webp(run, output, mode="glow"):
    """Save a lossless WebP from native working-machine captures."""
    result = json.loads((output / "lighting-result.json").read_text())
    ticks = result["animation_ticks" if mode == "glow" else "motion_ticks"]
    if len(ticks) != 64 or any(b - a != 5 for a, b in zip(ticks, ticks[1:])):
        raise RuntimeError(
            "Animation capture must contain 64 frames spaced five ticks apart"
        )
    machines = [
        machine for machine in result["machines"] if machine["state"] == "Working"
    ]
    labels = ("Electric dish", "Pneumatic dish", "Correlator")
    frames = []
    captures = output / f"{mode}-frames"
    captures.mkdir(exist_ok=True)
    for index in range(len(ticks)):
        sources = list(run.glob(f"**/script-output/astronomy-{mode}/{index:02d}.png"))
        if len(sources) != 1:
            raise RuntimeError(f"Expected one {mode} frame {index}, got {sources}")
        shutil.copyfile(sources[0], captures / f"{index:02d}.png")
        with Image.open(sources[0]) as source:
            frame = Image.new("RGB", (900, 410), (15, 19, 28))
            draw = ImageDraw.Draw(frame)
            for column, (machine, label) in enumerate(zip(machines, labels)):
                cx = (
                    source.width / 2
                    + (machine["position"]["x"] - result["animation_camera"]["x"])
                    * 32
                    * result["animation_zoom"]
                )
                cy = (
                    source.height / 2
                    + (machine["position"]["y"] - result["animation_camera"]["y"])
                    * 32
                    * result["animation_zoom"]
                )
                crop = source.crop(
                    (round(cx - 140), round(cy - 240), round(cx + 140), round(cy + 130))
                )
                frame.paste(crop, (column * 300 + 10, 30))
                draw.text((column * 300 + 10, 10), label, fill=(210, 215, 225))
            frames.append(frame)
    durations = [
        round((index + 1) * 1000 / 12) - round(index * 1000 / 12)
        for index in range(len(ticks))
    ]
    path = output / f"astronomy-{mode}.webp"
    frames[0].save(
        path,
        save_all=True,
        append_images=frames[1:],
        duration=durations,
        loop=0,
        lossless=True,
        quality=100,
        method=4,
    )
    with Image.open(path) as animation:
        if animation.info["loop"] != 0:
            raise RuntimeError("Native footage must loop continuously")
        if animation.n_frames != len(frames):
            raise RuntimeError("WebP lost animation frames")
        duration = 0
        for index, frame in enumerate(ImageSequence.Iterator(animation)):
            decoded = frame.convert("RGB")
            duration += frame.info["duration"]
            if decoded.tobytes() != frames[index].tobytes():
                raise RuntimeError(f"WebP changed pixels in frame {index}")
        if duration != sum(durations):
            raise RuntimeError(f"WebP lost animation timing: {duration}ms")
    print("Animation:", path)


def measure_motion(output, result):
    """Check that working equipment moves and inactive equipment stays still."""
    images = [
        Image.open(output / f"lighting-{state}.png").convert("RGB")
        for state in ("day", "motion-start", "motion-end")
    ]
    measurements = {}
    for machine in result["machines"]:
        zoom = result["zoom"]
        cx = (
            images[0].width / 2
            + (machine["position"]["x"] - result["camera"]["x"]) * 32 * zoom
        )
        cy = (
            images[0].height / 2
            + (machine["position"]["y"] - result["camera"]["y"]) * 32 * zoom
        )
        # Upper reflector or roof fans; exclude the pulsing cabinet lights and deck light.
        box = tuple(
            round(v)
            for v in (cx - 72 * zoom, cy - 123 * zoom, cx + 72 * zoom, cy - 55 * zoom)
        )
        crops = [image.crop(box) for image in images]
        delta = max(
            sum(ImageStat.Stat(ImageChops.difference(crops[0], other)).mean) / 3
            for other in crops[1:]
        )
        key = machine["name"] + ":" + machine["state"]
        measurements[key] = delta
        if machine["state"] == "Working":
            if delta < 0.5:
                raise RuntimeError(f"Working motion not visible: {key}: {delta}")
        elif delta > 0.1:
            raise RuntimeError(f"Inactive equipment moved: {key}: {delta}")
    (output / "motion-measurements.json").write_text(
        json.dumps(measurements, indent=2) + "\n"
    )


def main():
    from tools import run_factorio_tests as runner

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--factorio", type=Path, default=runner.default_factorio())
    parser.add_argument(
        "--dependency-mod-directory",
        type=Path,
        default=runner.default_dependency_mods(),
    )
    args = parser.parse_args()
    output = ROOT / "release/astronomy"
    output.mkdir(parents=True, exist_ok=True)
    stage = Path(tempfile.mkdtemp(prefix="pipe-preview-", dir=output))
    args.mod_under_test = ROOT / "nullius-star"
    args.until_tick = None
    args.timeout_seconds = None
    with ThreadPoolExecutor(max_workers=2) as executor:
        connector_run = executor.submit(
            runner.execute, args, "astronomy-connectors", stage / "run"
        )
        lighting_run = executor.submit(
            runner.execute, args, "astronomy-lighting", stage / "lighting-run"
        )
        result = connector_run.result()
        lighting = lighting_run.result()
    for state in ("capped", "connected", "centres"):
        captures = list(
            (stage / "run").glob(f"**/script-output/astronomy-connectors-{state}.png")
        )
        if len(captures) != 1:
            raise RuntimeError(f"Expected one {state} screenshot, got {captures}")
        shutil.copyfile(captures[0], output / f"connectors-{state}.png")
    detail = Image.new("RGB", (1200, 850), (49, 53, 54))
    draw = ImageDraw.Draw(detail)
    # Camera and placements are declared by the astronomy-connectors scenario.
    joins = (("Left", -1.5, 9.5), ("Right", 2.5, 9.5), ("South", 19.5, 2.5))
    for row, state in enumerate(("capped", "connected")):
        with Image.open(output / f"connectors-{state}.png") as screenshot:
            for column, (label, x, y) in enumerate(joins):
                cx = screenshot.width / 2 + (x - 14) * 32 * 1.3
                cy = screenshot.height / 2 + (y - 7) * 32 * 1.3
                crop = screenshot.crop(
                    (round(cx - 64), round(cy - 64), round(cx + 64), round(cy + 64))
                )
                crop = crop.resize((384, 384), Image.Resampling.NEAREST)
                detail.paste(crop, (column * 400 + 8, row * 425 + 32))
                draw.text(
                    (column * 400 + 8, row * 425 + 10),
                    f"{label} / {state} / 3x",
                    fill=(240, 240, 240),
                )
    detail.save(output / "connectors-alignment.png")
    (output / "connectors-result.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))
    for state in ("day", "night", "night-pulse", "motion-start", "motion-end"):
        captures = list(
            (stage / "lighting-run").glob(
                f"**/script-output/astronomy-lighting-{state}.png"
            )
        )
        if len(captures) != 1:
            raise RuntimeError(
                f"Expected one {state} lighting screenshot, got {captures}"
            )
        shutil.copyfile(captures[0], output / f"lighting-{state}.png")
    (output / "lighting-result.json").write_text(json.dumps(lighting, indent=2) + "\n")
    measure_glow(output, lighting)
    with ThreadPoolExecutor(max_workers=2) as executor:
        previews = [
            executor.submit(make_animation_webp, stage / "lighting-run", output, mode)
            for mode in ("glow", "motion")
        ]
        for preview in previews:
            preview.result()
    measure_motion(output, lighting)
    print(json.dumps(lighting, indent=2))
    print("Screenshot:", output / "connectors-connected.png")
    print("Logs:", stage)


if __name__ == "__main__":
    main()
