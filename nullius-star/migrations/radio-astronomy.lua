-- Configuration-change handlers of other mods raise technology events before
-- this mod's rebuild, so the dish state must exist first. The engine re-applies
-- researched Astronomy's new unlocks itself whenever mods change.
storage.nullius_dishes = {}
storage.nullius_dish_groups = {}
