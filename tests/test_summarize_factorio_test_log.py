import pytest

from tools.summarize_factorio_test_log import prototype_warnings, summarize


def test_complete_log_keeps_native_failure_and_location():
    report = summarize("""[1/2] PASS first - 2 assertions
[2/2] FAIL second - 1s
  scenario did not write required result
  Error while running event level::on_init
  __level__/control.lua:5: LuaEntity doesn't contain key fluidbox.
  artifacts: /tmp/second
Result: 1 passed, 1 failed in 2s
""")
    assert report["complete"]
    assert report["failure_groups"] == {"LuaEntity doesn't contain key fluidbox.": ["second"]}
    assert report["failures"][0]["artifacts"] == "/tmp/second"
    assert "control.lua:5" in report["failures"][0]["locations"][0]


def test_incomplete_log_requires_explicit_option():
    with pytest.raises(ValueError, match="no final result"):
        summarize("[1/2] PASS first - 2 assertions\n")
    assert not summarize("[1/2] PASS first - 2 assertions\n", True)["complete"]


def test_final_counts_must_match_records():
    with pytest.raises(ValueError, match="do not match"):
        summarize("[1/2] PASS first - 2 assertions\nResult: 2 passed, 0 failed in 1s\n")


def test_unused_fields_exclude_external_and_test_prototypes():
    report = prototype_warnings("""Value ROOT.recipe.nullius-a.always_show_products was not used.
Value ROOT.recipe.nullius-b.always_show_products was not used.
Value ROOT.recipe.factorio-test-nullius-a.always_show_products was not used.
Value ROOT.recipe.external.always_show_products was not used.
Finished checking unused prototype data
Factorio initialised
""")
    assert report["nullius_warnings"] == 2
    assert report["groups"]["recipe.always_show_products"]["prototypes"] == 2


def test_incomplete_prototype_audit_cannot_report_zero_warnings():
    with pytest.raises(ValueError, match="did not finish"):
        prototype_warnings("Error while loading prototypes")
