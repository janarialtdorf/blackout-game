# CLAUDE.md

Godot 4.7 project ("GameDevProject"). Scripts in GDScript.

## The game

- Single-player PvE top-down 2D shooter, prototype for a game design course (PC / browser). Spec: `Game idea (1) (1).pdf`.
- Bullet Echo darkness/limited vision + Marvel Future Fight 3-hero squads with tag-switching. Reference: Hotline Miami.
- Hook: switching hero changes what you can see, not just how you fight.
- Prototype scope (agreed):
  - Heroes: **Fighter** (wide short cone, shotgun, high HP), **Sniper** (long narrow cone, piercing slow shot, low HP), **Seer** (small circle that sees through walls, fast weak gun).
  - Switch with 1/2/3, shared 3 s cooldown. Switching does nothing else unless that hero's ultimate meter is full (no separate tag-in attacks — decided after playtesting).
  - Ultimates: one meter per hero, +0.5 %/s while alive, +1 % per 5 damage that hero deals. Switching to a hero with a full meter fires its ultimate (Fighter dashes 300 px toward the aim over 0.5 s, then a 100-dmg shockwave where it stops, Sniper 150-dmg aimed piercing beam through walls, Seer 8 s team wall-sight + reveal). Ultimate effects are gold.
  - Inactive heroes are AI: follow, path around walls, shoot nearest visible enemy.
  - Enemies outside vision are invisible; walls block vision (except Seer). Enemies idle until they see a hero or get hit.
  - Enemies: melee chaser, ranged shooter, boss (aimed 3-burst + 12-bullet ring). No friendly fire.
  - Dead heroes stay dead for the level; all dead = restart level. Level 1 → Level 2 (boss room, exit opens on boss death → win screen).
  - Out of scope for now: loot, team select, upgrades, shop, PvP, mobile, sound.
- The developer is a beginner with game engines: explain new Godot concepts briefly the first time they appear.

## Build plan (one step at a time, test + "commit" between)

1. ✅ Setup + one hero walking · 2. ✅ Shooting · 3. ✅ Health + target dummy · 4. ✅ Enemies (chaser, shooter, sight check) · 5. ✅ Darkness + vision · 6. ✅ Squad + switching + AI teammates · 7. ✅ Tag-ins + ultimates · 8. ✅ HUD (HP + ult bars, swap cooldown) · 9. ✅ Death, fail/restart, exit · 10. ✅ Level 1 + 2 layouts · 11. ✅ Boss + win screen

## Art direction (agar.io-style, everything drawn in Godot)

Reference: `docs/mockup.png` (rough Paint mockup of a boss fight: look at it before visual work). `docs/` has a `.gdignore`, so Godot doesn't import it.

- **No image files.** Everything is drawn by Godot: `_draw()` (`draw_circle`, `draw_arc`, `draw_line`, `draw_rect`), `Polygon2D`, `Line2D`, StyleBoxFlat. Don't add PNG/SVG art or AnimatedSprite2D unless I ask. Exceptions so far: the ultimate effects are 8-frame AnimatedSprite2Ds drawn at their in-game size, so they show 1:1: Sniper beam `abilities/ultimate_beam_effect.tscn` from `assets/sniperUlt/` (650×56 px = beam length × width) , Fighter shockwave `abilities/ultimate_ring_effect.tscn` from `assets/fighterUlt/` (440×440 px = 2 × blast radius, centred) and Seer reveal `abilities/ultimate_reveal_effect.tscn` from `assets/seerUlt/` (1152×648 px = the game window, centred on the Seer, which is at screen centre after a switch). Each ultimate effect also contains `abilities/screen_flash.tscn` (CanvasLayer 2, above the HUD), which tints the whole screen 30% and fades over 0.4 s: Fighter red, Sniper light blue, Seer yellow (its `color` is set on the instance). Fighter and Sniper effects also contain `abilities/screen_shake.tscn`: a subtle camera shake (4 px fading over 0.25 s, via `Camera2D.offset` so following is untouched). The scenes are authored at 100 px and the abilities scale them back up. The start menu uses hand-drawn images from `assets/startMenu/`: `start_menu.png` background (TextureRect, keep-aspect-covered) and a TextureButton with `start1.png` (normal) / `start2.png` (hover, pressed), both cropped to the button box with an AtlasTexture region.
- **Look:** simple, flat, readable, like agar.io. Solid colours, no gradients, textures, or detailed shading. Gameplay readability beats decoration.
- **Characters**: heroes and the boss are circles, chasers and shooters are triangles pointing where they face. A solid fill plus an outline ~3 px in a *darker shade of the same colour* (`color.darkened(0.35)`), not black. Facing = a short dark gun barrel (a small rectangle) sticking out on +X; the chaser (melee) has no barrel. Heroes radius ~12 px; the boss is much bigger (30 px, matching its hurtbox). Make circles smooth (enough points or `draw_circle`), not visibly polygonal. All drawn by `components/body_drawing.gd` (`BodyDrawing`, a `Body` child of each Visual scene).
- **Colours:** each hero has one identity colour used for its body, bullets and HUD accents: Fighter orange, Sniper green, Seer blue. Enemies are red, the boss red with a dark red outline. Ultimate effects are gold. Keep them saturated and easy to tell apart on grey.
- **Bullets:** small plain circles (~3 px radius) in the shooter's colour. Enemy bullets red.
- **Level:** mid-grey floor, walls drawn as thick black outlines (or dark-grey blocks with black edges). The area inside the active hero's vision is bright (near white). Outside vision the level stays visible but dim grey, never pitch black; only enemies are hidden.
- **HUD** (top-left): one card per hero with white background, thick black rounded outline (~3 px, corner radius ~10), name and key number ("1 Fighter"), red HP bar, blue ultimate bar. The active hero's card has a yellow outline. Under the cards, a rounded box with the switch cooldown as a big white number and a "switch cooldown" label. Boss bar: wide red bar top-centre with the boss name above it. Objective panel: white box top-right with bold "OBJECTIVE" and the current goal.
- **Feedback stays simple:** hurt = quick flash to off-white (`BodyDrawing.flash`; red would vanish on red enemies), death = shrink/fade (enemies vanish, dead heroes stay small and grey), switch-in = "land" drop (hero starts 1.5× and see-through, squashes and settles in 0.26 s; "hurt" resets scale/modulate so a hit mid-drop can’t leave it stuck); all live in `enemies/enemy_animations.tres` and `heroes/hero_animations.tres`, ultimates = fading coloured rings/lines like `abilities/ring_effect.gd`. No particles unless I ask; screen shake only the subtle ultimate one.
- **Implementation:** Visual scenes stay the swap point. Draw characters with one shared, reusable script (`@export` colour and radius) instead of per-hero drawing code; hero/enemy colour can live in their stats `.tres`. HUD styling goes through StyleBoxFlat / a Theme, not custom drawing.

## Architecture (art is swappable)

- Every hero/enemy/projectile look is a separate **Visual** scene (root uses `components/visual.gd`), referenced from its stats `.tres` (`visual_scene`). Reskin = make a new Visual scene, point the `.tres` at it.
- Gameplay only calls `visual.play("idle"|"walk"|"shoot"|"hurt"|"die")`; missing animations are ignored. Art faces right (+X).
- Levels are TileMapLayers using `levels/tiles/tile_set.tres` (collision + light occluder on the wall tile). The tile texture is invisible; the `Tiles` node’s script `levels/level_drawing.gd` (`LevelDrawing extends TileMapLayer`, @tool) draws the floor and the black wall outlines and redraws via `_update_cells()` while you paint (the `changed` signal does not fire on painting in 4.7). Reskin the level there.
- Every level's root uses `levels/level.gd` (`Level`, with `next_level`), has a child named `Squad`, and at least one `LevelExit` (`levels/level_exit.tscn`). The Level shows `ui/result_screen.tscn` (pauses the game) on a wipe or on the last level's exit. Text-map letters → scenes are in `PLACE` in `tools/build_levels.gd`.
- Every level needs a `Darkness` node (CanvasModulate + `levels/darkness.gd`, saved hidden so the editor stays bright). Vision = `VisionComponent` (a PointLight2D that generates its own cone texture from `HeroStats` vision numbers); nodes in group `hidden_in_dark` are hidden when the active hero can't see them. Wall tiles carry a light occluder (cull mode disabled, so light stops at the wall line). Darkness is 50% grey and VisionComponent energy 0.5, so lit things show their true colours.
- Visual check: `Godot.exe --path . --script res://tests/screenshot.gd -- <out.png> [hero_rotation]` (not headless) saves a frame of the main scene.
- Every level needs a `LevelNavigation` node (`levels/level_navigation.gd`, `tiles` → the TileMapLayer). It bakes the walkable area from the walls at load, so repainting never breaks pathfinding. Don't put navigation polygons on tiles: they hug walls and agents snag on corners.
- The player's team is `heroes/squad.tscn` (its Hero children, in key order, each with a `HeroStats`). Levels place one Squad at the spawn. `Hero.controlled` switches between player input and AI teammate; only the controlled hero's VisionComponent is active. Tests use `GameTest.solo_hero()` to remove the AI teammates.
- NavigationAgent2D `path_desired_distance` must stay below `LevelNavigation.agent_radius` (4 vs 14), or agents cut corners into walls.
- Wall checks go through `LineOfSight.is_clear()`.
- HUD (`ui/hud.tscn`) lives inside `squad.tscn`; the Squad calls `show_squad()` / `set_active()`. Each `HeroCard` only listens to hero signals. Reskin UI via the StyleBoxes in `ui/hero_card.tscn` and `ui/hud.tscn`; the white card/panel look is shared in `ui/white_panel.tres`. The Level adds `ui/objective_panel.tscn` (top-right): "Defeat the boss" while a boss lives, else "Reach the exit".; `HeroStats.portrait` shows a picture when set.
- Ultimates are `Ability` resources (`abilities/`: `BlastAbility`, `BeamAbility` (instant line hit, optional through walls), `RevealAbility`) stored as sub-resources in each hero's stats `.tres`. New ability type = new `Ability` subclass with `_apply(hero)`. Optional `effect_scene` is authored at 100 px radius and must free itself. Meter = `UltimateComponent` (numbers on it in `hero.tscn`); damage is credited via `WeaponComponent.damage_dealt`. The meter is emptied when the ultimate starts and ultimates never credit their own damage, so it does not recharge the meter. `BlastAbility.leap`/`leap_time` make the hero `dash()` first (`Hero.dash()` ignores input, ends early at a wall or body; the blast and its effect happen where it ends, none if the hero died). Pushes (Fighter blast on enemies, Sniper `recoil` on the hero) go through `KnockbackComponent` (`components/knockback_component.gd`, on every hero and enemy): a speed that slows to a stop, moved with `move_and_slide()` so it never passes walls; `speed_for(distance)` gives the exact push for a distance. Enemies are steered by it while pushed; heroes add it to their own movement.
- Boss = `enemies/boss/boss.tscn` (inherits `enemy.tscn`; `Boss extends Enemy` and only overrides `_attack()`). A level's exits stay locked while any `Boss` in it is alive. The last level's exit shows "Mission complete!" → Play again loads the main scene. `Boss.appeared` (first seen, or first notices a hero) makes the Level show `ui/boss_bar.tscn` (name from `EnemyStats.display_name`). Enemies start hidden until seen.
- Enemy types = `enemies/enemy.tscn` + an `EnemyStats` `.tres`; the type scene (e.g. `enemies/chaser/chaser.tscn`) only sets `stats`. Melee is a short-range weapon.
- Level layouts are text maps in `levels/maps/*.txt`, turned into `levels/*.tscn` by `tools/build_levels.gd` (see its header for the run command). It overwrites the scene, so once a level is hand-edited in the editor, delete its `.txt`.

## Setup

- Godot 4.7.2: `C:\Program Files\Godot\Godot.exe.exe` (headless check: `--headless --path . --quit-after 120`; tests: `--headless --path . --script res://tests/<test>.gd`, run `--import` first when adding a `class_name`)
- Renderer: Compatibility (needed for web export)
- 3D physics: Jolt (game is 2D, so this is unused for now)
- Window stretch: `canvas_items` / `expand`
- Main scene: `ui/start_menu.tscn` (`StartMenu`; its Start button loads `StartMenu.FIRST_LEVEL`) → `levels/level_1.tscn` → `level_2.tscn` → `level_3.tscn`. "Play again", the tests and `screenshot.gd` start from `StartMenu.FIRST_LEVEL`, not the main scene. Every in-game scene change goes through `SceneFader.change_scene(path)` (`ui/scene_fader.gd`, a static call, not an autoload: tests run with `--script`, which loads no autoloads). It freezes the game, fades to black over `FADE_TIME` (0.3 s), swaps the scene (empty path = reload), unfreezes and fades back in; its overlay lives on the root at layer 100. Tests wait with `GameTest.wait_for_fade()`. `levels/test_room.tscn` (hand-painted) is only used by the tests.
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
