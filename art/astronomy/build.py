"""Build original astronomy meshes, procedural materials and transparent renders."""

import argparse
import json
import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector, Matrix, Quaternion

SIZE = 768
PIXELS_PER_TILE = 64
M = {}
MOTIONS = json.loads(Path(__file__).with_name("motion.json").read_text())


def material(name, color, metal=0.0, roughness=0.65, wear=True, emission=False):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    n, links = mat.node_tree.nodes, mat.node_tree.links
    shader = n.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1)
    shader.inputs["Metallic"].default_value = metal
    shader.inputs["Roughness"].default_value = roughness
    if emission:
        mat["glow_color"] = color
        shader.inputs["Base Color"].default_value = (*(c * 0.08 for c in color), 1)
    if wear:
        coords = n.new("ShaderNodeTexCoord")
        broad = n.new("ShaderNodeTexNoise")
        broad.inputs["Scale"].default_value = 4.5
        broad.inputs["Detail"].default_value = 3
        links.new(coords.outputs["Generated"], broad.inputs["Vector"])
        ramp = n.new("ShaderNodeValToRGB")
        ramp.color_ramp.elements[0].position = 0.23
        ramp.color_ramp.elements[0].color = (*(c * 0.62 for c in color), 1)
        ramp.color_ramp.elements[1].position = 0.78
        ramp.color_ramp.elements[1].color = (*color, 1)
        links.new(broad.outputs["Fac"], ramp.inputs[0])
        ao = n.new("ShaderNodeAmbientOcclusion")
        ao.inputs["Distance"].default_value = 0.22
        ao.samples = 16
        dirt = n.new("ShaderNodeMixRGB")
        dirt.blend_type = "MULTIPLY"
        dirt.inputs[0].default_value = 0.65
        links.new(ramp.outputs["Color"], dirt.inputs[1])
        links.new(ao.outputs["Color"], dirt.inputs[2])
        links.new(dirt.outputs["Color"], shader.inputs["Base Color"])
        rough = n.new("ShaderNodeMapRange")
        rough.inputs["To Min"].default_value = max(0.12, roughness - 0.18)
        rough.inputs["To Max"].default_value = min(1, roughness + 0.18)
        links.new(broad.outputs["Fac"], rough.inputs["Value"])
        links.new(rough.outputs["Result"], shader.inputs["Roughness"])
        fine = n.new("ShaderNodeTexNoise")
        fine.inputs["Scale"].default_value = 85
        fine.inputs["Detail"].default_value = 2
        links.new(coords.outputs["Generated"], fine.inputs["Vector"])
        bump = n.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = 0.10
        bump.inputs["Distance"].default_value = 0.008
        links.new(fine.outputs["Fac"], bump.inputs["Height"])
        links.new(bump.outputs["Normal"], shader.inputs["Normal"])
    M[name] = mat
    return mat


def finish(obj, name, mat, parent=None, bevel=0):
    obj.name = name
    obj.data.materials.append(M[mat])
    if parent:
        obj.parent = parent
    if bevel:
        mod = obj.modifiers.new("Machined edge", "BEVEL")
        mod.width = bevel
        mod.segments = 2
        obj.modifiers.new("Corner normals", "WEIGHTED_NORMAL")
    return obj


def box(name, position, size, mat, parent=None, bevel=0.018):
    bpy.ops.mesh.primitive_cube_add(size=1, location=position)
    obj = bpy.context.object
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, name, mat, parent, bevel)


def cylinder(
    name, position, radius, depth, mat, parent=None, vertices=32, rotation=None
):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices, radius=radius, depth=depth, location=position
    )
    obj = bpy.context.object
    if rotation:
        obj.rotation_euler = rotation
    for face in obj.data.polygons:
        face.use_smooth = len(face.vertices) == 4
    return finish(obj, name, mat, parent, 0.015)


def tube(name, points, radius, mat, parent=None):
    curve = bpy.data.curves.new(name, "CURVE")
    curve.dimensions = "3D"
    curve.bevel_depth = radius
    curve.bevel_resolution = 2
    curve.use_fill_caps = True
    spline = curve.splines.new("POLY")
    spline.points.add(len(points) - 1)
    for target, point in zip(spline.points, points):
        target.co = (*point, 1)
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(M[mat])
    obj.parent = parent
    return obj


def ring(name, center, radius, thickness, mat, parent=None):
    return tube(
        name,
        [
            (
                center[0] + radius * math.cos(a * math.tau / 96),
                center[1] + radius * math.sin(a * math.tau / 96),
                center[2],
            )
            for a in range(97)
        ],
        thickness,
        mat,
        parent,
    )


def bolt(x, y, z, parent=None):
    cylinder("Hex bolt", (x, y, z), 0.045, 0.04, "steel", parent, vertices=6)


def platform():
    box("Concrete footing", (0, 0, 0.07), (4.55, 4.55, 0.14), "concrete", bevel=0.08)
    box("Cast plinth", (0, 0, 0.2), (4.3, 4.3, 0.14), "deck")
    for x in (-2.0, 2.0):
        for y in (-2.0, 2.0):
            box("Anchor plate", (x, y, 0.31), (0.32, 0.32, 0.07), "steel")
            bolt(x, y, 0.37)
    # Grooves and chipped panel joints remain visible at sprite scale.
    for x in (-1.4, 0, 1.4):
        box("Slab joint", (x, 0, 0.145), (0.018, 4.5, 0.005), "dark", bevel=0)
    for x in (-1.4, 0, 1.4):
        for y in (-1.55, -0.5, 0.55, 1.6):
            box(
                "Deck plate seam", (x, y, 0.277), (1.32, 0.022, 0.012), "black", bevel=0
            )
            bolt(x - 0.55, y + 0.12, 0.285)
    for i in range(9):
        box(
            "Safety stripe",
            (-1.8 + i * 0.45, -2.14, 0.29),
            (0.23, 0.13, 0.025),
            "ochre" if i % 2 == 0 else "dark",
            bevel=0,
        )


def radiator(x, y, z, width=0.7):
    box("Cooling core", (x, y, z), (width, 0.48, 0.7), "dark")
    for i in range(10):
        box(
            "Cooling fin",
            (x - width / 2 + (i + 0.5) * width / 10, y, z),
            (0.027, 0.53, 0.73),
            "steel",
            bevel=0.004,
        )
    for dz in (-0.35, 0.35):
        box("Radiator header", (x, y, z + dz), (width + 0.08, 0.58, 0.08), "olive")


def industrial_pipe(name, points, radius=0.27):
    points = [Vector(point) for point in points]
    rounded = [points[0]]
    for previous, corner, following in zip(points, points[1:], points[2:]):
        incoming, outgoing = previous - corner, following - corner
        trim = min(0.24, incoming.length / 3, outgoing.length / 3)
        start = corner + incoming.normalized() * trim
        end = corner + outgoing.normalized() * trim
        for step in range(9):
            t = step / 8
            rounded.append(
                (1 - t) ** 2 * start + 2 * (1 - t) * t * corner + t * t * end
            )
    rounded.append(points[-1])
    return tube(name, rounded, radius, "pipe-metal")


def port(x, hydrogen=False):
    before = set(bpy.context.scene.objects)
    # The engine's bolted plate seats against this broad casting face.
    vertices = []
    for dx in (-0.46, 0.46):
        vertices.extend(
            [
                (x + dx, 1.98, 0.12),
                (x + dx, 2.48, 0.12),
                (x + dx, 2.08, 0.82),
                (x + dx, 1.98, 0.82),
            ]
        )
    mesh = bpy.data.meshes.new("Inlet casting")
    mesh.from_pydata(
        vertices,
        [],
        [
            (0, 3, 2, 1),
            (4, 5, 6, 7),
            (0, 1, 5, 4),
            (1, 2, 6, 5),
            (2, 3, 7, 6),
            (3, 0, 4, 7),
        ],
    )
    mesh.update()
    obj = bpy.data.objects.new("Inlet casting", mesh)
    bpy.context.collection.objects.link(obj)
    finish(obj, "Sloped inlet mounting face", "cast-iron", bevel=0.035)
    box("Casting foot", (x, 2.24, 0.16), (1.0, 0.52, 0.15), "cast-iron")
    for dx in (-0.36, 0.36):
        bolt(x + dx, 2.02, 0.86)
    bend = [
        (x, 2.08 - 0.18 * math.sin(t), 0.36 + 0.18 * math.cos(t))
        for t in (step * math.pi / 32 for step in range(17))
    ]
    tube(
        "Hydrogen ground pipe" if hydrogen else "Fuel ground pipe",
        [(x, 2.12, 0.54), *bend, (x, 1.9, -0.25)],
        0.16,
        "pipe-metal",
    )
    for part in set(bpy.context.scene.objects) - before:
        part["inlet_facing"] = 0


def side_port(side):
    before = set(bpy.context.scene.objects)
    port(0)
    rotation = Matrix.Rotation(-side * math.pi / 2, 4, "Z")
    for obj in set(bpy.context.scene.objects) - before:
        obj.matrix_world = rotation @ obj.matrix_world
        if "inlet_facing" in obj:
            obj["inlet_facing"] = side


def dish(pneumatic=False):
    platform()
    box("Drain frame", (0.15, -1.28, 0.29), (0.76, 0.76, 0.04), "steel")
    box("Drain recess", (0.15, -1.28, 0.315), (0.64, 0.64, 0.02), "black")
    for i in range(6):
        box(
            "Drain grate",
            (-0.1 + i * 0.1, -1.28, 0.335),
            (0.045, 0.62, 0.035),
            "cast-iron",
            bevel=0.006,
        )
    box("Deck access seal", (-1.15, -1.75, 0.285), (0.86, 0.36, 0.025), "black")
    box("Deck access cover", (-1.15, -1.75, 0.31), (0.78, 0.28, 0.035), "olive")
    for x in (-1.46, -0.84):
        bolt(x, -1.75, 0.345)
    tube(
        "Hatch pull",
        [
            (-1.25, -1.75, 0.33),
            (-1.25, -1.75, 0.38),
            (-1.05, -1.75, 0.38),
            (-1.05, -1.75, 0.33),
        ],
        0.025,
        "steel",
    )
    accent = "copper" if pneumatic else "blue"
    cylinder("Azimuth foundation", (0, 0.1, 0.5), 0.88, 0.45, "dark")
    for degrees in (195, 225, 255, 285, 315, 345):
        a = math.radians(degrees)
        rib = box(
            "Pedestal cast rib",
            (0.88 * math.cos(a), 0.1 + 0.88 * math.sin(a), 0.49),
            (0.2, 0.1, 0.36),
            "cast-iron",
            bevel=0.025,
        )
        rib.rotation_euler.z = a
    cylinder("Slewing ring", (0, 0.1, 0.77), 0.79, 0.14, "steel", vertices=64)
    for i in range(24):
        a = math.tau * i / 24
        bolt(0.68 * math.cos(a), 0.1 + 0.68 * math.sin(a), 0.87)
    box("Azimuth motor", (0.93, 0.1, 0.65), (0.6, 0.65, 0.55), accent)
    for x in (-0.52, 0.52):
        box("Yoke leg", (x, 0.1, 1.43), (0.32, 0.54, 1.3), "olive")
        cylinder(
            "Elevation bearing",
            (x, 0.1, 2.0),
            0.29,
            0.44,
            "steel",
            rotation=(0, math.pi / 2, 0),
        )
        cylinder(
            "Bearing cap",
            (x + (-0.26 if x < 0 else 0.26), 0.1, 2),
            0.23,
            0.1,
            accent,
            rotation=(0, math.pi / 2, 0),
        )
        tube("Yoke brace", [(x, -0.3, 0.8), (x, -0.1, 1.8)], 0.11, "olive")
    bpy.ops.object.empty_add()
    head = bpy.context.object
    head.name = "Reflector elevation pivot"
    head.location = (0, 0.1, 2.0)
    head.rotation_euler = (math.radians(18), 0, math.radians(-12))
    # Each panel is a bounded section of z = r^2 / (4f).
    radius, focal = 1.86, 1.12
    for sector in range(24):
        vertices = []
        faces = []
        for radial in range(13):
            r = 0.06 + (radius - 0.06) * radial / 12
            for side in range(5):
                a = math.tau * (sector + (0.014 + 0.972 * side / 4)) / 24
                vertices.append((r * math.cos(a), r * math.sin(a), r * r / (4 * focal)))
        for radial in range(12):
            for side in range(4):
                i = radial * 5 + side
                faces.append((i, i + 1, i + 6, i + 5))
        mesh = bpy.data.meshes.new("Parabolic reflector panel")
        mesh.from_pydata(vertices, [], faces)
        mesh.update()
        obj = bpy.data.objects.new("Reflector panel %02d" % sector, mesh)
        bpy.context.collection.objects.link(obj)
        finish(obj, obj.name, "porcelain" if sector % 4 else "panel", head)
        for face in mesh.polygons:
            face.use_smooth = True
        solid = obj.modifiers.new("Panel thickness", "SOLIDIFY")
        solid.thickness = 0.035
        a = math.tau * (sector + 0.5) / 24
        tube(
            "Back rib",
            [
                (r * math.cos(a), r * math.sin(a), r * r / (4 * focal) - 0.08)
                for r in (0.1, 0.5, 1, 1.5, radius)
            ],
            0.035,
            "steel",
            head,
        )
    ring(
        "Reflector rim",
        (0, 0, radius * radius / (4 * focal)),
        radius,
        0.055,
        "steel",
        head,
    )
    for angle in (30, 150, 270):
        a = math.radians(angle)
        tube(
            "Feed strut",
            [
                (radius * 0.88 * math.cos(a), radius * 0.88 * math.sin(a), 0.62),
                (0.12 * math.cos(a), 0.12 * math.sin(a), focal + 0.08),
            ],
            0.036,
            "dark",
            head,
        )
    cylinder("Receiver feed", (0, 0, focal), 0.17, 0.34, "dark", head)
    ring("Feed collar", (0, 0, focal + 0.12), 0.18, 0.025, "copper", head)
    tube(
        "Receiver cable",
        [
            (0, 0, focal + 0.2),
            (0, -0.16, focal + 0.25),
            (0, -1.6, 0.7),
            (0, -1.65, -0.15),
            (0, -0.5, -0.5),
        ],
        0.027,
        "blue",
        head,
    )
    for child in head.children:
        child.location.z += 0.4
    box("Service cabinet", (-1.25, -0.95, 0.75), (0.85, 0.9, 0.96), "olive")
    box("Cabinet door", (-1.25, -1.415, 0.75), (0.72, 0.045, 0.76), "panel")
    box("Cabinet latch", (-0.97, -1.45, 0.8), (0.045, 0.05, 0.18), "dark")
    for x in (-1.42, -1.2):
        box("Status lamp", (x, -1.45, 1.0), (0.1, 0.04, 0.07), "amber", bevel=0.01)
    box("Cabinet roof vent recess", (-1.25, -0.95, 1.235), (0.59, 0.61, 0.025), "black")
    for i in range(5):
        louver = box(
            "Cabinet roof louver",
            (-1.25, -1.19 + i * 0.12, 1.265),
            (0.55, 0.085, 0.045),
            "olive",
            bevel=0.008,
        )
        louver.rotation_euler.x = math.radians(20)
    for z in (0.55, 1.03):
        cylinder("Cabinet hinge", (-1.59, -1.45, z), 0.045, 0.16, "steel")
    for z in (0.48, 0.55, 0.62):
        box(
            "Cabinet intake slot",
            (-1.25, -1.445, z),
            (0.43, 0.022, 0.025),
            "black",
            bevel=0.005,
        )
    tube(
        "Cabinet handle",
        [
            (-0.99, -1.45, 0.73),
            (-0.99, -1.51, 0.73),
            (-0.99, -1.51, 0.9),
            (-0.99, -1.45, 0.9),
        ],
        0.025,
        "steel",
    )
    box("Cable junction", (-0.65, -1.1, 0.38), (0.28, 0.3, 0.2), "cast-iron")
    box("Junction lid", (-0.65, -1.1, 0.49), (0.3, 0.32, 0.035), "olive")
    bolt(-0.65, -1.1, 0.525)
    radiator(1.45, 1.1, 0.75)
    port(-1, hydrogen=True)
    if pneumatic:
        for x in (1.2, 1.85):
            cylinder("Pressure receiver", (x, -1.15, 1.18), 0.29, 1.5, "copper")
            for z in (0.43, 1.93):
                bpy.ops.mesh.primitive_uv_sphere_add(
                    segments=32, ring_count=16, radius=1, location=(x, -1.15, z)
                )
                cap = bpy.context.object
                cap.scale = (0.29, 0.29, 0.22)
                for face in cap.data.polygons:
                    face.use_smooth = True
                finish(cap, "Domed pressure vessel end", "copper")
            for z in (0.64, 1.66):
                ring("Tank clamp", (x, -1.15, z), 0.30, 0.045, "steel")
            cylinder(
                "Pressure gauge",
                (x, -1.47, 1.72),
                0.12,
                0.07,
                "porcelain",
                rotation=(math.pi / 2, 0, 0),
            )
            tube(
                "Gauge needle",
                [(x, -1.515, 1.72), (x + 0.055, -1.515, 1.78)],
                0.014,
                "dark",
            )
            tube(
                "Receiver feed",
                [
                    (x, -1.15, 2.12),
                    (x, -0.72, 2.12),
                    (1.9, -0.72, 1.6),
                    (1.9, 0.1, 1.6),
                    (0.95, 0.1, 1.6),
                ],
                0.07,
                "copper",
            )
        side_port(-1)
        side_port(1)
        industrial_pipe("Pressure manifold", [(-2.1, 0, -0.05), (2.1, 0, -0.05)])[
            "rotate_with_ports"
        ] = True
        industrial_pipe(
            "Receiver branch",
            [
                (0, 0, -0.05),
                (1.85, 0, -0.05),
                (1.85, -1.15, -0.05),
                (1.85, -1.15, 0.48),
            ],
            radius=0.22,
        )

    else:
        box("Drive electronics", (1.45, -1.2, 0.55), (0.75, 0.95, 0.5), "blue")
        box("Drive cooling plate", (1.45, -1.2, 0.815), (0.62, 0.7, 0.04), "dark")
        for i in range(6):
            box(
                "Drive cooling fin",
                (1.2 + i * 0.1, -1.2, 0.89),
                (0.035, 0.64, 0.13),
                "steel",
                bevel=0.005,
            )
        tube(
            "Drive conduit",
            [(1.1, -1.2, 0.43), (0.85, -1.1, 0.36), (0.6, -0.6, 0.44)],
            0.055,
            "steel",
        )
        for i in range(5):
            box(
                "Drive vent",
                (1.45, -1.6, 0.48 + i * 0.045),
                (0.55, 0.025, 0.018),
                "dark",
                bevel=0,
            )
    tube(
        "Drive cable",
        [(-0.85, -1.1, 0.38), (-0.65, -1.1, 0.38), (-0.4, -0.65, 0.48)],
        0.065,
        "steel",
    )
    box("Conduit clip", (-0.5, -0.84, 0.405), (0.19, 0.08, 0.13), "cast-iron")


def fan(x, y, z):
    cylinder("Fan housing", (x, y, z), 0.54, 0.14, "dark", vertices=48)
    cylinder("Fan well", (x, y, z + 0.08), 0.43, 0.03, "black", vertices=48)
    bpy.ops.object.empty_add(location=(x, y, z))
    rotor = bpy.context.object
    rotor.name = "Fan rotor"
    rotor["fan_rotor"] = True
    blades = MOTIONS["correlator-fans"]["blades"]
    for i in range(blades):
        a = i * math.tau / blades
        blade = box(
            "Fan blade",
            (0.23 * math.cos(a), 0.23 * math.sin(a), 0.11),
            (0.37, 0.13, 0.025),
            "steel",
            bevel=0.01,
        )
        blade.parent = rotor
        blade.rotation_euler.z = a + 0.3
    cylinder("Fan hub", (x, y, z + 0.14), 0.1, 0.09, "olive")
    ring("Fan guard rim", (x, y, z + 0.18), 0.46, 0.022, "steel")
    for dy in (-0.3, -0.15, 0, 0.15, 0.3):
        extent = math.sqrt(0.45**2 - dy**2)
        tube(
            "Fan guard",
            [(x - extent, y + dy, z + 0.19), (x + extent, y + dy, z + 0.19)],
            0.013,
            "steel",
        )


def correlator():
    platform()
    for x in (-1.3, 0, 1.3):
        box("Rack frame", (x, 0.45, 1.12), (1.05, 2.15, 1.65), "dark")
        box("Rack armor", (x, 0.45, 1.98), (1.12, 2.23, 0.12), "olive")
        for dx in (-0.44, 0.44):
            for y in (-0.45, 1.35):
                bolt(x + dx, y, 2.065)
            for y, length in ((-0.2, 0.25), (0.65, 0.4), (1.25, 0.12)):
                box(
                    "Scuffed roof lip",
                    (x + dx, y, 2.045),
                    (0.045, length, 0.015),
                    "steel",
                    bevel=0,
                )
        for y in (-0.67, 1.56):
            for dx in (-0.48, 0.48):
                box("Rack corner", (x + dx, y, 1.16), (0.09, 0.1, 1.61), "steel")
        for j in range(6):
            z = 0.53 + j * 0.23
            box(
                "Processor drawer",
                (x, -0.68, z),
                (0.86, 0.075, 0.18),
                "blue" if j % 3 == 0 else "panel",
            )
            for side in (-1, 1):
                box(
                    "Drawer pull",
                    (x + side * 0.32, -0.74, z),
                    (0.065, 0.04, 0.1),
                    "dark",
                )
            for led in range(3):
                box(
                    "Activity indicator",
                    (x - 0.16 + led * 0.1, -0.728, z + 0.015),
                    (0.045, 0.02, 0.032),
                    "amber" if (j + led) % 3 else "cyan",
                    bevel=0.002,
                )
        # Roof-level connectors and distinct cable bundles identify data processing.
        for j in range(2):
            y = -0.25 + j * 0.4
            box("Roof interconnect", (x, y, 2.09), (0.7, 0.17, 0.12), "steel")
            tube(
                "Data bundle",
                [
                    (x + 0.25, y, 2.17),
                    (x + 0.48, y, 2.25),
                    (x + 0.53, -0.95, 2.25),
                    (x + 0.53, -1.16, 0.55),
                ],
                0.045,
                "ochre",
            )
    box("Shared data trunk", (0, -1.2, 0.42), (3.9, 0.34, 0.24), "dark")
    for x in (-1.4, -0.7, 0, 0.7, 1.4):
        box("Trunk clamp", (x, -1.2, 0.55), (0.1, 0.4, 0.04), "steel")
    box("Cooling skid", (0, 1.7, 0.82), (3.8, 0.65, 1.05), "olive")
    fan(-1.3, 0.9, 2.10)
    fan(1.3, 0.9, 2.10)
    radiator(0, 0.9, 2.38, width=0.65)
    for x in (-1.9, 1.9):
        radiator(x, 0.65, 1.0, width=0.35)
        tube(
            "Closed coolant loop",
            [(x, 1.65, 1.1), (x, 1.0, 1.1), (x, 0.95, 0.45), (x, -0.65, 0.45)],
            0.06,
            "copper",
        )
    box("Recording reader", (0, -1.75, 0.73), (1.4, 0.55, 0.75), "olive")
    box("Reader display bezel", (0, -2.035, 0.59), (0.62, 0.045, 0.23), "dark")
    box("Reader display", (0, -2.062, 0.59), (0.5, 0.025, 0.13), "cyan")
    for x in (-0.43, 0, 0.43):
        box(
            "Recording module slot",
            (x, -2.04, 0.82),
            (0.25, 0.025, 0.12),
            "black",
            bevel=0.005,
        )
        box(
            "Slot indicator", (x, -2.06, 0.99), (0.18, 0.025, 0.04), "cyan", bevel=0.005
        )


def scene_setup(threads):
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for mat in list(bpy.data.materials):
        bpy.data.materials.remove(mat)
    M.clear()
    material("concrete", (0.26, 0.25, 0.21), roughness=0.92)
    material("dark", (0.065, 0.075, 0.074), metal=0.65)
    material("deck", (0.15, 0.17, 0.155), metal=0.45, roughness=0.78)
    material("black", (0.012, 0.016, 0.017), roughness=0.8, wear=False)
    material("steel", (0.31, 0.34, 0.32), metal=1.0, roughness=0.29)
    material("olive", (0.23, 0.27, 0.22), metal=0.0, roughness=0.78)
    material("panel", (0.37, 0.4, 0.35), metal=0.0, roughness=0.72)
    material("porcelain", (0.48, 0.47, 0.40), metal=0.95, roughness=0.62)
    material("cast-iron", (0.115, 0.12, 0.105), metal=0.5, roughness=0.8)
    material("pipe-metal", (0.30, 0.235, 0.135), metal=0.65, roughness=0.74)
    material("copper", (0.4, 0.19, 0.07), metal=1.0, roughness=0.55)
    material("blue", (0.095, 0.19, 0.22), metal=0.0, roughness=0.78)
    material("ochre", (0.55, 0.32, 0.08), metal=0.3)
    material("amber", (0.8, 0.29, 0.035), wear=False, emission=True)
    material("cyan", (0.08, 0.55, 0.65), wear=False, emission=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 48
    scene.cycles.seed = 1729
    scene.cycles.use_denoising = True
    scene.render.threads_mode = "FIXED"
    scene.render.threads = threads
    scene.render.resolution_x = SIZE
    scene.render.resolution_y = SIZE
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.film_transparent = True
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "Medium High Contrast"
    scene.view_settings.exposure = 0
    world = bpy.data.worlds.new("Neutral ambient")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.64, 0.69, 0.76, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.45
    scene.world = world
    bpy.ops.object.camera_add(location=(0, -20, 20))
    camera = bpy.context.object
    camera.name = "Factorio orthographic camera"
    camera.rotation_euler = (
        (Vector((0, 0, 0)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    )
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = SIZE / PIXELS_PER_TILE
    scene.camera = camera
    bpy.ops.object.light_add(type="SUN", location=(-8, -5, 10))
    sun = bpy.context.object
    sun.name = "Factorio sun"
    sun.rotation_euler = Vector((0.8, 0.35, -1)).to_track_quat("-Z", "Y").to_euler()
    sun.data.energy = 2.1
    sun.data.angle = math.radians(5)
    return scene


def build(output, views=None, threads=12, frame=0, layer="base"):
    output.mkdir(parents=True, exist_ok=True)
    metadata = {
        "blender": bpy.app.version_string,
        "seed": 1729,
        "pixels_per_tile": PIXELS_PER_TILE,
        "canvas": SIZE,
        "origin": [SIZE / 2, SIZE / 2],
        "footprint": [5, 5],
        "projection": {"elevation_degrees": 45, "ground_y_scale": math.sqrt(2)},
        "models": {},
    }
    for name, builder in [
        ("radio-dish", lambda: dish(False)),
        ("pneumatic-radio-dish", lambda: dish(True)),
        ("correlator", correlator),
    ]:
        directions = (
            ("north",) if name == "correlator" else ("north", "east", "south", "west")
        )
        for angle, direction in enumerate(directions):
            variant = name if direction == "north" else name + "-" + direction
            if views and variant not in views:
                continue
            scene = scene_setup(threads)
            builder()
            motion = MOTIONS["correlator-fans" if name == "correlator" else "reflector"]
            if not 0 <= frame < motion["frames"]:
                raise ValueError("Motion frame outside animation")
            phase = frame / motion["frames"]
            head = bpy.data.objects.get("Reflector elevation pivot")
            if head:
                orientation = head.rotation_euler.to_quaternion()
                head.rotation_mode = "QUATERNION"
                head.rotation_quaternion = (
                    Quaternion(
                        (1, 0, 0),
                        math.radians(motion["tilt_degrees"])
                        * math.sin(math.tau * phase),
                    )
                    @ orientation
                )
            for obj in scene.objects:
                if obj.get("fan_rotor", False):
                    obj.rotation_euler.z = math.tau * phase / motion["blades"]
            model = [o for o in scene.objects if o.type in {"MESH", "CURVE"}]
            bpy.ops.object.empty_add()
            root = bpy.context.object
            root.name = "Tile projection correction"
            for obj in list(scene.objects):
                if (
                    obj != root
                    and obj.type not in {"CAMERA", "LIGHT"}
                    and obj.parent is None
                ):
                    obj.parent = root
            rotation = Matrix.Rotation(-angle * math.pi / 2, 4, "Z")
            root.matrix_world = Matrix.Diagonal((1, math.sqrt(2), 1, 1))
            for obj in model:
                if "inlet_facing" in obj or obj.get("rotate_with_ports", False):
                    obj.matrix_basis = rotation @ obj.matrix_basis
            bpy.context.view_layer.update()
            for obj in model:
                if "inlet_facing" in obj and (obj["inlet_facing"] + angle) % 2:
                    # Side mounting faces meet the native fitting at pipe height.
                    obj.matrix_world = (
                        Matrix.Translation((0, -0.47, 0)) @ obj.matrix_world
                    )
            head = bpy.data.objects.get("Reflector elevation pivot")
            if head:
                head.matrix_parent_inverse = Matrix.Diagonal(
                    (1, 1 / math.sqrt(2), 1, 1)
                )
            floor = box(
                "Ground bounce", (0, 0, -0.045), (200, 200, 0.05), "concrete", bevel=0
            )
            floor.visible_camera = False
            moving = {
                child
                for parent in scene.objects
                if parent.name == "Reflector elevation pivot"
                or parent.get("fan_rotor", False)
                for child in parent.children_recursive
            }
            static = [obj for obj in model if obj not in moving]
            if layer == "base":
                bpy.ops.wm.save_as_mainfile(filepath=str(output / (variant + ".blend")))
                for obj in moving:
                    obj.visible_camera = False
            else:
                for obj in static:
                    if "inlet_facing" in obj or obj.get("rotate_with_ports", False):
                        obj.hide_render = True
                    else:
                        obj.is_holdout = True
            scene.render.filepath = str(output / (variant + "-body.png"))
            bpy.ops.render.render(write_still=True)
            if layer == "base":
                floor.visible_camera = True
                floor.is_shadow_catcher = True
                for obj in model:
                    obj.visible_camera = False
                scene.render.filepath = str(output / (variant + "-shadow.png"))
                bpy.ops.render.render(write_still=True)
            if layer == "base":
                floor.visible_camera = False
                floor.is_shadow_catcher = False
                for obj in model:
                    obj.visible_camera = True
                    obj.hide_render = False
                for mat in M.values():
                    nodes = mat.node_tree.nodes
                    nodes.clear()
                    surface = nodes.new("ShaderNodeOutputMaterial")
                    emission = nodes.new("ShaderNodeEmission")
                    emission.inputs["Color"].default_value = (
                        *mat.get("glow_color", (0, 0, 0)),
                        1,
                    )
                    emission.inputs["Strength"].default_value = 1
                    mat.node_tree.links.new(
                        emission.outputs[0], surface.inputs["Surface"]
                    )
                scene.cycles.samples = 16
                scene.cycles.use_denoising = False
                scene.render.filepath = str(output / (variant + "-glow.png"))
                bpy.ops.render.render(write_still=True)
            metadata["models"][variant] = {
                "objects": len(model),
                "body": variant + "-body.png",
                "shadow": variant + "-shadow.png",
                "glow": variant + "-glow.png",
            }
    if views and set(views) != set(metadata["models"]):
        raise ValueError("Unknown requested render view")
    (output / "render.json").write_text(json.dumps(metadata, indent=2) + "\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--layer", choices=("base", "motion"), default="base")
    parser.add_argument("--frame", type=int, default=0)
    parser.add_argument("--threads", type=int, default=12)
    parser.add_argument(
        "--views", nargs="+", help="Render selected views for inspection"
    )
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1 :])
    if args.threads < 1:
        parser.error("--threads must be positive")
    build(args.output.resolve(), args.views, args.threads, args.frame, args.layer)
