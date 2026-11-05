# CLAUDE.md

Godot 4.7 project ("GameDevProject"). Scripts in GDScript.

## The game

- Single-player PvE top-down 2D shooter, prototype for a game design course (PC / browser). Spec: `Game idea (1) (1).pdf`.
- Bullet Echo darkness/limited vision + Marvel Future Fight 3-hero squads with tag-switching. Reference: Hotline Miami.
- Hook: switching hero changes what you can see, not just how you fight.
- Prototype scope (agreed):
  - Heroes: **Fighter** (wide short cone, shotgun, high HP), **Sniper** (long narrow cone, piercing slow shot, low HP), **Seer** (small circle that sees through walls, fast weak gun).
  - Switch with 1/2/3, shared 3 s cooldown. Switching does nothing else unless that hero's ultimate meter is full (no separate tag-in attacks — decided after playtesting).
  - Ultimates: one meter per hero, +0.5 %/s while alive, +1 % per 5 damage that hero deals. Switching to a hero with a full meter fires its ultimate (Fighter 100-dmg shockwave, Sniper 150-dmg aimed piercing beam through walls, Seer 8 s team wall-sight + reveal). Ultimate effects are gold.
  - Inactive heroes are AI: follow, path around walls, shoot nearest visible enemy.
  - Enemies outside vision are invisible; walls block vision (except Seer). Enemies idle until they see a hero or get hit.
  - Enemies: melee chaser, ranged shooter, boss (aimed 3-burst + 12-bullet ring). No friendly fire.
  - Dead heroes stay dead for the level; all dead = restart level. Level 1 → Level 2 (boss room, exit opens on boss death → win screen).
  - Out of scope for now: loot, team select, upgrades, shop, PvP, mobile, sound.
- The developer is a beginner with game engines: explain new Godot concepts briefly the first time they appear.

## Build plan (one step at a time, test + "commit" between)

1. ✅ Setup + one hero walking · 2. ✅ Shooting · 3. ✅ Health + target dummy · 4. ✅ Enemies (chaser, shooter, sight check) · 5. ✅ Darkness + vision · 6. ✅ Squad + switching + AI teammates · 7. ✅ Tag-ins + ultimates · 8. ✅ HUD (HP + ult bars, swap cooldown) · 9. ✅ Death, fail/restart, exit · 10. ✅ Level 1 + 2 layouts · 11. ✅ Boss + win screen

## Art is swappable (no assets yet)

- Every hero/enemy/projectile look is a separate **Visual** scene (root uses `components/visual.gd`), referenced from its stats `.tres` (`visual_scene`). Reskin = make a new Visual scene, point the `.tres` at it.
- Gameplay only calls `visual.play("idle"|"walk"|"shoot"|"hurt"|"die")`; missing animations are ignored. Art faces right (+X).
- Levels are TileMapLayers using `levels/tiles/tile_set.tres` (collision on the wall tile). Replace the placeholder texture to reskin.
- Every level's root uses `levels/level.gd` (`Level`, with `next_level`), has a child named `Squad`, and at least one `LevelExit` (`levels/level_exit.tscn`). The Level shows `ui/result_screen.tscn` (pauses the game) on a wipe or on the last level's exit. Text-map letters → scenes are in `PLACE` in `tools/build_levels.gd`.
- Every level needs a `Darkness` node (CanvasModulate + `levels/darkness.gd`, saved hidden so the editor stays bright). Vision = `VisionComponent` (a PointLight2D that generates its own cone texture from `HeroStats` vision numbers); nodes in group `hidden_in_dark` are hidden when the active hero can't see them. Wall tiles carry a light occluder (cull mode counter-clockwise so wall faces get lit).
- Visual check: `Godot.exe --path . --script res://tests/screenshot.gd -- <out.png> [hero_rotation]` (not headless) saves a frame of the main scene.
- Every level needs a `LevelNavigation` node (`levels/level_navigation.gd`, `tiles` → the TileMapLayer). It bakes the walkable area from the walls at load, so repainting never breaks pathfinding. Don't put navigation polygons on tiles: they hug walls and agents snag on corners.
- The player's team is `heroes/squad.tscn` (its Hero children, in key order, each with a `HeroStats`). Levels place one Squad at the spawn. `Hero.controlled` switches between player input and AI teammate; only the controlled hero's VisionComponent is active. Tests use `GameTest.solo_hero()` to remove the AI teammates.
- NavigationAgent2D `path_desired_distance` must stay below `LevelNavigation.agent_radius` (4 vs 14), or agents cut corners into walls.
- Wall checks go through `LineOfSight.is_clear()`.
- HUD (`ui/hud.tscn`) lives inside `squad.tscn`; the Squad calls `show_squad()` / `set_active()`. Each `HeroCard` only listens to hero signals. Reskin UI via the StyleBoxes in `ui/hero_card.tscn` (or a Theme); `HeroStats.portrait` shows a picture when set.
- Ultimates are `Ability` resources (`abilities/`: `BlastAbility`, `BeamAbility` (instant line hit, optional through walls), `RevealAbility`) stored as sub-resources in each hero's stats `.tres`. New ability type = new `Ability` subclass with `_apply(hero)`. Optional `effect_scene` is authored at 100 px radius and must free itself. Meter = `UltimateComponent` (numbers on it in `hero.tscn`); damage is credited via `WeaponComponent.damage_dealt`. Ultimate damage does not recharge the meter.
- Boss = `enemies/boss/boss.tscn` (inherits `enemy.tscn`; `Boss extends Enemy` and only overrides `_attack()`). A level's exits stay locked while any `Boss` in it is alive. The last level's exit shows "Mission complete!" → Play again loads the main scene. `Boss.appeared` (first seen, or first notices a hero) makes the Level show `ui/boss_bar.tscn` (name from `EnemyStats.display_name`). Enemies start hidden until seen.
- Enemy types = `enemies/enemy.tscn` + an `EnemyStats` `.tres`; the type scene (e.g. `enemies/chaser/chaser.tscn`) only sets `stats`. Melee is a short-range weapon.
- Level layouts are text maps in `levels/maps/*.txt`, turned into `levels/*.tscn` by `tools/build_levels.gd` (see its header for the run command). It overwrites the scene, so once a level is hand-edited in the editor, delete its `.txt`.

## Setup

- Godot 4.7.2: `C:\Program Files\Godot\Godot.exe.exe` (headless check: `--headless --path . --quit-after 120`; tests: `--headless --path . --script res://tests/<test>.gd`, run `--import` first when adding a `class_name`)
- Renderer: Compatibility (needed for web export)
- 3D physics: Jolt (game is 2D, so this is unused for now)
- Window stretch: `canvas_items` / `expand`
- Main scene: `levels/level_1.tscn` → `level_2.tscn` → `level_3.tscn`. `levels/test_room.tscn` (hand-painted) is only used by the tests.
- Run all tests: `.\tools\run_tests.ps1` (re-imports, runs every `tests/test_*.gd`, kills hangs). Every test `extends GameTest` (`tests/game_test.gd`: `check()`, `load_scene()`, spawn helpers) and overrides `_run()`.
- Physics layers: 1 `walls`, 2 `heroes`, 3 `enemies`, 4 `hero_hurtbox`, 5 `enemy_hurtbox`. Bullets stop at whatever is in their weapon's `hit_mask` (walls + the target's hurtbox layer).

## How we work: one small feature at a time

Treat every feature like a feature branch.

1. **Agree the step.** Before writing code, state the one feature you're about to build in 1–3 lines (what it does, which files/scenes it touches). Keep it small enough to test in a few minutes.
2. **Build only that.** No extra features, no "while I'm here" refactors outside the step.
3. **Say how to test it.** Tell me exactly what to run or click in the editor and what I should see.
4. **Stop and ask.** End the step with a short summary and ask before starting the next feature. Suggest what the next step could be, but don't start it.
5. If the project uses git, suggest a branch name per feature (`feature/player-movement`) and a commit message when the step is done. Commit only when I say "commit".

**Commit messages follow [Conventional Commits](https://www.conventionalcommits.org):** `<type>(<optional scope>): <imperative summary>`, lowercase, no period, ≤ 72 chars. Types: `feat`, `fix`, `refactor`, `art`, `docs`, `chore`, `test`, `style`, `perf`. Team workflow for humans is in `CONTRIBUTING.md`. Optional body explains *why*. Example: `feat(weapons): add shotgun weapon component and projectile`.

## Code principles

**Simplest code that works.**

- Fewest lines and fewest nodes that do the job. No speculative features, options or abstractions.
- Prefer built-in Godot nodes and functions over custom code (`CharacterBody2D.move_and_slide()`, `Area2D` for hits, `Timer` for cooldowns, `Input.get_vector()` for movement).
- Short functions with clear names. Comment only the _why_, not the _what_.

**Every line reusable.**

- Write code once and reuse it; don't copy-paste logic between heroes, enemies or weapons.
- **Composition over inheritance.** Build behavior from small, single-purpose component scenes attached as child nodes, e.g. `HealthComponent`, `HitboxComponent` / `HurtboxComponent`, `WeaponComponent`. A hero is a scene that combines components.
- **Data in Resources, not code.** Hero and weapon numbers (speed, max health, damage, fire rate) live in custom `Resource` files (`HeroStats.tres`, `WeaponStats.tres`) with `@export` fields. A new hero should mostly be a new `.tres` + scene, not new code.
- **Components don't know who owns them.** Use `@export` for anything a component needs instead of hardcoded paths like `get_parent().get_parent()`.
- Use `class_name` on reusable scripts so they're typed and easy to find.
- Extract shared code the second time it's needed, not before.

**Conventional Godot structure.**

- **Call down, signal up.** Parents call methods on children; children emit signals to tell parents something happened (`health_changed`, `died`). Siblings don't reach into each other.
- Each scene works on its own: open it, press F6, it runs without errors.
- Autoloads (singletons) only for truly global things (e.g. game state, events bus). Not for convenience.
- Input through the Input Map (`move_left`, `shoot`, …), never hardcoded keys.
- Use physics layers/masks by name (set in Project Settings → Layer Names), e.g. `player`, `enemy`, `walls`, `projectiles`.

## Conventions

- Use Godot 4 syntax only (`@export`, `@onready`, typed GDScript, `signal.connect(callable)`), not Godot 3.
- Type everything: `var speed: float = 200.0`, `func take_damage(amount: int) -> void:`.
- Naming: `snake_case` for files, folders, variables and functions; `PascalCase` for node names and `class_name`; `UPPER_CASE` for constants.
- Folder layout by feature, scene and script side by side:
  ```
  res://
    components/   health_component.tscn + .gd, hitbox_component..., weapon_component...
    heroes/       hero.tscn (base), <hero_name>/ with its stats .tres and art
    weapons/      projectile.tscn, weapon stats .tres
    levels/       arenas
    ui/           HUD, menus
    resources/    custom Resource scripts (hero_stats.gd, weapon_stats.gd)
  ```
- Prefer editing scenes/settings in the editor; hand-edit `.tscn` / `project.godot` only for small, well-understood changes. When something must be done in the editor, give me the steps.
- Never edit or commit `.godot/` (editor cache, regenerated on open) or `*.import` internals by hand.
- Resource paths use `res://`.
