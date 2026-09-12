-- The runner appends this interface to each version's mod control file.
remote.add_interface("release-upgrade", {
  seed = function()
    local force = game.forces.player
    for _, name in ipairs({"nullius-probe-vulcanus", "nullius-geology-2",
        "nullius-climatology-2", "nullius-air-separation-2"}) do
      force.technologies[name].researched = true
    end
    probe.on_probe_researched("nullius-probe-vulcanus", force)
    local body = storage.nullius_probe_androids["nullius-vulcanus"]
    body.insert{name = "nullius-iron-plate", count = 17}
    local tag = force.add_chart_tag(body.surface, {
      position = body.position, text = "Upgrade body",
      icon = {type = "item", name = "character"},
    })
    assert(tag, "fixture map marker was not created")
    storage.nullius_android_tag = {[body.unit_number] = tag}
    storage.nullius_tag_android = {[tag.tag_number] = body}
    storage.release_upgrade_fixture = {body = body, unit = body.unit_number, tag = tag}
  end,
  verify = function()
    assert(script.active_mods["nullius-star"] == "0.0.2", "candidate was not loaded")
    local fixture = storage.release_upgrade_fixture
    local body = fixture.body
    local force = body.force
    local landing = probe.get_landing(force)
    assert(landing and landing.android == body and landing.unit == fixture.unit,
      "upgrade replaced the probe body")
    assert(body.get_item_count("nullius-iron-plate") == 17, "body inventory changed")
    assert(storage.nullius_probe_androids == nil, "old probe storage remains")
    assert(fixture.tag.valid and fixture.tag.text == "Upgrade body", "marker changed")
    assert(storage.nullius_tag_android[force.index .. ":" .. fixture.tag.tag_number] == body,
      "marker reverse lookup was not converted")
    assert(storage.nullius_tag_android[fixture.tag.tag_number] == nil, "old marker key remains")
    for _, name in ipairs({"nullius-geology-pack-vulcanus-2",
        "nullius-climatology-pack-vulcanus-2", "nullius-vulcanus-residual-gas"}) do
      assert(force.recipes[name].enabled, "researched recipe remains locked: " .. name)
    end
    probe.on_probe_researched("nullius-probe-vulcanus", force)
    assert(body.surface.count_entities_filtered{name = "nullius-landing-main", force = force} == 1,
      "upgrade duplicated landing supplies")
    assert(probe.get_landing(force).android == body, "reactivation replaced the body")
    helpers.write_file("upgrade-result.json", helpers.table_to_json{
      status = "pass", from = "0.0.1", to = script.active_mods["nullius-star"],
      factorio_version = script.active_mods.base, tick = game.tick,
    }, false)
  end,
})
