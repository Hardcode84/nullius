# Vulcanus progression

## Level 1 — Player milestones

| ID | Milestone | Segment time | Cumulative time |
|---|---|---:|---:|
| M0 | Land, recover the wreck, and assess the starting area | 0–5 min | 0–5 min |
| M1 | Establish temporary pneumatic bootstrap | 5–10 min | 5–15 min |
| M2 | Make the pneumatic bootstrap self-sustaining | 5–10 min | 10–25 min |
| M3 | Establish the basic local material palette | 15–25 min | 25–50 min |
| M4 | Bring heat-dependent metallurgy and chemistry online | 15–25 min | 40–75 min |
| M5 | Produce the first bootstrap metallurgic science | 15–25 min | 55–100 min |
| M6 | Reproduce and expand the core factory from local production | 25–40 min | 75–130 min |
| M7 | Accumulate bootstrap metallurgic science | 30–60 min | 105–190 min |
| M8 | Replace rock-mined graphite with atmosphere and HCl chemistry | 30–45 min | 120–200 min |
| M9 | Produce geology, climatology, mechanical, and electrical science | 45–75 min | 165–275 min |
| M10 | Establish local sulfur, alkali, lubricant, and chemical-science production | 45–75 min | 210–350 min |
| M11 | Research and commission efficient hot-bloom metallurgic science | 30–45 min | 240–395 min |
| M12 | Commission direct hot casting and complete Thermal Engineering 1 | 45–75 min | 285–470 min |
| M13 | Start solar-heated crushing, smelting, and casting on Nauvis | 20–40 min | 305–510 min |
| M14 | Complete the first crushing, smelting, and casting optimization levels | 30–50 min | 335–560 min |
| M15 | Establish refractory infrastructure, pilot titanium, and deploy tier-2 industry | 2–4 h | 6–12 h |
| M16 | Unlock tier-3 thermal industry and supply it from nuclear heat | 4–8 h | 10–20 h |

Time basis: first solo playthrough after activation, no prepared layout.

## Level 2 — Scenario specifications

```yaml
format:
  scenario: [given, place, connect, act, run, expect]
  quantity: {exact: "=", minimum: ">=", maximum: "<=", absent: 0}
  place: {id: {prototype: string, count: integer, at: "[x,y] | auto", direction: direction}}
  auto-placement: topology-constrained
  connect: ["endpoint -> network", "network -> endpoint"]
  run: {ticks: integer, until: predicate, timeout: integer, checkpoints: [integer]}
  expect: {tick: {inventory: map, fluid: map, produced: map, consumed: map, entity: map}}

defaults:
  surface:
    planet: nullius-vulcanus
    map: fixed
    properties: {nullius-ambient-temperature: 200}
  force:
    researched: [nullius-pneumatic-technology]
  mods: {Companion_Drones: false}
  isolation: new-surface
  intermediates: recipe-only
  debug-inputs: declared-only
  scheduling: parallel

chunk_contract:
  execution: independent
  order: [activation, vent-prime, gas-self-power, lava-separation, bloom-cooldown, aluminum-reduction, sulfur-catalysis, metallurgic-pack-recipe, construction-closure, inorganic-barrel, metallurgic-pack-10, hcl-thermal-cracking, basic-science-10, chemical-acid-200, chemical-alkali-20, chemical-glass-lubricant, chemical-concrete-barrels, chemical-pack-10, efficient-metallurgic-research, efficient-metallurgic-science, hot-casting, thermal-engineering-1, thermal-cell-1, industrial-optimization-1, refractory-production, titanium-pilot, titanium-construction, thermal-cell-2, thermal-cell-3]
  supporting: [pneumatic-heat, pneumatic-compressor, pneumatic-heat-production, caustic-bootstrap]
  given: "subset of cumulative prior terminal state + declared raw/debug boundaries"
  expect: "exact local terminal state"
  cross_chunk_save: false

validators:
  construction: "python3 tools/analyze_factorio_prereqs.py @tests/progression/vulcanus-construction.args"
  inorganic-barrel: "python3 tools/analyze_factorio_prereqs.py @tests/progression/vulcanus-barrel.args"
  efficient-metallurgic-science: "python3 tools/analyze_factorio_prereqs.py @tests/progression/vulcanus-efficient-pack.args"
  hot-casting: "python3 tools/analyze_factorio_prereqs.py @tests/progression/vulcanus-hot-casting.args"
  refractory-production: "python3 tools/analyze_factorio_prereqs.py @tests/progression/vulcanus-refractory-production.args"
  titanium-pilot: "python3 tools/analyze_factorio_prereqs.py @tests/progression/vulcanus-titanium-pilot.args"
  titanium-construction: "python3 tools/analyze_factorio_prereqs.py @tests/progression/vulcanus-titanium-construction.args"
  metallurgic-pack: "python3 tools/analyze_factorio_prereqs.py @tests/progression/vulcanus-pack.args"
  renewable-graphite: "python3 tools/analyze_factorio_prereqs.py @tests/progression/vulcanus-renewable-graphite.args"
  basic-science: "python3 tools/analyze_factorio_prereqs.py @tests/progression/vulcanus-basic-science.args"
  chemical-science: "python3 tools/analyze_factorio_prereqs.py @tests/progression/vulcanus-chemical-science.args"
  chemical-acid: "python3 tools/analyze_factorio_prereqs.py @tests/progression/vulcanus-chemical-acid.args"
  chemical-alkali: "python3 tools/analyze_factorio_prereqs.py @tests/progression/vulcanus-chemical-alkali.args"
  chemical-glass-lubricant: "python3 tools/analyze_factorio_prereqs.py @tests/progression/vulcanus-chemical-glass-lubricant.args"
  chemical-concrete-barrels: "python3 tools/analyze_factorio_prereqs.py @tests/progression/vulcanus-chemical-concrete-barrels.args"
  chemical-pack: "python3 tools/analyze_factorio_prereqs.py @tests/progression/vulcanus-chemical-pack.args"
  thermal-furnace-sizes: "python3 tools/analyze_factorio_prereqs.py @tests/progression/nauvis-thermal-furnace-sizes.args"

prototypes:
  technologies:
    nullius-efficient-metallurgic-science:
      prerequisites: [nullius-pneumatic-technology]
      unit: {count: 5, time: 30, ingredients: {nullius-metallurgic-pack: 2, nullius-geology-pack: 2, nullius-mechanical-pack: 1, nullius-electrical-pack: 1}}
      totals: {nullius-metallurgic-pack: 10, nullius-geology-pack: 10, nullius-mechanical-pack: 5, nullius-electrical-pack: 5}
      unlocks: [nullius-metallurgic-pack-efficient, nullius-chlorine-barrel, nullius-sulfur-dioxide-barrel]
    nullius-hot-metalworking:
      prerequisites: [nullius-efficient-metallurgic-science, nullius-aluminum-working-1]
      unit: {count: 10, time: 30, ingredients: {nullius-metallurgic-pack: 10, nullius-mechanical-pack: 1}}
      totals: {nullius-metallurgic-pack: 100, nullius-mechanical-pack: 10}
      unlocks: [nullius-hot-iron-plate, nullius-hot-iron-rod, nullius-hot-aluminum-sheet, nullius-hot-aluminum-rod]
    nullius-vulcanus-refractory-engineering:
      prerequisites: [nullius-hot-metalworking, nullius-ceramics, nullius-thermal-storage-2]
      unit: {count: 10, time: 45, ingredients: {nullius-metallurgic-pack: 40, nullius-geology-pack: 4, nullius-chemical-pack: 4}}
      totals: {nullius-metallurgic-pack: 400, nullius-geology-pack: 40, nullius-chemical-pack: 40}
      unlocks: [nullius-refractory-mix-vulcanus, nullius-refractory-brick-vulcanus, nullius-heat-pipe-2-vulcanus, nullius-vulcanus-radiator-2-refractory]
    nullius-volcanic-titanium-metallurgy:
      prerequisites: [nullius-vulcanus-refractory-engineering, nullius-titanium-production-2, nullius-water-filtration-3, nullius-metalworking-2]
      unit: {count: 10, time: 60, ingredients: {nullius-metallurgic-pack: 80, nullius-geology-pack: 8, nullius-chemical-pack: 8}}
      totals: {nullius-metallurgic-pack: 800, nullius-geology-pack: 80, nullius-chemical-pack: 80}
      unlocks: [nullius-titanium-ingot-vulcanus, nullius-aluminum-chloride-recovery, nullius-hydro-plant-2-vulcanus, nullius-foundry-2-vulcanus]
    nullius-thermal-engineering-1:
      prerequisites: [nullius-efficient-metallurgic-science, nullius-mineral-processing-1, nullius-metallurgy-1, nullius-metalworking-1, nullius-boiling-1, nullius-solar-thermal-power-1]
      unit: {count: 5, time: 30, ingredients: {nullius-metallurgic-pack: 40, nullius-geology-pack: 2, nullius-mechanical-pack: 1}}
      totals: {nullius-metallurgic-pack: 200, nullius-geology-pack: 10, nullius-mechanical-pack: 5}
      unlocks: [nullius-crusher-1-thermal, nullius-small-furnace-1-thermal, nullius-medium-furnace-1-thermal, nullius-large-furnace-1-thermal, nullius-foundry-1-thermal]
    nullius-thermal-engineering-2:
      prerequisites: [nullius-thermal-engineering-1, nullius-mineral-processing-2, nullius-metallurgy-2, nullius-metalworking-2, nullius-thermal-storage-2, nullius-solar-thermal-power-2]
      unit: {count: 10, time: 45, ingredients: {nullius-metallurgic-pack: 80, nullius-geology-pack: 8, nullius-mechanical-pack: 4, nullius-electrical-pack: 4, nullius-chemical-pack: 4}}
      totals: {nullius-metallurgic-pack: 800, nullius-geology-pack: 80, nullius-mechanical-pack: 40, nullius-electrical-pack: 40, nullius-chemical-pack: 40}
      unlocks: [nullius-crusher-2-thermal, nullius-small-furnace-2-thermal, nullius-medium-furnace-2-thermal, nullius-large-furnace-2-thermal, nullius-foundry-2-thermal]
    nullius-thermal-engineering-3:
      prerequisites: [nullius-thermal-engineering-2, nullius-mineral-processing-3, nullius-metallurgy-3, nullius-metalworking-4, nullius-thermal-storage-3, nullius-nuclear-power-1]
      unit: {count: 20, time: 60, ingredients: {nullius-metallurgic-pack: 160, nullius-geology-pack: 16, nullius-climatology-pack: 8, nullius-mechanical-pack: 8, nullius-electrical-pack: 8, nullius-chemical-pack: 16}}
      totals: {nullius-metallurgic-pack: 3200, nullius-geology-pack: 320, nullius-climatology-pack: 160, nullius-mechanical-pack: 160, nullius-electrical-pack: 160, nullius-chemical-pack: 320}
      unlocks: [nullius-crusher-3-thermal, nullius-small-furnace-3-thermal, nullius-medium-furnace-3-thermal, nullius-foundry-3-thermal]
    repeatable:
      common: {max_level: infinite, count_formula: "100*L^2", time: 30, ingredients: {nullius-metallurgic-pack: 1}, change_per_level: 0.01}
      branches:
        nullius-crushing-productivity-1: {prerequisites: [nullius-thermal-engineering-1, nullius-mineral-processing-1], categories: [ore-crushing]}
        nullius-smelting-productivity-1: {prerequisites: [nullius-thermal-engineering-1, nullius-metallurgy-1], categories: [dry-smelting]}
        nullius-casting-productivity-1: {prerequisites: [nullius-thermal-engineering-1, nullius-metalworking-1], categories: [machine-casting]}
      recipe_selector: {category_or_additional_category: branch.categories, exclude: {maximum_productivity: 0}}
  entities:
    common:
      source: corresponding_electric_entity
      placeable_by: corresponding_base_item
      minable_result: corresponding_base_item
      energy_source: heat
      crafting_speed: unchanged
      module_slots: unchanged
      allowed_effects: unchanged
      crafting_categories: unchanged
    tiers:
      1: {entities: [nullius-crusher-1-thermal, nullius-small-furnace-1-thermal, nullius-medium-furnace-1-thermal, nullius-large-furnace-1-thermal, nullius-foundry-1-thermal], base_productivity: 0.05, min_temperature: 100, max_temperature: 250, distribution: nullius-heat-pipe-1, source: nullius-solar-collector-1}
      2: {entities: [nullius-crusher-2-thermal, nullius-small-furnace-2-thermal, nullius-medium-furnace-2-thermal, nullius-large-furnace-2-thermal, nullius-foundry-2-thermal], base_productivity: 0.10, min_temperature: 200, max_temperature: 500, distribution: nullius-heat-pipe-2, source: nullius-solar-collector-2}
      3: {entities: [nullius-crusher-3-thermal, nullius-small-furnace-3-thermal, nullius-medium-furnace-3-thermal, nullius-foundry-3-thermal], base_productivity: 0.15, min_temperature: 500, max_temperature: 1500, distribution: nullius-heat-pipe-3, source: nullius-reactor}
  transitions:
    nauvis: {before: electric, after: thermal, input: Ctrl+R, requires: [corresponding_nullius_thermal_engineering_tier, base_building_recipe_enabled]}
    nullius-vulcanus: {before: electric, after: pneumatic, input: Ctrl+R, unchanged: true}
    other_surfaces: {transition: none}

scenarios:
  activation:
    milestone: M0
    given:
      surface: nauvis
      force:
        completed: [nullius-probe-vulcanus]
        researched: [nullius-pneumatic-technology]
    act:
      - event: on_research_finished
        technology: nullius-probe-vulcanus
    expect:
      terminal:
        planet_surface: {nullius-vulcanus: "=1"}
        character:
          prototype: character
          count: "=1"
        force:
          unlocked_space_locations: [nullius-vulcanus]
        entities:
          nullius-landing-main: "=1"
        wreck_inventory:
          nullius-seawater-intake-1: "=2"
          nullius-hydro-plant-1: "=4"
          nullius-small-furnace-1: "=4"
          pipe: "=50"
          nullius-heat-pipe-1: "=30"
          pipe-to-ground: "=10"
          nullius-extractor-1: "=2"
          nullius-air-filter-1: "=2"
          nullius-distillery-1: "=2"
          nullius-chemical-plant-1: "=2"
          nullius-foundry-1: "=4"
          nullius-small-assembler-1: "=4"
          inserter: "=12"
          iron-chest: "=4"
          nullius-lab-1: "=1"
          transport-belt: "=50"
          splitter: "=4"
          cliff-explosives: "=30"
        android:
          armor: {nullius-chassis-1: "=1"}
          equipment:
            nullius-charger-1: "=1"
            nullius-hangar-1: "=1"
            nullius-solar-panel-1: "=2"
            nullius-battery-1: "=4"
          inventory: {nullius-construction-bot-1: "=6"}

  vent-prime:
    milestone: M1
    given:
      inventory: {nullius-seawater-intake-1: "=1"}
      fluids: {nullius-compressed-volcanic-gas: 0}
    place:
      vent: {prototype: nullius-seawater-intake-1, at: [0, 0]}
      gas-buffer: {prototype: storage-tank, at: auto}
    connect:
      - vent.output -> gas
      - gas -> gas-buffer.input
    act:
      - build: vent
      - rotate_mode: {entity: vent, mode: free-gas}
    run: {ticks: 120}
    expect:
      120:
        fluid: {gas: {nullius-compressed-volcanic-gas: ">=24"}}
        owned_hidden_drill: {vent: "=1"}
        owned_hidden_resource: {vent: "=1"}
      after_destroy:
        entity: {vent: 0}
        owned_hidden_drill: {vent: 0}
        owned_hidden_resource: {vent: 0}

  gas-self-power:
    milestone: M2
    given:
      fluids:
        lava: "=100"
        nullius-compressed-volcanic-gas: "=24"
    place:
      hydro: {prototype: nullius-hydro-plant-1-pneumatic, at: [0, 0]}
      gas-buffer: {prototype: storage-tank, at: auto}
      stone-sink: {prototype: infinity-chest, at: auto}
      stone-inserter: {prototype: inserter, at: auto}
      debug-power: {prototype: electric-energy-interface, at: auto}
      power-pole: {prototype: small-electric-pole, at: auto}
    connect:
      - lava -> hydro.fluid_input
      - gas-buffer <-> gas
      - gas -> hydro.energy_input
      - hydro.fluid_output -> gas
      - hydro.item_output -> stone-sink
      - debug-power -> power-pole -> stone-inserter
    act:
      - set_recipe: {entity: hydro, recipe: nullius-lava-gas-extraction}
    run: {ticks: 245}
    expect:
      terminal:
        produced: {nullius-compressed-volcanic-gas: "=120", stone: "=6"}
        consumed: {lava: "=100", nullius-compressed-volcanic-gas: "<=48.1"}
        fluid: {gas: {nullius-compressed-volcanic-gas: ">=95.9"}}
        connected_vent: 0

  lava-separation:
    milestone: M3
    matrix:
      - id: iron
        recipe: nullius-lava-iron-separation
        recipe_ticks: 300
        ticks: 380
        input: {lava: 100, nullius-compressed-volcanic-gas: 60}
        output: {nullius-molten-iron-bloom: 4, nullius-compressed-volcanic-gas: 30, stone: 10}
        gas_terminal: 30
      - id: aluminum
        recipe: nullius-lava-aluminum-separation
        recipe_ticks: 300
        ticks: 380
        input: {lava: 100, nullius-compressed-volcanic-gas: 60}
        output: {nullius-molten-aluminum-bloom: 3, nullius-compressed-volcanic-gas: 25, stone: 8}
        gas_terminal: 25
      - id: calcite
        recipe: nullius-lava-calcite-separation
        recipe_ticks: 240
        ticks: 313
        input: {lava: 80, nullius-compressed-volcanic-gas: 48}
        output: {nullius-crushed-limestone: 6, nullius-compressed-volcanic-gas: 20}
        gas_terminal: 20
      - id: silica
        recipe: nullius-lava-silica-extraction
        recipe_ticks: 180
        ticks: 244
        input: {lava: 60, nullius-compressed-volcanic-gas: 36}
        output: {nullius-silica: 8, stone: 5, nullius-compressed-volcanic-gas: 15, nullius-sulfur-dioxide: 10}
        gas_terminal: 15
    place:
      hydro: {prototype: nullius-hydro-plant-1-pneumatic, at: [0, 0]}
      gas-buffer: {prototype: storage-tank, at: auto}
      fluid-output: {prototype: storage-tank, at: auto}
      item-output: {prototype: infinity-chest, at: auto}
      item-inserter: {prototype: inserter, at: auto}
      debug-power: {prototype: electric-energy-interface, at: auto}
      power-pole: {prototype: small-electric-pole, at: auto}
    connect:
      - matrix.input.lava -> hydro.fluid_input
      - matrix.input.nullius-compressed-volcanic-gas -> gas
      - gas-buffer <-> gas
      - gas -> hydro.energy_input
      - hydro.gas_output -> gas
      - hydro.fluid_output -> fluid-output
      - hydro.item_output -> item-output
      - debug-power -> power-pole -> item-inserter
    act:
      - set_recipe: {entity: hydro, recipe: matrix.recipe}
    run: {ticks: matrix.ticks}
    expect:
      terminal:
        produced: "=matrix.output"
        input_remaining: 0
        gas: "=matrix.gas_terminal"
      before_terminal:
        tick: matrix.recipe_ticks
        produced: 0

  bloom-cooldown:
    milestone: M3
    matrix:
      - {id: iron, input: {nullius-molten-iron-bloom: 4}, spoil_ticks: 1800, ticks: 1801, output: {nullius-iron-ingot: 4}}
      - {id: aluminum, input: {nullius-molten-aluminum-bloom: 3}, spoil_ticks: 2400, ticks: 2401, output: {nullius-alumina: 3}}
    given: {inventory: "=matrix.input"}
    place:
      cooldown-inventory: {prototype: iron-chest, at: auto}
    run: {ticks: matrix.ticks}
    expect:
      before_terminal:
        tick: matrix.spoil_ticks
        inventory: "=matrix.input"
      terminal: {inventory: "=matrix.output", input_remaining: 0}

  aluminum-reduction:
    milestone: M4
    given:
      force:
        researched: [nullius-pneumatic-technology]
        closure_contains: [nullius-aluminum-production]
      inventory: {nullius-alumina: 9, nullius-graphite: 5}
      heat: {temperature: ">=100", available_energy_j: ">=2760000"}
    place:
      furnace: {prototype: nullius-small-furnace-1-pneumatic, at: [20, 0]}
      heat-pipe: {prototype: nullius-heat-pipe-1, at: runtime-heat-connection}
    connect: [heat-pipe -> furnace]
    act:
      - set_recipe: {entity: furnace, recipe: nullius-aluminum-ingot}
    run: {recipe_ticks: 600, crafting_speed: 0.25, ticks: 2402}
    expect:
      before_terminal:
        tick: 2400
        produced: 0
      terminal:
        produced: {nullius-aluminum-ingot: "=3", nullius-aluminum-carbide: "=4"}
        consumed: {nullius-alumina: "=9", nullius-graphite: "=5"}

  sulfur-catalysis:
    milestone: M4
    given:
      force: {researched: [nullius-pneumatic-technology]}
      fluids: {nullius-sulfur-dioxide: 40}
      inventory: {nullius-rutile: 1}
      heat: {temperature: ">=200", available_energy_j: ">=4000000"}
    place:
      radiator: {prototype: nullius-vulcanus-radiator-1, at: [20, 0]}
      heat-pipe: {prototype: nullius-heat-pipe-1, at: runtime-heat-connection}
      input-pipe: {prototype: pipe, at: runtime-fluid-input}
      output-pipe: {prototype: pipe, at: runtime-fluid-output}
    connect:
      - heat-pipe -> radiator
      - input-pipe -> radiator.fluid_input
      - radiator.fluid_output -> output-pipe
    act:
      - set_recipe: {entity: radiator, recipe: nullius-so2-catalytic-decomposition}
    run: {recipe_ticks: 240, crafting_speed: 1, ticks: 242}
    expect:
      before_terminal: {tick: 240, produced: 0}
      terminal:
        produced: {nullius-oxygen: "=40", sulfur: "=1", nullius-rutile: "=1"}
        consumed: {nullius-sulfur-dioxide: "=40"}
        inventory: {nullius-rutile: "=1"}

  pneumatic-heat:
    milestone: M4
    given:
      fluids:
        lava: infinite
        nullius-compressed-volcanic-gas: 96
        nullius-sulfur-dioxide: 40
      inventory:
        nullius-alumina: 9
        nullius-graphite: 5
        nullius-rutile: 1
      heat: {temperature: engine-default, debug_source: 0}
    place:
      hydro: {prototype: nullius-hydro-plant-1-pneumatic, count: 4, at: auto}
      gas-buffer: {prototype: storage-tank, count: 4, at: auto}
      heat-pipe: {prototype: nullius-heat-pipe-1, available: 30, at: auto}
      furnace: {prototype: nullius-small-furnace-1-pneumatic, count: 1, at: auto}
      radiator: {prototype: nullius-vulcanus-radiator-1, count: 1, at: auto}
      stone-sink: {prototype: steel-chest, count: 4, at: auto}
      stone-inserter: {prototype: inserter, count: 4, at: auto}
      debug-power: {prototype: electric-energy-interface, count: 4, at: auto}
      power-distribution: {prototype: small-electric-pole, count: 4, at: auto}
    connect:
      - lava -> hydro[*].fluid_input
      - gas <-> hydro[*].energy_input
      - hydro[*].fluid_output -> gas
      - gas -> gas-buffer[*]
      - hydro[*].item_output -> stone-sink
      - debug-power -> power-distribution -> stone-inserter[*]
      - hydro[*].owned_heat_interface -> heat-pipe
      - heat-pipe -> furnace
      - heat-pipe -> radiator
    act:
      - set_recipe: {entity: "hydro[*]", recipe: nullius-lava-gas-extraction}
      - set_recipe: {entity: furnace, recipe: nullius-aluminum-ingot}
      - set_recipe: {entity: radiator, recipe: nullius-so2-catalytic-decomposition}
    run: {ticks: 65000}
    expect:
      terminal:
        temperature: {furnace: ">=100", radiator: ">=200"}
        produced:
          nullius-aluminum-ingot: "=3"
          nullius-aluminum-carbide: "=4"
          nullius-oxygen: "=40"
          sulfur: "=1"
          nullius-rutile: "=1"
        heat_sources: {owned_pneumatic_interfaces: "=4", debug: 0, preheated: 0}
        heat_pipes_placed: "<=30"

  metallurgic-pack-recipe:
    milestone: M5
    validator: metallurgic-pack
    given:
      inventory:
        nullius-iron-ingot: 12
        nullius-aluminum-ingot: 8
        nullius-crushed-limestone: 4
        nullius-silica: 4
        sulfur: 4
      fluids: {nullius-compressed-volcanic-gas: 354}
    place:
      assembler: {prototype: nullius-small-assembler-1-pneumatic, at: [0, 0]}
    connect: [gas -> assembler.energy_input]
    act:
      - set_recipe: {entity: assembler, recipe: nullius-metallurgic-pack}
    run: {recipe_ticks: 3600, crafting_speed: 0.5, ticks: 7202}
    expect:
      before_terminal: {tick: 7200, produced: 0}
      terminal:
        produced: {nullius-metallurgic-pack: "=1"}
        input_remaining: 0
        fluid: {gas: 0}

  construction-closure:
    milestone: M6
    validator: construction
    given:
      fixture: activation.wreck_inventory
      debug_parallel_fixture: {nullius-seawater-intake-1: 6, nullius-hydro-plant-1: 4, nullius-small-furnace-1: 4, nullius-extractor-1: 6, nullius-air-filter-1: 6, nullius-distillery-1: 6, nullius-chemical-plant-1: 6, nullius-foundry-1: 4, nullius-small-assembler-1: 4}
      stock: {nullius-compressed-volcanic-gas: 24}
      mined_input: {nullius-graphite: 128, nullius-limestone: 100, nullius-rutile: 1}
      lava: nullius-lava-pumping
      injected_intermediates: 0
      heat: {mode: scripted-preheat-per-cycle, heat_pipe_temperature: 250, pneumatic_heat_temperature: 500}
    act:
      - execute_manifest: construction
    run: {until: targets_complete, ticks: 264062, timeout: 270000, parallel_executors: 8}
    expect:
      terminal:
        produced:
          nullius-seawater-intake-1: "=7"
          nullius-hydro-plant-1: "=6"
          nullius-air-filter-1: "=1"
          nullius-chemical-plant-1: "=1"
          nullius-distillery-1: "=4"
          nullius-small-furnace-1: "=6"
          nullius-foundry-1: "=1"
          nullius-small-assembler-1: "=4"
          nullius-medium-assembler-1: "=1"
          nullius-vulcanus-radiator-1: "=1"
          transport-belt: "=60"
          inserter: "=20"
          pipe: "=165"
          pipe-to-ground: "=18"
          storage-tank: "=7"
          wooden-chest: "=8"
          nullius-heat-pipe-1: "=30"
        selected_steps: "=47"
        additional_research: 0
        fuel_consumed: {nullius-compressed-volcanic-gas: "=24233.4"}
        surplus:
          inserter: 2
          lava: 100
          nullius-aluminum-carbide: 88
          nullius-aluminum-ingot: 2
          nullius-carbon-dioxide: 70
          nullius-compressed-volcanic-gas: 30.6
          nullius-crushed-limestone: 25
          nullius-gravel: 43
          nullius-hydro-plant-1: 1
          nullius-iron-gear: 1
          nullius-iron-rod: 4
          nullius-iron-sheet: 4
          nullius-rutile: 1
          nullius-silica: 308
          nullius-steel-beam: 1
          nullius-steel-ingot: 1
          pipe: 3
          pipe-to-ground: 1
          stone: 2635
          sulfur: 15
          transport-belt: 6

  inorganic-barrel:
    milestone: M6
    validator: inorganic-barrel
    given:
      inventory:
        nullius-steel-sheet: 2
        nullius-aluminum-sheet: 2
        nullius-glass: 1
        nullius-one-way-valve: 1
      fluids: {nullius-compressed-volcanic-gas: 59}
    place:
      assembler: {prototype: nullius-small-assembler-1-pneumatic, at: [0, 0]}
    connect: [gas -> assembler.energy_input]
    act:
      - set_recipe: {entity: assembler, recipe: nullius-vulcanus-barrel}
    run: {recipe_ticks: 600, crafting_speed: 0.5, ticks: 1202}
    expect:
      terminal:
        produced: {barrel: "=3"}
        input_remaining: 0
        organic_inputs: 0

  metallurgic-pack-10:
    milestone: M7
    validator: metallurgic-pack
    given:
      prior_stage: construction-closure
      fixture:
        nullius-seawater-intake-1: 1
        nullius-hydro-plant-1: 4
        nullius-small-furnace-1: 1
        nullius-small-assembler-1: 1
        nullius-vulcanus-radiator-1: 1
        nullius-heat-pipe-1: 30
      debug_parallel_fixture: {nullius-seawater-intake-1: 7, nullius-hydro-plant-1: 12, nullius-small-furnace-1: 15, nullius-small-assembler-1: 15, nullius-vulcanus-radiator-1: 15}
      stock: {nullius-compressed-volcanic-gas: 24}
      mined_input: {nullius-graphite: 135, nullius-rutile: 1}
      lava: nullius-lava-pumping
      injected_intermediates: 0
      heat: {mode: scripted-preheat-per-cycle, heat_pipe_temperature: 250, pneumatic_heat_temperature: 500}
    act:
      - execute_manifest: metallurgic-pack
    run: {until: targets_complete, ticks: 212788, timeout: 220000, parallel_executors: 16}
    expect:
      terminal:
        produced: {nullius-metallurgic-pack: "=10"}
        selected_steps: "=11"
        consumed:
          nullius-iron-ingot: 120
          nullius-aluminum-ingot: 80
          nullius-crushed-limestone: 40
          nullius-silica: 40
          sulfur: 40
          nullius-compressed-volcanic-gas: 23520
        surplus:
          lava: 65
          nullius-aluminum-carbide: 108
          nullius-aluminum-ingot: 1
          nullius-compressed-volcanic-gas: 29
          nullius-crushed-limestone: 2
          nullius-oxygen: 1600
          nullius-rutile: 1
          nullius-silica: 1240
          stone: 2651
        cycles:
          nullius-metallurgic-pack: 10
          nullius-aluminum-ingot: 27
          nullius-so2-catalytic-decomposition: 40
          nullius-lava-iron-separation: 30
          nullius-lava-aluminum-separation: 81
          nullius-lava-calcite-separation: 7
          nullius-lava-silica-extraction: 160
          nullius-lava-gas-extraction: 301
          nullius-lava-pumping: 291
        spoil_ticks:
          nullius-molten-iron-bloom: 1800
          nullius-molten-aluminum-bloom: 2400

  hcl-thermal-cracking:
    milestone: M8
    given:
      force: {researched: [nullius-pneumatic-technology]}
      fluids:
        lava: infinite
        nullius-compressed-volcanic-gas: 24
        nullius-hydrogen-chloride: 60
    place:
      heat-producer: {prototype: nullius-hydro-plant-1-pneumatic, at: [32, 0]}
      radiator: {prototype: nullius-vulcanus-radiator-2, at: [37, 0]}
      lava-source: {prototype: infinity-pipe, at: auto}
      gas-sink: {prototype: infinity-pipe, at: auto}
      stone-sink: {prototype: infinity-chest, at: auto}
    connect:
      - heat-producer.owned_heat_interface -> radiator
    act:
      - set_recipe: {entity: heat-producer, recipe: nullius-lava-gas-extraction}
      - set_recipe: {entity: radiator, recipe: nullius-vulcanus-cracking}
    run: {warmup_ticks: 80000, recipe_ticks: 120, ticks: 80122}
    expect:
      before_terminal:
        tick: 80120
        produced: 0
      terminal:
        produced:
          nullius-hydrogen: "=30"
          nullius-chlorine: "=30"
        consumed: {nullius-hydrogen-chloride: "=60"}
        temperature:
          heat-producer-interface: ">=450"
          radiator: ">=450"
        direct_heat_connection: true
        entity:
          nullius-heat-pipe-1: 0
          nullius-heat-pipe-2: 0

  basic-science-10:
    milestone: M9
    validator: basic-science
    given:
      prior_stage: hcl-thermal-cracking
      fixture:
        nullius-seawater-intake-1: 1
        nullius-hydro-plant-1: 4
        nullius-air-filter-1: 1
        nullius-distillery-1: 1
        nullius-chemical-plant-1: 1
        nullius-foundry-1: 1
        nullius-small-furnace-1: 1
        nullius-small-assembler-1: 1
        nullius-medium-assembler-1: 1
        nullius-vulcanus-radiator-1: 1
        nullius-vulcanus-radiator-2: 1
        nullius-heat-pipe-1: 30
      debug_parallel_fixture: {nullius-seawater-intake-1: 7, nullius-hydro-plant-1: 4, nullius-air-filter-1: 7, nullius-distillery-1: 7, nullius-chemical-plant-1: 7, nullius-foundry-1: 7, nullius-small-furnace-1: 7, nullius-small-assembler-1: 7, nullius-medium-assembler-1: 7}
      stock: {nullius-compressed-volcanic-gas: 24}
      raw:
        nullius-hydrogen-chloride: 27975
        nullius-limestone: 124
        nullius-rutile: 1
      forbidden: [seawater-pumping]
      injected_intermediates: 0
    place:
      direct-heat-producer: {prototype: nullius-hydro-plant-1-pneumatic, at: [36, -4]}
      high-temperature-radiator: {prototype: nullius-vulcanus-radiator-2, at: [41, -4]}
    connect: [direct-heat-producer.owned_heat_interface -> high-temperature-radiator]
    act:
      - execute_manifest: basic-science
    run: {until: targets_complete, ticks: 276436, timeout: 280000, parallel_executors: 8}
    expect:
      terminal:
        produced:
          nullius-geology-pack: "=10"
          nullius-climatology-pack: "=10"
          nullius-mechanical-pack: "=10"
          nullius-electrical-pack: "=10"
        reserve:
          nullius-compressed-volcanic-gas: "=9417.65"
          nullius-hydrogen-chloride: "=15"
        selected_steps: "=46"
        fuel_consumed: {nullius-compressed-volcanic-gas: "=41236.35"}
        cycles:
          nullius-lava-pumping: 400
          nullius-lava-gas-extraction: 800
          nullius-vulcanus-cracking: 466
        heat:
          radiator_temperature: ">=450"
          direct_connection: true
          nullius-heat-pipe-2: 0
        seawater: 0

  chemical-acid-200:
    milestone: M10
    validator: chemical-acid
    given:
      stock: {nullius-compressed-volcanic-gas: 30}
      raw: {nullius-hydrogen-chloride: 360, nullius-rutile: 1}
      forbidden: [seawater-pumping, electricity]
      executors: {nullius-lava-pumping: nullius-lava-intake-1, nullius-water-treatment: nullius-hydro-plant-1-pneumatic, basic-chemistry: nullius-chemical-plant-1-pneumatic, nullius-low-temp-radiator: nullius-vulcanus-radiator-1}
    run: {until: targets_complete, ticks: 4778, timeout: 10000, parallel_executors: 8}
    expect: {produced: {nullius-acid-sulfuric: "=200"}, additional_technologies: 0, electric_paths: 0}

  chemical-alkali-20:
    milestone: M10
    validator: chemical-alkali
    given:
      stock: {nullius-carbon-dioxide: 800, nullius-compressed-hydrogen: 80, nullius-compressed-nitrogen: 30, nullius-compressed-volcanic-gas: 6658.4, nullius-gravel: 180, nullius-lime: 10, nullius-water: 1900}
      raw: {nullius-hydrogen-chloride: 765}
      forbidden: [electricity]
      executors: {basic-chemistry: nullius-chemical-plant-1-pneumatic, distillation: nullius-distillery-1-pneumatic, nullius-water-treatment: nullius-hydro-plant-1-pneumatic}
    run: {until: targets_complete, ticks: 11694, timeout: 13000, parallel_executors: 10}
    expect: {produced: {nullius-sodium-hydroxide: "=20"}, additional_technologies: 0, electric_paths: 0}

  chemical-glass-lubricant:
    milestone: M10
    validator: chemical-glass-lubricant
    given:
      stock: {nullius-silica: 100, nullius-graphite: 19, nullius-hydrogen-chloride: 250, nullius-compressed-volcanic-gas: 7038}
      forbidden: [electricity]
      executors: {machine-casting: nullius-foundry-1-pneumatic, dry-smelting: nullius-medium-furnace-1-pneumatic, basic-chemistry: nullius-chemical-plant-1-pneumatic}
    run: {until: targets_complete, ticks: 9128, timeout: 10000, parallel_executors: 10}
    expect: {produced: {nullius-glass: "=30", nullius-lubricant: "=40"}, additional_technologies: 0, electric_paths: 0}

  chemical-concrete-barrels:
    milestone: M10
    validator: chemical-concrete-barrels
    given:
      stock: {barrel: 10, nullius-ammonia: 500, nullius-cement: 10, nullius-compressed-volcanic-gas: 775, nullius-gravel: 40, nullius-sand: 20, nullius-water: 60}
      forbidden: [electricity]
      executors: {ore-flotation: nullius-flotation-cell-1-pneumatic, nullius-barrel: nullius-barrel-pump-1-pneumatic}
    act: [transition nullius-flotation-cell-1 -> nullius-flotation-cell-1-pneumatic, execute_manifest]
    run: {until: targets_complete, ticks: 499, timeout: 1500, parallel_executors: 10}
    expect: {produced: {concrete: "=50", nullius-ammonia-barrel: "=10"}, additional_technologies: 0, electric_paths: 0}

  chemical-pack-10:
    milestone: M10
    validator: chemical-pack
    given:
      stock: {concrete: 50, nullius-acid-sulfuric: 200, nullius-ammonia-barrel: 10, nullius-glass: 30, nullius-lubricant: 40, nullius-sodium-hydroxide: 20, nullius-compressed-volcanic-gas: 1440}
      forbidden: [electricity]
      executors: {basic-chemistry: nullius-chemical-plant-1-pneumatic}
    run: {until: targets_complete, ticks: 902, timeout: 1500, parallel_executors: 10}
    expect: {produced: {nullius-chemical-pack: "=10"}, additional_technologies: 0, electric_paths: 0}

  efficient-metallurgic-research:
    milestone: M11
    given:
      inventory: {nullius-metallurgic-pack: 10, nullius-geology-pack: 10, nullius-mechanical-pack: 5, nullius-electrical-pack: 5}
      fluids: {nullius-compressed-volcanic-gas: 712.5}
    place:
      lab: {prototype: nullius-lab-1-pneumatic, at: [0, 0]}
    connect: [gas -> lab.energy_input]
    act:
      - set_research: nullius-efficient-metallurgic-science
      - insert_research_inputs: lab
    run: {unit_count: 5, unit_time: 30, researching_speed: 1, ticks: 9002}
    expect:
      terminal:
        force: {researched: [nullius-efficient-metallurgic-science]}
        unlocked: [nullius-metallurgic-pack-efficient, nullius-chlorine-barrel, nullius-sulfur-dioxide-barrel]
        consumed: {nullius-metallurgic-pack: 10, nullius-geology-pack: 10, nullius-mechanical-pack: 5, nullius-electrical-pack: 5, nullius-compressed-volcanic-gas: 712.5}

  efficient-metallurgic-science:
    milestone: M11
    validator: efficient-metallurgic-science
    given:
      force: {researched: [nullius-efficient-metallurgic-science]}
      inventory:
        barrel: 2
        nullius-molten-iron-bloom: 2
        nullius-molten-aluminum-bloom: 2
        nullius-crucible: 1
      fluids:
        nullius-chlorine: 50
        nullius-sulfur-dioxide: 50
        nullius-compressed-volcanic-gas: 108.6
    place:
      chlorine-pump: {prototype: nullius-barrel-pump-1-pneumatic, at: [10, -4]}
      sulfur-dioxide-pump: {prototype: nullius-barrel-pump-1-pneumatic, at: [10, 4]}
      assembler: {prototype: nullius-medium-assembler-1-pneumatic, at: [20, 0]}
    connect:
      - gas -> chlorine-pump.energy_input
      - gas -> sulfur-dioxide-pump.energy_input
      - gas -> assembler.energy_input
    act:
      - set_recipe: {entity: chlorine-pump, recipe: nullius-chlorine-barrel}
      - set_recipe: {entity: sulfur-dioxide-pump, recipe: nullius-sulfur-dioxide-barrel}
      - transfer: {from: chlorine-pump, to: assembler, item: nullius-chlorine-barrel}
      - transfer: {from: sulfur-dioxide-pump, to: assembler, item: nullius-sulfur-dioxide-barrel}
      - set_recipe: {entity: assembler, recipe: nullius-metallurgic-pack-efficient}
    run: {barreling_ticks: 15, recipe_ticks: 900, timeout: 1000}
    expect:
      terminal:
        produced: {nullius-metallurgic-pack: "=5", barrel: "1..2"}
        expected_barrels: 1.9
        barrel_productivity_eligible: false
        pack_productivity_eligible: true
        input_remaining: 0
        spoiled: {nullius-iron-ingot: 0, nullius-alumina: 0}

  hot-casting:
    milestone: M12
    validator: hot-casting
    given:
      force: {researched: [nullius-hot-metalworking]}
      inventory: {nullius-molten-iron-bloom: 8, nullius-molten-aluminum-bloom: 8}
      fluids: {nullius-compressed-volcanic-gas: 112.5}
    place:
      foundry: {prototype: nullius-foundry-1-pneumatic, count: 4, at: auto}
    connect: [gas -> foundry[*].energy_input]
    act:
      - set_recipe: {entity: foundry[1], recipe: nullius-hot-iron-plate}
      - set_recipe: {entity: foundry[2], recipe: nullius-hot-iron-rod}
      - set_recipe: {entity: foundry[3], recipe: nullius-hot-aluminum-sheet}
      - set_recipe: {entity: foundry[4], recipe: nullius-hot-aluminum-rod}
    run: {parallel_executors: 4, ticks: 243, timeout: 500}
    expect:
      terminal:
        consumed: {nullius-molten-iron-bloom: 8, nullius-molten-aluminum-bloom: 8, nullius-compressed-volcanic-gas: 112.5}
        produced: {nullius-iron-plate: 3, nullius-iron-rod: 5, nullius-aluminum-sheet: 5, nullius-aluminum-rod: 5}
        spoiled: {nullius-iron-ingot: 0, nullius-alumina: 0}

  thermal-engineering-1:
    milestone: M12
    given:
      prior_stage: efficient-metallurgic-science
      force: {researched: [nullius-efficient-metallurgic-science, nullius-mineral-processing-1, nullius-metallurgy-1, nullius-metalworking-1, nullius-boiling-1, nullius-solar-thermal-power-1]}
      inventory: {nullius-metallurgic-pack: 200, nullius-geology-pack: 10, nullius-mechanical-pack: 5}
      fluids: {nullius-compressed-volcanic-gas: 712.5}
    place:
      lab: {prototype: nullius-lab-1-pneumatic, at: [0, 0]}
    connect: [gas -> lab.energy_input]
    act:
      - set_research: nullius-thermal-engineering-1
      - insert_research_inputs: lab
    run: {unit_count: 5, unit_time: 30, researching_speed: 1, ticks: 9002}
    expect:
      terminal:
        force: {researched: [nullius-thermal-engineering-1]}
        consumed: {nullius-metallurgic-pack: 200, nullius-geology-pack: 10, nullius-mechanical-pack: 5, nullius-compressed-volcanic-gas: 712.5}
        lab_inputs_contains: [nullius-metallurgic-pack, nullius-geology-pack, nullius-mechanical-pack]

  thermal-machine-prototypes:
    milestone: [M13, M15, M16]
    matrix:
      - {tier: 1, base: nullius-crusher-1, thermal: nullius-crusher-1-thermal, research: nullius-thermal-engineering-1, productivity: 0.05, min_temperature: 100, max_temperature: 250}
      - {tier: 1, base: nullius-small-furnace-1, thermal: nullius-small-furnace-1-thermal, research: nullius-thermal-engineering-1, productivity: 0.05, min_temperature: 100, max_temperature: 250}
      - {tier: 1, base: nullius-medium-furnace-1, thermal: nullius-medium-furnace-1-thermal, research: nullius-thermal-engineering-1, productivity: 0.05, min_temperature: 100, max_temperature: 250}
      - {tier: 1, base: nullius-large-furnace-1, thermal: nullius-large-furnace-1-thermal, research: nullius-thermal-engineering-1, productivity: 0.05, min_temperature: 100, max_temperature: 250}
      - {tier: 1, base: nullius-foundry-1, thermal: nullius-foundry-1-thermal, research: nullius-thermal-engineering-1, productivity: 0.05, min_temperature: 100, max_temperature: 250}
      - {tier: 2, base: nullius-crusher-2, thermal: nullius-crusher-2-thermal, research: nullius-thermal-engineering-2, productivity: 0.10, min_temperature: 200, max_temperature: 500}
      - {tier: 2, base: nullius-small-furnace-2, thermal: nullius-small-furnace-2-thermal, research: nullius-thermal-engineering-2, productivity: 0.10, min_temperature: 200, max_temperature: 500}
      - {tier: 2, base: nullius-medium-furnace-2, thermal: nullius-medium-furnace-2-thermal, research: nullius-thermal-engineering-2, productivity: 0.10, min_temperature: 200, max_temperature: 500}
      - {tier: 2, base: nullius-large-furnace-2, thermal: nullius-large-furnace-2-thermal, research: nullius-thermal-engineering-2, productivity: 0.10, min_temperature: 200, max_temperature: 500}
      - {tier: 2, base: nullius-foundry-2, thermal: nullius-foundry-2-thermal, research: nullius-thermal-engineering-2, productivity: 0.10, min_temperature: 200, max_temperature: 500}
      - {tier: 3, base: nullius-crusher-3, thermal: nullius-crusher-3-thermal, research: nullius-thermal-engineering-3, productivity: 0.15, min_temperature: 500, max_temperature: 1500}
      - {tier: 3, base: nullius-small-furnace-3, thermal: nullius-small-furnace-3-thermal, research: nullius-thermal-engineering-3, productivity: 0.15, min_temperature: 500, max_temperature: 1500}
      - {tier: 3, base: nullius-medium-furnace-3, thermal: nullius-medium-furnace-3-thermal, research: nullius-thermal-engineering-3, productivity: 0.15, min_temperature: 500, max_temperature: 1500}
      - {tier: 3, base: nullius-foundry-3, thermal: nullius-foundry-3-thermal, research: nullius-thermal-engineering-3, productivity: 0.15, min_temperature: 500, max_temperature: 1500}
    expect:
      prototype:
        item_to_place: matrix.base
        minable_result: matrix.base
        crafting_speed: "=base.crafting_speed"
        crafting_categories: "=base.crafting_categories"
        module_slots: "=base.module_slots"
        allowed_effects: "=base.allowed_effects"
        energy_usage: "=base.energy_usage"
        energy_source: {type: heat, min_temperature: matrix.min_temperature, max_temperature: matrix.max_temperature}
        effect_receiver: {base_effect: {productivity: matrix.productivity}}

  thermal-cell-1:
    milestone: M13
    given:
      surface: nauvis
      force: {researched: [nullius-thermal-engineering-1]}
      inventory: {nullius-solar-collector-1: 15, nullius-heat-pipe-1: 30, nullius-crusher-1: 5, nullius-small-furnace-1: 5, nullius-foundry-1: 5}
      recipe_inputs: {nullius-limestone: 800, nullius-alumina: 900, nullius-graphite: 500, nullius-iron-ingot: 400}
      modules: 0
    place:
      heat-source: {prototype: nullius-solar-collector-1, count: 15, at: auto}
      heat-pipe: {prototype: nullius-heat-pipe-1, count: "<=30", at: auto}
      crusher: {prototype: nullius-crusher-1, count: 5, at: auto}
      furnace: {prototype: nullius-small-furnace-1, count: 5, at: auto}
      foundry: {prototype: nullius-foundry-1, count: 5, at: auto}
      debug-input-chest: {prototype: steel-chest, count: 15, at: auto}
      debug-output-chest: {prototype: steel-chest, count: 3, at: auto}
    connect: ["heat-source[*] -> heat-pipe", "heat-pipe -> crusher", "heat-pipe -> furnace", "heat-pipe -> foundry"]
    act:
      - rotate_mode: {entities: [crusher, furnace, foundry], mode: thermal}
      - set_recipe: {entity: crusher, recipe: nullius-crushed-limestone}
      - set_recipe: {entity: furnace, recipe: nullius-aluminum-ingot}
      - set_recipe: {entity: foundry, recipe: nullius-iron-plate}
    run: {base_cycles: {per_machine: 20, total_per_recipe: 100}, until: all_inputs_consumed, timeout: 65000}
    expect:
      terminal:
        entities: {crusher: {prototype: nullius-crusher-1-thermal, count: 5}, furnace: {prototype: nullius-small-furnace-1-thermal, count: 5}, foundry: {prototype: nullius-foundry-1-thermal, count: 5}}
        temperature: {crusher: ">=100", furnace: ">=100", foundry: ">=100"}
        consumed: {nullius-limestone: 800, nullius-alumina: 900, nullius-graphite: 500, nullius-iron-ingot: 400}
        produced: {nullius-crushed-limestone: 525, stone: 315, nullius-aluminum-ingot: 315, nullius-aluminum-carbide: 420, nullius-iron-plate: 315}
        productivity_bonus: {crusher: 0.05, furnace: 0.05, foundry: 0.05}
        electric_energy_consumed_by_process_machines: 0
        items_preserved: {nullius-crusher-1: 5, nullius-small-furnace-1: 5, nullius-foundry-1: 5}

  industrial-optimization-1:
    milestone: M14
    given:
      force: {researched: [nullius-thermal-engineering-1]}
      inventory: {nullius-metallurgic-pack: 300}
    matrix:
      - {technology: nullius-crushing-productivity-1, recipe: nullius-crushed-limestone, unrelated: nullius-aluminum-ingot}
      - {technology: nullius-smelting-productivity-1, recipe: nullius-aluminum-ingot, unrelated: nullius-iron-plate}
      - {technology: nullius-casting-productivity-1, recipe: nullius-iron-plate, unrelated: nullius-crushed-limestone}
    act:
      - research_each: matrix.technology
    run: {levels_each: 1, level_cost: 100, total_units: 300}
    expect:
      terminal:
        consumed: {nullius-metallurgic-pack: 300}
        technology_level: {nullius-crushing-productivity-1: 2, nullius-smelting-productivity-1: 2, nullius-casting-productivity-1: 2}
        recipe_productivity_bonus: {nullius-crushed-limestone: 0.01, nullius-aluminum-ingot: 0.01, nullius-iron-plate: 0.01}
        next_level_cost: {nullius-crushing-productivity-1: 400, nullius-smelting-productivity-1: 400, nullius-casting-productivity-1: 400}
        downstream_technology_prerequisites_added: 0

  refractory-production:
    milestone: M15
    validator: refractory-production
    given:
      force: {researched: [nullius-vulcanus-refractory-engineering]}
      inventory: {nullius-alumina: 5, nullius-silica: 8, nullius-mineral-dust: 12, nullius-aluminum-sheet: 8, nullius-silicon-insulation: 2, nullius-eutectic-salt: 5, nullius-heat-pipe-1: 2, nullius-pipe-2: 6, nullius-vulcanus-radiator-1: 1}
      fluids: {nullius-compressed-volcanic-gas: 203.4}
      heat: {furnace: 500}
    place:
      mixer: {prototype: nullius-medium-assembler-1-pneumatic, at: [8, 0]}
      furnace: {prototype: nullius-small-furnace-2-pneumatic, at: [20, 0]}
      foundry: {prototype: nullius-foundry-1-pneumatic, at: [32, -4]}
      radiator-assembler: {prototype: nullius-medium-assembler-1-pneumatic, at: [32, 4]}
    act:
      - set_recipe: {entity: mixer, recipe: nullius-refractory-mix-vulcanus}
      - transfer: {from: mixer, to: furnace, item: nullius-refractory-mix, count: 10}
      - set_recipe: {entity: furnace, recipe: nullius-refractory-brick-vulcanus}
      - transfer: {from: furnace, to: [foundry, radiator-assembler], item: nullius-refractory-brick, count: 8}
      - set_recipe: {entity: foundry, recipe: nullius-heat-pipe-2-vulcanus}
      - set_recipe: {entity: radiator-assembler, recipe: nullius-vulcanus-radiator-2-refractory}
    run: {stages: sequential, final_stage_parallelism: 2, ticks: 3210, timeout: 3500}
    expect:
      terminal:
        produced: {nullius-refractory-mix: 10, nullius-refractory-brick: 30, nullius-heat-pipe-2: 2, nullius-vulcanus-radiator-2: 1}
        retained: {nullius-refractory-brick: 22}
        consumed: {nullius-alumina: 5, nullius-silica: 8, nullius-mineral-dust: 12, nullius-aluminum-sheet: 8, nullius-silicon-insulation: 2, nullius-eutectic-salt: 5, nullius-heat-pipe-1: 2, nullius-pipe-2: 6, nullius-vulcanus-radiator-1: 1, nullius-compressed-volcanic-gas: 203.4}
        forbidden_inputs: [nullius-insulation, nullius-pipe-3, nullius-plastic, nullius-rubber]

  titanium-pilot:
    milestone: M15
    validator: titanium-pilot
    given:
      force: {researched: [nullius-volcanic-titanium-metallurgy]}
      inventory: {nullius-sand: 400, nullius-graphite: 14, nullius-aluminum-ingot: 8}
      fluids: {nullius-acid-sulfuric: 1200, nullius-chlorine: 160, nullius-water: 60, nullius-acid-nitric: 2, nullius-compressed-volcanic-gas: 963.9}
      heat: {wet-furnace: 500, radiators: 500}
    place:
      flotation-cell: {prototype: nullius-flotation-cell-1-pneumatic, count: 8, at: auto}
      wet-furnace: {prototype: nullius-medium-furnace-2-pneumatic, count: 2, at: auto}
      radiator: {prototype: nullius-vulcanus-radiator-2, count: 2, at: auto}
      foundry: {prototype: nullius-foundry-1-pneumatic, count: 1, at: auto}
    run: {parallelism: 8, ticks: 3316, timeout: 4600}
    expect:
      terminal:
        produced: {nullius-rutile: 8, nullius-titanium-tetrachloride: 30, nullius-titanium-ingot: 4, nullius-aluminum-chloride: 8, nullius-titanium-plate: 3, nullius-hydrogen-chloride: 120}
        retained: {nullius-titanium-plate: 3, nullius-hydrogen-chloride: 120, nullius-alumina: 2, nullius-carbon-dioxide: 200, nullius-mineral-dust: 50, nullius-sludge: 641}
        forbidden_inputs: [nullius-sodium, nullius-argon]
        electric_paths: 0

  titanium-construction:
    milestone: M15
    validator: titanium-construction
    given:
      force: {researched: [nullius-volcanic-titanium-metallurgy]}
      inventory: {nullius-titanium-plate: 3, nullius-refractory-brick: 32, nullius-hydro-plant-1: 1, nullius-chemical-plant-1: 1, nullius-medium-tank-2: 1, nullius-red-wire: 5, nullius-foundry-1: 1, nullius-small-furnace-2: 1, bob-turbo-inserter: 2}
      fluids: {nullius-compressed-volcanic-gas: 223.2}
    place:
      assembler: {prototype: nullius-medium-assembler-1-pneumatic, count: 2, at: auto}
    run: {parallelism: 2, ticks: 1864, timeout: 2100}
    expect:
      terminal:
        produced: {nullius-hydro-plant-2: 1, nullius-foundry-2: 1}
        retained_inputs: 0
        seawater_intake_consumed: 0
        electric_paths: 0

  thermal-cell-2:
    milestone: M15
    given:
      surface: nauvis
      force: {researched: [nullius-thermal-engineering-2]}
      inventory: {nullius-solar-collector-2: 25, nullius-heat-pipe-2: 25, nullius-crusher-2: 5, nullius-small-furnace-2: 5, nullius-medium-furnace-2: 5, nullius-large-furnace-2: 5, nullius-foundry-2: 5}
      recipe_inputs: {nullius-limestone: 800, nullius-alumina: 1800, nullius-graphite: 1000, nullius-box-ceramic-powder: 200, nullius-iron-ingot: 400}
      modules: 0
    place:
      heat-source: {prototype: nullius-solar-collector-2, count: 25, at: auto}
      heat-pipe: {prototype: nullius-heat-pipe-2, count: 25, at: runtime-heat-connection}
      crusher: {prototype: nullius-crusher-2, count: 5, at: auto}
      small-furnace: {prototype: nullius-small-furnace-2, count: 5, at: auto}
      medium-furnace: {prototype: nullius-medium-furnace-2, count: 5, at: auto}
      large-furnace: {prototype: nullius-large-furnace-2, count: 5, at: auto}
      foundry: {prototype: nullius-foundry-2, count: 5, at: auto}
      debug-input-chest: {prototype: steel-chest, count: 25, at: auto}
      debug-output-chest: {prototype: steel-chest, count: 5, at: auto}
    connect: ["heat-source[*] -> heat-pipe[*]", "heat-pipe[*] -> process-machine[*]"]
    act:
      - rotate_mode: {entities: [crusher, small-furnace, medium-furnace, large-furnace, foundry], mode: thermal}
      - set_recipe: {entity: crusher, recipe: nullius-crushed-limestone}
      - set_recipe: {entity: small-furnace, recipe: nullius-aluminum-ingot}
      - set_recipe: {entity: medium-furnace, recipe: nullius-aluminum-ingot}
      - set_recipe: {entity: large-furnace, recipe: nullius-boxed-refractory-brick}
      - set_recipe: {entity: foundry, recipe: nullius-iron-plate}
    run: {base_cycles: {per_machine: 20, crusher: 100, dry-smelting: 200, bulk-smelting: 100, casting: 100}, until: all_inputs_consumed, timeout: 65000}
    expect:
      terminal:
        entities: {crusher: {prototype: nullius-crusher-2-thermal, count: 5}, small-furnace: {prototype: nullius-small-furnace-2-thermal, count: 5}, medium-furnace: {prototype: nullius-medium-furnace-2-thermal, count: 5}, large-furnace: {prototype: nullius-large-furnace-2-thermal, count: 5}, foundry: {prototype: nullius-foundry-2-thermal, count: 5}}
        temperature: {heat-source: ">=200", heat-pipe: ">=200", process-machine: ">=200"}
        consumed: {nullius-limestone: 800, nullius-alumina: 1800, nullius-graphite: 1000, nullius-box-ceramic-powder: 200, nullius-iron-ingot: 400}
        produced: {nullius-crushed-limestone: 550, stone: 330, nullius-aluminum-ingot: 660, nullius-aluminum-carbide: 880, nullius-box-refractory-brick: 660, nullius-iron-plate: 330}
        productivity_bonus: {process-machine: 0.10}
        electric_energy_consumed_by_process_machines: 0
        items_preserved: {nullius-crusher-2: 5, nullius-small-furnace-2: 5, nullius-medium-furnace-2: 5, nullius-large-furnace-2: 5, nullius-foundry-2: 5}

  thermal-cell-3:
    milestone: M16
    given:
      surface: nauvis
      force: {researched: [nullius-thermal-engineering-3]}
      inventory: {nullius-reactor: 20, nullius-fusion-cell: 40, nullius-heat-pipe-3: 20, nullius-crusher-3: 5, nullius-small-furnace-3: 5, nullius-medium-furnace-3: 5, nullius-foundry-3: 5}
      recipe_inputs: {nullius-limestone: 800, nullius-alumina: 1800, nullius-graphite: 1000, nullius-iron-ingot: 400}
      modules: 0
    place:
      heat-source: {prototype: nullius-reactor, count: 20, at: auto}
      heat-pipe: {prototype: nullius-heat-pipe-3, count: 20, at: runtime-heat-connection}
      crusher: {prototype: nullius-crusher-3, count: 5, at: auto}
      small-furnace: {prototype: nullius-small-furnace-3, count: 5, at: auto}
      medium-furnace: {prototype: nullius-medium-furnace-3, count: 5, at: auto}
      foundry: {prototype: nullius-foundry-3, count: 5, at: auto}
      debug-input-chest: {prototype: steel-chest, count: 20, at: auto}
      debug-output-chest: {prototype: steel-chest, count: 4, at: auto}
    connect: ["heat-source[*] -> heat-pipe[*]", "heat-pipe[*] -> process-machine[*]"]
    act:
      - fuel: {entity: heat-source, item: nullius-fusion-cell, count_each: 2}
      - rotate_mode: {entities: [crusher, small-furnace, medium-furnace, foundry], mode: thermal}
      - set_recipe: {entity: crusher, recipe: nullius-crushed-limestone}
      - set_recipe: {entity: small-furnace, recipe: nullius-aluminum-ingot}
      - set_recipe: {entity: medium-furnace, recipe: nullius-aluminum-ingot}
      - set_recipe: {entity: foundry, recipe: nullius-iron-plate}
    run: {base_cycles: {per_machine: 20, crusher: 100, dry-smelting: 200, casting: 100}, until: all_inputs_consumed, timeout: 20000}
    expect:
      terminal:
        entities: {crusher: {prototype: nullius-crusher-3-thermal, count: 5}, small-furnace: {prototype: nullius-small-furnace-3-thermal, count: 5}, medium-furnace: {prototype: nullius-medium-furnace-3-thermal, count: 5}, foundry: {prototype: nullius-foundry-3-thermal, count: 5}}
        temperature: {heat-source: ">=500", heat-pipe: ">=500", process-machine: ">=500"}
        consumed: {nullius-limestone: 800, nullius-alumina: 1800, nullius-graphite: 1000, nullius-iron-ingot: 400}
        produced: {nullius-crushed-limestone: 575, stone: 345, nullius-aluminum-ingot: 690, nullius-aluminum-carbide: 920, nullius-iron-plate: 345}
        productivity_bonus: {process-machine: 0.15}
        electric_energy_consumed_by_process_machines: 0
        items_preserved: {nullius-crusher-3: 5, nullius-small-furnace-3: 5, nullius-medium-furnace-3: 5, nullius-foundry-3: 5}

```
