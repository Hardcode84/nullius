# Planner executor contract

- **given:** The generated fixture declares research, recipe ingredients, five
  base cycles, six cycles of fuel, and guaranteed outputs. It supplies all
  intermediate ingredients directly. Heat consumers receive scripted heat at
  500 degrees every 30 ticks.
- **place:** Put each selected executor on a separate cleared Vulcanus tile area.
- **connect:** Insert fluids into the selected machine's input and fuel boxes.
  This test does not connect machines to each other.
- **act:** Select the declared recipe. Furnaces select their recipe from inputs.
- **run:** Feed finite inputs and remove outputs every 30 ticks. Stop each machine
  when it has completed the declared cycles and produced the guaranteed outputs.
- **expect:** Each selected recipe runs on its declared executor. Native
  productivity produces at least the guaranteed whole-cycle bonus. Finish before
  the generated fixture deadline and the `test.json` runner deadline.

Regenerate `fixture.lua` with `tools/plan_factorio_factory.py --executor-fixture`.
The test proves executor compatibility and output quantities. A connected
campaign test must prove heat delivery, logistics, and continuous factory rates.
