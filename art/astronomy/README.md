# Astronomy models

| Model | Visible equipment | Footprint |
|---|---|---|
| Radio dish | Segmented reflector, feed supports, yoke, drive, control cabinet | 5×5 tiles |
| Pneumatic radio dish | Radio dish with pressure receivers and air pipes | 5×5 tiles |
| Correlator | Three electronics racks, cable trays, recording reader, cooling fans | 5×5 tiles |

`build.py` creates all geometry and material textures with Blender Python.
No external textures or models are required. The render uses Cycles on the CPU.

## Build

Use Blender 4.5.3 LTS and Python with Pillow. Run from the repository root:

```sh
python tools/render_astronomy.py --blender blender
```

The command writes editable `.blend` files, full-size render passes, and a log
into `release/astronomy/`. Each saved scene contains its camera, lights, and
procedural materials. Open a scene and render its active camera to inspect it.
Independent views and motion poses render in parallel. Worker and thread
counts depend on the available CPUs.
Each worker has a separate output directory and log. The publisher combines
the frames only after every worker succeeds. `render-timing.json` records the
worker count and elapsed times. Use `--jobs` to set the number of concurrent
scene processes and `--threads` to set the threads per process:

```sh
python tools/render_astronomy.py --blender blender --jobs 16 --threads 24
```

Generated sprites and icons are in `nullius-star/graphics/entity/astronomy/`
and `nullius-star/graphics/icons/astronomy/`. The publisher writes their scale,
shift, and animation settings to `nullius-star/prototypes/entity/astronomy-graphics.lua`.
The astronomy prototypes use these assets directly. `rendered/` contains the
preview and source and sprite hash manifest. Rebuild the assets when the source
changes. The publisher rejects empty or clipped sprites.

## Projection

The camera is orthographic, at 45 degrees above the ground. Ground geometry is
stretched by √2 along the camera axis so that tiles project as squares. The
reflector retains its circular shape. The render has 64 pixels per tile; the
sprite scale is 0.5. Body and shadow passes share an origin. The publisher
computes the shift after cropping and removes the shadow catcher's low-alpha
ambient noise. The preview shows 32 pixels per tile.

The render seed, engine version, projection, and SHA-256 hashes are in
`rendered/manifest.json`. CPU render rounding can change individual color
levels between runs.

Paint has a matte finish. Bare metal has a separate reflective response.
Broad surface variation and contact dirt give the panels depth. Fine texture
has low relief. Roof lips have short wear marks; plate joints and fasteners
break up the base. The reflector tilts about its elevation bearings while
the machine works.
The correlator fan blades turn below fixed guards. Bases and pipes stay fixed.
`motion.json` sets the pose counts, tilt, and playback speeds. Motion sheets
use the same crop for all frames.
One reflector animation serves both dish types in all directions. Each
direction selects its static base and pipe fittings. Each base keeps its
baked shading and shadow at the neutral pose. Fixed parts mask the moving
geometry that they cover. The glow has its own timing.
Indicators and the reader display pulse in a separate working layer. A small
light illuminates the nearby deck at night. Idle and unpowered
machines have dark indicators. Native working visuals control these effects.
The pneumatic preview disables the fluid burner's default white light.
Cabinet louvers, hinges, cooling fins, and clipped conduits add service details.
Deck gratings and access covers surround the ribbed pedestal. The lighter deck
material keeps these details visible at game scale.

## References

- [Wube projection explanation](https://www.factorio.com/blog/post/fff-133)
- [Factorio Blender setup guide](https://forums.factorio.com/viewtopic.php?p=614272)
- [Requested Blender example](https://mods.factorio.com/mod/blender-example):
  its archive download returned HTTP 403. Its scene was not used.

## Pipe fittings

Both dishes have a hydrogen socket. The pneumatic dish also has two connected
fuel sockets. Each native mounting plate seats on a broad cast inlet housing.
The hydrogen and fuel pipes bend down from their housings and enter the ground.
The fuel manifold runs below the deck between the side housings.
A branch at its centre feeds the pressure receivers.
Factorio draws the socket mouth, directional fitting, and disconnected cap.
This keeps the fitting style the same as the current dish prototypes.
Hydrogen enters from the north. Fuel passes between the west and east ports.
Only the pipe fittings, their supports, and the fuel manifold rotate.
The dish, pedestal, cabinets, and pressure receivers keep the same view.
The north hydrogen fitting draws behind the reflector. Both dishes have four
directional base and base-shadow renders. Their reflector sheets are shared.
For each view, the side inlet housings move towards the camera to align with
the native pipe fittings. The fluid connection positions stay fixed.

| Fluid | Connection on the 5×5 footprint | Adjacent pipe |
|---|---|---|
| Hydrogen | North, `{-1, -2}` | `{-1, -3}` |
| Compressed volcanic gas | West, `{-2, 0}` | `{-3, 0}` |
| Compressed volcanic gas | East, `{2, 0}` | `{3, 0}` |

The hydro plant uses Angel's fittings with its own shifts. These shifts fit its
body shape. Do not apply them to the dish. The standard assembler fittings use
four directional sprites; the engine selects the fitting and cap from the
fluid connection state. See [FluidBox](https://lua-api.factorio.com/latest/types/FluidBox.html).

Run the native connector check after rendering:

```sh
python tools/preview_astronomy.py
```

This checks the packaged machine prototypes and their 5×5 footprints. It checks
all four orientations, fuel flow between the side ports, and capped and
connected states beside a hydro plant. The real client runs in a
private virtual display. The image, result, and logs are saved in
`release/astronomy/`. `connectors-alignment.png` shows magnified left, right, and
south fittings for visual inspection. Connection assertions check fluid links;
the images are required to check sprite alignment.

`connectors-centres.png` marks the fuel centreline in cyan. The result also
records the engine's connection and target positions for every orientation.

The same command checks working, powered-idle, and unpowered machines with
real recipes. `lighting-day.png` and `lighting-night.png` show these states.
`lighting-night-pulse.png` captures another point in the glow cycle.
`astronomy-motion.webp` shows working motion in daylight.
`astronomy-glow.webp` shows the same equipment with its glow at night.
The previews loop with the real crafting-rate timing. The source frames remain in
`motion-frames/` and `glow-frames/` beside the animations. The two lossless
previews encode in parallel.
The preview checks that the glow changes on working machines and stays dark
on idle and unpowered machines. It also checks movement on working machines
and fixed poses on idle and unpowered machines. `lighting-measurements.json`
and `motion-measurements.json` record the image checks.
The glow pass contains visible light sources only. The body pass keeps their
unlit faces, so the machine can stop emitting light without changing its body.
