# Contributing

How we work on this project as a team. The game idea is in `Game idea (1) (1).pdf`; the full technical conventions are in [`CLAUDE.md`](CLAUDE.md).

## 1. Setup (once)

1. Install **Godot 4.7.2** exactly. Mixed versions rewrite files and cause noisy diffs.
2. Clone the repo and open `project.godot` in Godot (**Import** in the project list).
3. Press **F5**. You should start in Level 1 with three heroes.
4. Run the tests once to check your setup (PowerShell, from the project folder):
   ```
   .\tools\run_tests.ps1
   ```
   If Godot is not at `C:\Program Files\Godot\Godot.exe.exe`, pass your path: `.\tools\run_tests.ps1 -Godot "D:\Godot\Godot.exe"`.

## 2. Daily workflow

1. `git switch main` and `git pull`.
2. Make a branch for one small task: `git switch -c feature/<short-name>` (or `fix/...`, `art/...`, `level/...`).
3. Do the work. Keep the branch short-lived: a day or two.
4. Run `.\tools\run_tests.ps1`. Everything must pass.
5. Commit, push, and open a **pull request** into `main`. One teammate looks at it and merges.

`main` must always be playable.

### Commit messages

We use [Conventional Commits](https://www.conventionalcommits.org): `<type>(<scope>): <summary>`, lowercase, no period.

```
feat(enemies): add exploding chaser
fix(vision): seer light no longer flickers at walls
art(heroes): add fighter sprite sheet
docs: explain how to add a level
```

Types: `feat`, `fix`, `refactor`, `art`, `docs`, `test`, `chore`.

## 3. Avoiding merge conflicts

Scene (`.tscn`) and resource (`.tres`) files merge badly. **Two people must not edit the same scene at the same time.**

- Before you start, say in the team chat which scenes you are editing ("I'm on `level_1.tscn`").
- Prefer many small scenes over one big one. The project is already split so that different roles touch different files (see the table below).
- Pull `main` into your branch often if it lives more than a day.
- If you do get a conflict in a `.tscn`, don't hand-merge it. Keep one side (`git checkout --theirs` / `--ours`), then redo the smaller change in the editor.

## 4. Where things live

| I want to… | Edit this | Code needed? |
|---|---|---|
| Change a hero's HP, speed, vision, weapon or ultimate | `heroes/<hero>/<hero>_stats.tres` | No |
| Change an enemy's HP, speed, sight, weapon | `enemies/<type>/<type>_stats.tres` | No |
| Change weapon damage, fire rate, spread, range | `weapons/*.tres` | No |
| Change how fast ultimates charge | `heroes/hero.tscn` → UltimateComponent | No |
| Paint or change a level | `levels/level_*.tscn` → **Tiles** node | No |
| Add a hero, enemy or weapon look (art) | the `*_visual.tscn` scenes | No |
| Restyle the HUD | `ui/hero_card.tscn`, `ui/hud.tscn`, `ui/boss_bar.tscn` | No |
| Change game behaviour | `components/`, `heroes/`, `enemies/`, `abilities/`, `levels/*.gd` | Yes |

Folders by feature: `components/` (reusable parts like health, weapon, vision), `heroes/`, `enemies/`, `weapons/`, `abilities/`, `levels/`, `ui/`, `resources/` (stats scripts), `tests/`, `tools/`.

## 5. Adding art

Nothing in the game uses image files yet; every look is a placeholder made of shapes. Each look is its own **Visual scene**, so art can be swapped without touching code:

1. Open the look you're replacing, e.g. `heroes/fighter/fighter_visual.tscn`.
2. Delete the `Placeholder...` nodes. The `AnimationPlayer` holds a placeholder red `hurt` flash; keep it or replace it.
3. Add an **AnimatedSprite2D** (or AnimationPlayer) as a child of the root `Visual` node.
4. Name the animations **`idle`, `walk`, `shoot`, `hurt`, `die`**. Any you leave out are simply skipped.
5. Untick **Loop** on `shoot`, `hurt` and `die`.
6. Draw characters **facing right**.

Other art slots:
- **Hero portraits:** `Portrait` in the hero's stats `.tres`.
- **Floor/wall tiles:** replace `levels/tiles/placeholder_tiles.png` (32×32 tiles: floor, then wall). Wall collision and vision blocking come from the tile set, so they keep working.
- **Ability effects:** scenes in `abilities/`. Draw at a 100 px radius (rings) or 100×100 px starting at the left edge (beams), play the animation, then call `queue_free()`.
- **Exit tile:** `levels/level_exit.tscn`.

Large source files (`.psd`, `.aseprite`, audio projects) don't go in this repo; only export the PNGs into the project. Do commit the `.import` files Godot creates next to them.

## 6. Adding content

- **New enemy type:** duplicate `enemies/chaser/` (stats `.tres`, visual, and the small scene that only sets `stats`). In the copies, point the scene's **Stats** at the new `.tres` and the `.tres`'s **Visual Scene** at the new visual, then change the numbers. No code.
- **New hero:** a new `HeroStats` `.tres` + visual scene, then add one more Hero child to `heroes/squad.tscn` and an Input Map action `switch_4`.
- **New level:** easiest is to duplicate a level scene and repaint it. Every level needs: the `Level` script on its root (set **Next Level**), a `Squad`, a `LevelExit`, a `LevelNavigation` node and a `Darkness` node. Put a Boss in it and the exit locks until the boss dies.

## 7. Tests

`.\tools\run_tests.ps1` runs every `tests/test_*.gd` file without opening a window. Each test prints `PASS`/`FAIL` lines.

- Tests load `levels/test_room.tscn` as a fixed layout. **Don't repaint the test room**; paint the real levels instead.
- New behaviour that has rules (damage, switching, unlocking) should get a check in the matching test file. Copy the style of the existing ones.

## 8. Pull request checklist

- [ ] One task per branch, named `feature/...`, `fix/...`, `art/...` or `level/...`
- [ ] `.\tools\run_tests.ps1` says **ALL PASSED**
- [ ] Played it with F5 at least once
- [ ] No files from `.godot/` committed
- [ ] Commit messages follow Conventional Commits
