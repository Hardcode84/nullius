# Vulcanus progression

## Authorities

| Fact | Authority |
|---|---|
| Progression order and boundary intent | This document |
| Design rationale | `PLANET_VULCANUS.md` |
| Runtime setup and assertions | `tests/scenarios/<name>/` |
| Runtime deadline | `tests/scenarios/<name>/test.json` |
| Reachability boundary | `tests/progression/<name>.args` |
| Recipe, technology, and entity values | Factorio resolved prototypes |

## Flow

```text
activation
  -> pneumatic bootstrap
  -> self-powered gas
  -> lava materials
  -> heat chemistry
  -> bootstrap metallurgy
  -> construction closure
  -> renewable graphite
  -> basic science
  -> chemical science and thermite
  -> efficient metallurgy
  -> primitive logistics
  -> hot casting
  -> tier-1 thermal industry
  -> industrial optimization
  -> refractory and titanium industry
  -> tier-2 thermal industry
  -> tier-3 thermal industry
  -> thermal nanofabrication and physics science
```

## Milestones

| Milestone | Entrance boundary | Completion boundary | Runtime witnesses | Reachability witnesses |
|---|---|---|---|---|
| Activation | Vulcanus probe research completes | Vulcanus surface, character, and wreck are available | `vulcanus-activation` | — |
| Pneumatic bootstrap | Wreck inventory is available | Free gas is extracted and usable | `vulcanus-vent-prime`, `vulcanus-gas-vent-smoke` | — |
| Self-powered gas | Primed pneumatic equipment is available | Dedicated gas production sustains its own machinery | `vulcanus-gas-self-power` | — |
| Lava materials | Self-powered gas production is available | Local iron, aluminum, calcite, silica, stone, and sulfur-bearing gas paths operate | `vulcanus-lava-separation-*`, `vulcanus-bloom-cooldown-*` | — |
| Heat chemistry | Lava materials and wreck machinery are available | Aluminum reduction, sulfur catalysis, pneumatic heat, and thermal HCl cracking operate | `vulcanus-aluminum-reduction`, `vulcanus-sulfur-catalysis`, `vulcanus-pneumatic-heat-production`, `vulcanus-hcl-thermal-cracking` | — |
| Bootstrap metallurgy | Local metals and chemistry are available | Bootstrap metallurgic science can be crafted | `vulcanus-metallurgic-pack-recipe`, `vulcanus-metallurgic-pack-10` | `vulcanus-pack.args` |
| Construction closure | Bootstrap production is available | Core pneumatic factory and inorganic fluid handling can be reproduced locally | `vulcanus-construction-closure`, `vulcanus-inorganic-barrel`, `pneumatic-assemblers`, `pneumatic-barrel-pumps`, `pneumatic-boxer`, `vulcanus-pneumatic-compressor` | `vulcanus-construction.args`, `vulcanus-barrel.args`, `pneumatic-boxer.args` |
| Renewable graphite | Construction closure is available | Atmosphere and HCl chemistry replace rock-mined graphite | `vulcanus-hcl-thermal-cracking` | `vulcanus-renewable-graphite.args` |
| Basic science | Renewable graphite and construction closure are available | Local geology, climatology, mechanical, and electrical science operate | `vulcanus-basic-science-10` | `vulcanus-basic-science.args` |
| Chemical science and thermite | Basic science is available | Local alkali, acids, glass, lubricant, barrels, chemical science, and thermite operate | `vulcanus-caustic-bootstrap`, `vulcanus-chemical-*`, `vulcanus-thermite` | `vulcanus-caustic-bootstrap.args`, `vulcanus-chemical-*.args`, `vulcanus-thermite.args` |
| Efficient metallurgy | Bootstrap metallurgic and generic science are available | Efficient metallurgic research and production operate | `vulcanus-efficient-metallurgic-research`, `vulcanus-efficient-metallurgic-science` | `vulcanus-efficient-pack.args` |
| Primitive logistics | Efficient metallurgy is available | Clockwork logistics equipment operates | `primitive-robotics` | `vulcanus-primitive-robotics.args` |
| Hot casting | Efficient metallurgy and metalworking are available | Hot blooms are cast directly into useful products | `vulcanus-hot-casting` | `vulcanus-hot-casting.args` |
| Tier-1 thermal industry | Base industrial machines and solar heat are available | Thermal crushing, smelting, casting, and heat storage operate | `thermal-machines-1`, `thermal-cell-1`, `variant-upgrades` | `nauvis-thermal-furnace-sizes.args` |
| Industrial optimization | Efficient metallurgy and tier-1 process technology are available | Repeatable process productivity research affects eligible recipes | `industrial-optimization-1`, `industrial-productivity-technologies`, `recipe-productivity-family` | — |
| Refractory and titanium industry | Hot casting, local chemistry, and thermal storage are available | Refractory materials and pilot titanium equipment are produced locally | `vulcanus-boric-acid`, `carbothermic-sodium`, `vulcanus-refractory-production`, `vulcanus-titanium-pilot`, `vulcanus-titanium-construction` | `vulcanus-boric-acid.args`, `carbothermic-sodium.args`, `vulcanus-refractory-production.args`, `vulcanus-titanium-pilot.args`, `vulcanus-titanium-construction.args` |
| Tier-2 thermal industry | Refractory and tier-2 base machines are available | Tier-2 thermal machines and heat storage operate | `thermal-engineering-technologies`, `thermal-machines-higher-tiers`, `thermal-cell-2` | `nauvis-thermal-furnace-sizes.args` |
| Tier-3 thermal industry | Tier-2 thermal industry and nuclear heat are available | Tier-3 thermal machines and heat storage operate | `thermal-engineering-technologies`, `thermal-machines-higher-tiers`, `thermal-cell-3` | — |
| Thermal nanofabrication and physics science | High-temperature industry and physics intermediates are available | Thermal nanofabricators operate and physics science is locally reachable without electric execution | `thermal-nanofabricators` | `vulcanus-physics-production.args`, `tests/test_vulcanus_physics_contract.py` |

## Cross-cutting contracts

| Contract | Runtime witnesses |
|---|---|
| Surface restrictions | `recipe-surface-conditions`, `renewable-placement`, `water-well-placement`, `vulcanus-polymer-restrictions` |
| Polymer-free substitutes | `vulcanus-high-temperature-resin`, `vulcanus-polymer-free-recipes`, `vulcanus-boxed-polymer-free` |
| Checkpoint aggregation across surfaces | `checkpoint-multisurface` |
| Vulcanus mining productivity | `vulcanus-mining-productivity` |
| Temperature sensing | `temperature-sensor` |
| Pneumatic heat ownership and geometry | `vulcanus-pneumatic-heat` |
