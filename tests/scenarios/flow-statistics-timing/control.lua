-- given: a separate force and surface with zero build statistics
-- place/connect: none
-- act: record one build and removal through the native statistics API
-- run: read in the same tick and one tick later
-- expect: both totals equal one on the next tick
local name="nullius-small-furnace-1"
script.on_nth_tick(1,function()
  if not storage.started then
    storage.started=game.tick
    storage.surface=game.create_surface("flow-statistics-timing",{width=32,height=32})
    storage.force=game.create_force("flow-statistics-timing")
    local statistics=storage.force.get_entity_build_count_statistics(storage.surface)
    statistics.on_flow(name,1)
    statistics.on_flow(name,-1)
    storage.immediate={input=statistics.get_input_count(name),output=statistics.get_output_count(name)}
    return
  end
  local statistics=storage.force.get_entity_build_count_statistics(storage.surface)
  local later={input=statistics.get_input_count(name),output=statistics.get_output_count(name)}
  assert(later.input==1,"next-tick build count")
  assert(later.output==1,"next-tick removal count")
  helpers.write_file("factorio-tests/flow-statistics-timing.json",helpers.table_to_json{
    schema=1,case="flow-statistics-timing",status="pass",factorio_version=script.active_mods.base,
    tick=game.tick,assertions=2,failure_count=0,failures={},
    observations={immediate=storage.immediate,next_tick=later},
  },false)
  script.on_nth_tick(1,nil)
end)
