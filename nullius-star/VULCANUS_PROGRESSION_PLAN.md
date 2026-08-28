# Vulcanus progression

## Level 1 — Player milestones

| ID | Milestone | Segment time | Cumulative time |
|---|---|---:|---:|
| M0 | Land, recover the wreck, and assess the starting area | 0–5 min | 0–5 min |
| M1 | Establish temporary pneumatic bootstrap | 5–10 min | 5–15 min |
| M2 | Make the pneumatic bootstrap self-sustaining | 5–10 min | 10–25 min |
| M3 | Establish the basic local material palette | 15–25 min | 25–50 min |
| M4 | Bring heat-dependent metallurgy and chemistry online | 15–25 min | 40–75 min |
| M5 | Produce the first metallurgic science | 10–15 min | 50–90 min |
| M6 | Reproduce and expand the core factory from local production | 25–40 min | 75–130 min |
| M7 | Deliver the first stable science batch with the next cycle ready | 15–25 min | 90–155 min |
| M8 | Replace rock-mined graphite with atmosphere and HCl chemistry | 30–45 min | 120–200 min |
| M9 | Produce geology, climatology, mechanical, and electrical science | 45–75 min | 165–275 min |
| M10 | Scale local science and complete Thermal Engineering 1 | 45–75 min | 210–350 min |
| M11 | Start solar-heated crushing, smelting, and casting on Nauvis | 20–40 min | 230–390 min |
| M12 | Complete the first crushing, smelting, and casting optimization levels | 30–50 min | 260–440 min |
| M13 | Unlock and deploy tier-2 thermal industry alongside Nauvis progression | 2–4 h | 6–11 h |
| M14 | Unlock tier-3 thermal industry and supply it from nuclear heat | 4–8 h | 10–19 h |

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
  order: [activation, vent-prime, gas-self-power, lava-separation, bloom-cooldown, aluminum-reduction, sulfur-catalysis, metallurgic-pack-recipe, construction-closure, metallurgic-pack-10, hcl-thermal-cracking, basic-science-10, thermal-engineering-1, thermal-cell-1, industrial-optimization-1]
  supporting: [pneumatic-heat]
  given: "subset of cumulative prior terminal state + declared raw/debug boundaries"
  expect: "exact local terminal state"
  cross_chunk_save: false

validators:
  construction: "python3 tools/analyze_factorio_prereqs.py @nullius-star/progression/vulcanus-construction.args"
  metallurgic-pack: "python3 tools/analyze_factorio_prereqs.py @nullius-star/progression/vulcanus-pack.args"
  renewable-graphite: "python3 tools/analyze_factorio_prereqs.py @nullius-star/progression/vulcanus-renewable-graphite.args"
  basic-science: "python3 tools/analyze_factorio_prereqs.py @nullius-star/progression/vulcanus-basic-science.args"
  thermal-furnace-sizes: "python3 tools/analyze_factorio_prereqs.py @nullius-star/progression/nauvis-thermal-furnace-sizes.args"

planned_prototypes:
  technologies:
    nullius-thermal-engineering-1:
      prerequisites: [nullius-pneumatic-technology, nullius-mineral-processing-1, nullius-metallurgy-1, nullius-metalworking-1, nullius-boiling-1, nullius-solar-thermal-power-1]
      unit: {count: 5, time: 30, ingredients: {nullius-metallurgic-pack: 40, nullius-geology-pack: 2, nullius-mechanical-pack: 1}}
      totals: {nullius-metallurgic-pack: 200, nullius-geology-pack: 10, nullius-mechanical-pack: 5}
      unlocks: [nullius-crusher-1-thermal, nullius-small-furnace-1-thermal, nullius-medium-furnace-1-thermal, nullius-large-furnace-1-thermal, nullius-foundry-1-thermal]
    nullius-thermal-engineering-2:
      prerequisites: [nullius-thermal-engineering-1, nullius-mineral-processing-2, nullius-metallurgy-2, nullius-metalworking-2, nullius-thermal-storage-2, nullius-solar-thermal-power-2]
      unit: {count: 10, time: 45, ingredients: {nullius-metallurgic-pack: 80, nullius-geology-pack: 2, nullius-mechanical-pack: 1, nullius-electrical-pack: 1}}
      totals: {nullius-metallurgic-pack: 800, nullius-geology-pack: 20, nullius-mechanical-pack: 10, nullius-electrical-pack: 10}
      unlocks: [nullius-crusher-2-thermal, nullius-small-furnace-2-thermal, nullius-medium-furnace-2-thermal, nullius-large-furnace-2-thermal, nullius-foundry-2-thermal]
    nullius-thermal-engineering-3:
      prerequisites: [nullius-thermal-engineering-2, nullius-mineral-processing-3, nullius-metallurgy-3, nullius-metalworking-4, nullius-thermal-storage-3, nullius-nuclear-power-1]
      unit: {count: 20, time: 60, ingredients: {nullius-metallurgic-pack: 160, nullius-geology-pack: 2, nullius-climatology-pack: 1, nullius-mechanical-pack: 1, nullius-electrical-pack: 1}}
      totals: {nullius-metallurgic-pack: 3200, nullius-geology-pack: 40, nullius-climatology-pack: 20, nullius-mechanical-pack: 20, nullius-electrical-pack: 20}
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
        nullius-iron-ingot: 3
        nullius-aluminum-ingot: 2
        nullius-crushed-limestone: 1
        nullius-silica: 1
        sulfur: 1
      fluids: {nullius-compressed-volcanic-gas: 88.5}
    place:
      assembler: {prototype: nullius-small-assembler-1-pneumatic, at: [0, 0]}
    connect: [gas -> assembler.energy_input]
    act:
      - set_recipe: {entity: assembler, recipe: nullius-metallurgic-pack}
    run: {recipe_ticks: 900, crafting_speed: 0.5, ticks: 1802}
    expect:
      before_terminal: {tick: 1800, produced: 0}
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
      stock: {nullius-compressed-volcanic-gas: 24}
      mined_input: {nullius-graphite: 35, nullius-rutile: 1}
      lava: nullius-lava-pumping
      injected_intermediates: 0
      heat: {mode: scripted-preheat-per-cycle, heat_pipe_temperature: 250, pneumatic_heat_temperature: 500}
    act:
      - execute_manifest: metallurgic-pack
    run: {until: targets_complete, ticks: 71046, timeout: 71100}
    expect:
      terminal:
        produced: {nullius-metallurgic-pack: "=10"}
        selected_steps: "=11"
        consumed:
          nullius-iron-ingot: 30
          nullius-aluminum-ingot: 20
          nullius-crushed-limestone: 10
          nullius-silica: 10
          sulfur: 10
          nullius-compressed-volcanic-gas: 5985
        surplus:
          lava: 115
          nullius-aluminum-carbide: 28
          nullius-aluminum-ingot: 1
          nullius-compressed-volcanic-gas: 4
          nullius-crushed-limestone: 2
          nullius-molten-iron-bloom: 2
          nullius-oxygen: 400
          nullius-rutile: 1
          nullius-silica: 310
          stone: 676
        cycles:
          nullius-metallurgic-pack: 10
          nullius-aluminum-ingot: 7
          nullius-so2-catalytic-decomposition: 10
          nullius-lava-iron-separation: 8
          nullius-lava-aluminum-separation: 21
          nullius-lava-calcite-separation: 2
          nullius-lava-silica-extraction: 40
          nullius-lava-gas-extraction: 76
          nullius-lava-pumping: 75
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

  thermal-engineering-1:
    milestone: M10
    given:
      prior_stage: basic-science-10
      force: {researched: [nullius-pneumatic-technology, nullius-mineral-processing-1, nullius-metallurgy-1, nullius-metalworking-1, nullius-boiling-1, nullius-solar-thermal-power-1]}
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
    milestone: [M11, M13, M14]
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
    milestone: M11
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
    milestone: M12
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

implementation_holes:
  - {id: thermal-technologies, required_by: [M13, M14], missing: [nullius-thermal-engineering-2, nullius-thermal-engineering-3]}
  - {id: thermal-entities, required_by: [M13, M14], missing: [nullius-crusher-2-thermal, nullius-crusher-3-thermal, nullius-small-furnace-2-thermal, nullius-small-furnace-3-thermal, nullius-medium-furnace-2-thermal, nullius-medium-furnace-3-thermal, nullius-large-furnace-2-thermal, nullius-foundry-2-thermal, nullius-foundry-3-thermal]}
  - {id: nauvis-transition, required_by: [M13, M14], missing: [thermal-engineering-2-pairs, thermal-engineering-3-pairs]}
  - {id: repeatable-technologies, required_by: M12, missing: [nullius-crushing-productivity-1, nullius-smelting-productivity-1, nullius-casting-productivity-1]}
  - {id: recipe-family-generator, required_by: repeatable-technologies, fix: "generate change-recipe-productivity effects from resolved recipe categories; exclude maximum_productivity=0"}
  - {id: thermal-test-contracts, required_by: M12, missing: [industrial-optimization-1]}

```
