-- given: declared pre-physics research and recipe inputs, including boric acid.
-- place/connect: isolated recipe stations and explicit electric grids on Fulgora properties.
-- act/run: execute the fixture batches; transfer crafted physics boxes to unpacking.
-- expect: compatible recipes complete; deterministic outputs and productivity match.
-- Random drops are checked separately by fulgora-filtration, not asserted at their means.
require("__nullius-star__/scenarios/planner-executor-runner")("planner-fulgora-physics-executors", require("fixture"))
