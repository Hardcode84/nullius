local active_mods = mods or script.active_mods

return {is_2_1 = string.match(active_mods.base, "^2%.1%.") ~= nil}
