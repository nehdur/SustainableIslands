# SustainableIsland Tourism Council

A simple turn-based tourism management sim built for Godot 4.x, teaching the
trade-off between economic growth (SDG 8), responsible consumption (SDG 12),
marine ecosystems (SDG 14), and land ecosystems (SDG 15).

## How to open
1. Open Godot 4.x
2. Click "Import", select the `project.godot` file in this folder
3. Press F5 (or the Play button) to run — `scenes/Main.tscn` is set as the main scene

## How it plays
- You manage 5 zones: Hotel Site, Marine Reserve, Forest, Town Center, Waste Management
- Each zone has 2 decisions with different trade-offs between Economy,
  Employment, Environment, and Satisfaction
- You get 2 actions per season, across 8 seasons total
- Each season end, tourism pressure quietly erodes the Environment score —
  if you never reinvest in conservation, it'll show
- At the end, your average Prosperity (economy+employment) and Sustainability
  (environment+satisfaction) determine one of 4 endings

## Where to extend it
- **Add zones/decisions**: edit `autoloads/GameData.gd` — the UI reads this
  data automatically, no scene editing needed
- **Change balance**: tweak the delta values on each decision, or the season
  tick logic in `autoloads/GameState.gd` (`end_season()`)
- **Add art**: swap the zone Buttons in `scripts/Main.gd` for TextureButtons,
  or replace the flat background ColorRect with an island map sprite
- **Add more endings**: add entries to the `endings` dict in `GameData.gd`
  and extend the threshold logic in `GameState._end_game()`

## Known simplifications (v1 scope)
- No visual island map yet — zones are just buttons in a grid
- No save/load
- No art assets — everything is default Godot theme/UI
