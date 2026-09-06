# First-physics executor contract

- **given:** The generated fixture supplies pre-physics research, installed
  machines, recipe ingredients, finite fuel, and scripted heat. Every researched
  technology is checked for physics-science consumption.
- **place:** Put each selected executor in a separate cleared area on Vulcanus.
- **connect:** Transfer the physics assembler's measured boxed output through
  the fixture ledger to the unpacking machine. Supply no boxed physics packs.
- **act:** Run one physics assembly batch, then 25 unpacking cycles. Run the
  declared cycles for all other selected recipes, including the argon, carbon
  fiber, processor, battery, and ordinary and boxed equipment routes selected
  by the planner.
- **run:** Poll every 30 ticks. Stop at the generated fixture deadline.
- **expect:** Each recipe produces its guaranteed output. One batch produces
  25 physics boxes; the unpacking machine produces 125 physics packs from them.

This is an executor test with a connected final material ledger. It supplies
upstream intermediates and heat. It does not prove raw-resource-to-physics
logistics, factory construction, or total campaign time.
