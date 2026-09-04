local save_lineage = {}

local unsupported_save_message =
  "Nullius* cannot load a save created with upstream Nullius. " ..
  "Start a new game with Nullius* enabled."

function save_lineage.validate(event)
  local changes = event and event.mod_changes
  local upstream = changes and changes.nullius
  if upstream and upstream.old_version then
    error(unsupported_save_message)
  end
end

return save_lineage
