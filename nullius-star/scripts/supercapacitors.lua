local capacitors = {}
local config = require("shared.supercapacitors")
local bases = {}
for _, base in ipairs(config.machines) do bases[base .. "-supercapacitor"] = base end

local function settle(row)
  local entity = row.entity
  entity.energy = math.max(0, entity.energy - entity.electric_buffer_size *
    config.leakage_per_second * (game.tick - row.tick) / 60)
  row.tick = game.tick
end

local function track(entity)
  storage.nullius_supercapacitors[entity.unit_number] = {entity=entity, tick=game.tick}
end

function capacitors.rebuild()
  local previous = storage.nullius_supercapacitors or {}
  storage.nullius_supercapacitors = {}
  local names = {}
  for name in pairs(bases) do names[#names + 1] = name end
  for _, surface in pairs(game.surfaces) do
    for _, entity in pairs(surface.find_entities_filtered{name=names}) do
      storage.nullius_supercapacitors[entity.unit_number] = previous[entity.unit_number] or
        {entity=entity, tick=game.tick}
    end
  end
end

script.on_nth_tick(60, function()
  for id, row in pairs(storage.nullius_supercapacitors) do
    if row.entity.valid then settle(row) else storage.nullius_supercapacitors[id] = nil end
  end
end)

function capacitors.unlocked(force, base)
  return force.technologies[config.technology].researched and force.recipes[base].enabled
end

-- Switching retains settings and stored joules, capped at the new capacity.
function capacitors.replace(entity, name, force)
  local ghost = entity.type == "entity-ghost"
  local behavior = entity.get_control_behavior()
  local signal = behavior and behavior.output_signal
  local read_charge = behavior and behavior.read_charge
  if not ghost then
    local row = storage.nullius_supercapacitors[entity.unit_number]
    if row then
      settle(row)
      storage.nullius_supercapacitors[entity.unit_number] = nil
    end
  end
  local energy = not ghost and entity.energy
  local health = not ghost and entity.health
  local tags = ghost and entity.tags
  local wires = {}
  if ghost then
    for id, connector in pairs(entity.get_wire_connectors(false)) do
      for _, connection in pairs(connector.connections) do
        wires[#wires + 1] = {id=id, target=connection.target, origin=connection.origin}
      end
    end
  end
  local replacement = assert(replace_fluid_entity(entity, name, force, nil),
    "Cannot switch battery to " .. name)
  if ghost then
    replacement.tags = tags
    for _, wire in ipairs(wires) do
      assert(replacement.get_wire_connector(wire.id, true).connect_to(
        wire.target, false, wire.origin), "Cannot restore battery ghost wire")
    end
  else
    replacement.energy = math.min(energy, replacement.electric_buffer_size)
    replacement.health = health
  end
  if behavior then
    local control = replacement.get_or_create_control_behavior()
    control.output_signal = signal
    control.read_charge = read_charge
  end
  return replacement
end

-- Locked variants placed or revived become ordinary batteries.
function capacitors.built(entity)
  local name = entity.type == "entity-ghost" and entity.ghost_name or entity.name
  local base = bases[name]
  if base and not capacitors.unlocked(entity.force, base) then
    return capacitors.replace(entity, base, entity.force)
  end
  if base and entity.type ~= "entity-ghost" then track(entity) end
  return entity
end

function capacitors.register()
  local transitions = require("scripts.transitions")
  for _, base in ipairs(config.machines) do
    local variant = base .. "-supercapacitor"
    transitions.register(base, variant, {
      condition = function(_, force) return capacitors.unlocked(force, base) end,
      replace_fn = capacitors.replace,
    })
    transitions.register(variant, base, {replace_fn = capacitors.replace})
  end
end
return capacitors
