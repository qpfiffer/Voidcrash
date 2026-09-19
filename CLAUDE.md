# voidcrash

Text-mode LÖVE 11.5 game. Lua 5.1 (this machine's love is *not* LuaJIT; `luajit` is only used for tooling).

## Commands

- Run: `love .`
- Tests (headless, pure-Lua modules only): `luajit tests/run.lua`
- Stray-global lint (must stay clean): `tools/lint_globals.sh`
- Measure / drive without a keyboard:
  `VOIDCRASH_STATS=1 VOIDCRASH_STRICT=1 VOIDCRASH_EXIT_AFTER=20 VOIDCRASH_KEYS="return,space,space,-,shot:map" VOIDCRASH_SHOT_DIR=/tmp love .`
  (see `src/DebugStats.lua`: `-` waits, `hold:key`/`release:key`, `shot:name`; F3 toggles stats in game)

## Architecture

- `src/Clock.lua` is the only place `dt` enters. `clock.ui` never pauses; `clock.sim` advances in fixed
  steps and is frozen by pause. Use `timeline:after/every` (period may be a function) — never accumulate
  dt by hand. All tuning in `src/Constants.lua` is per second.
- `src/ecs/World.lua` is the simulation: entities are ids, components are plain data
  (`src/ecs/components.lua`), kinds of thing are prefabs (`src/ecs/prefabs.lua`), behaviour is systems
  (`src/ecs/systems/`). An entity is in the world (`Position`) or inside something (`InCargo`), never
  both; only `src/ecs/containment.lua` switches them. The UI changes the world only through
  `src/sim/commands.lua`, and hears about it through world events (`world:on`).
- Components that mean "needs simulating" (`Orders`, `Movement`) exist only while there is work. When no
  system matches anything the clock stops stepping and the game sleeps. Don't add always-on systems.
- Screens (`src/states/`, base `src/Screen.lua`) are views. They have no `update`; they own timer scopes
  that are suspended while hidden. Nothing is redrawn unless invalidated (key events, ui timers, blink,
  sim movement, `game_state:invalidate()`), so anything that changes on its own needs a timer.
- `main.lua` has a custom `love.run`: advance clock → draw if dirty → sleep until `clock:next_wake()`.
- `src/ecs`, `src/sim`, `src/Clock.lua` must stay free of `love.*` so they run under plain `luajit`.

## Conventions

- `require("src/...")` with slashes, always (dots would load a second copy of the module).
- Glyphs go through `renderer:draw_glyph/draw_string`; call `renderer:flush()` before raw `love.graphics`
  drawing or transforms.
