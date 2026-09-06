# Water quenching

```yaml
given:
  surface: nullius-vulcanus
  research: hot-metalworking prerequisite closure, then water-quenching
  bulk_unlock: mass-production-4
  blooms: 4 dry, 4 quenched, 20 bulk, 4 outage, 4 restart
  water: 2 quenched, 10 bulk, 2 restart
  debug_heat: four heat interfaces at 250 C
  inserter_fuel: 200 compressed volcanic gas per inserter
place:
  foundries: four foundry-1-thermal entities
  logistics: two pneumatic inserters and two iron chests
connect:
  water: one adjacent pipe per foundry
  heat: one heat pipe from each interface to its foundry
  outage_output: foundry -> inserter -> chest
  restart_input: chest -> inserter -> foundry
act:
  start: insert declared blooms; fill only the wet and bulk water pipes
  outage_end_tick: 2100
  restart: put four fresh blooms in the source chest and two water in the pipe
run:
  first_cycle_check: 240
  spoilage_check: 2100
  terminal_check: 3000
  runner_deadline: 3060
expect:
  dry: three plates from four blooms
  quenched: four plates from four blooms and two water
  bulk: four five-plate boxes from twenty blooms and ten water
  outage: zero crafts; four cooled iron ingots in the output chest
  restart: one craft; four plates and four recovered ingots in the output chest
  scripted_inventory_clearing: none
```

The fixture supplies heat, fuel, blooms, water, and placed equipment. It tests
casting and automatic recovery. It does not measure full-factory supply time.
The planner comparison includes the local water, fuel, and waste-processing
routes and the construction flow for a copy of this cell's equipment.
