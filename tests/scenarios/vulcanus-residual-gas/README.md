# Local argon contract

- **given:** Air separation 2 and pneumatic technology, with their prerequisites.
  No researched technology may consume physics science. Supply at most 15,000
  air and 2,000 compressed volcanic gas per distillery. Supply no residual gas
  or argon.
- **place:** Put two first-tier pneumatic distilleries at `(0, 0)` and `(3, -8)`.
- **connect:** At tick 600, place three ordinary pipes between the residual-gas
  output and the second distillery's input. No script transfers residual gas.
- **act:** Separate Vulcanus air, then separate the resulting residual gas.
  Scripted sinks remove CO2, SO2, trace gas, water, and measured argon.
- **run:** Check every 30 ticks. Stop by tick 15,000.
- **expect:** Produce 120 argon from 100 air-separation cycles and six residual
  separation cycles. Produce no argon before the pipe connection. Keep air
  separation 4 locked.

This test checks the new material route and the delayed fluid connection.
It supplies air and fuel, and it removes co-products. It does not measure an
entire factory or produce the starting machines.
