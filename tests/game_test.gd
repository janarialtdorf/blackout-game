class_name GameTest
extends SceneTree
## Base for every tests/test_*.gd. A test overrides _run(); failures are counted and the
## process exits with code 1 if any check failed. Run one test:
##   Godot.exe --headless --path . --script res://tests/test_<name>.gd
## The test room: squad spawns at (176, 112); a wall column at x = 256..288 blocks rows 1-3.

const TEST_ROOM := "res://levels/test_room.tscn"
const CHASER := preload("res://enemies/chaser/chaser.tscn")
const SHOOTER := preload("res://enemies/shooter/shooter.tscn")

var _failures := 0


func _initialize() -> void:
	await _run()
	paused = false
	quit(1 if _failures else 0)


func _run() -> void:
	pass


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok:
		_failures += 1


## Loads a scene and waits until its nodes are ready. empty = free the enemies placed in it.
func load_scene(path: String, empty := false) -> Node:
	paused = false
	change_scene_to_file(path)
	await process_frame
	await process_frame
	if empty:
		for enemy in get_nodes_in_group(&"enemies"):
			enemy.free()
	return current_scene


func squad() -> Squad:
	return current_scene.get_node("Squad")


## Removes the AI teammates so a test only has to reason about the controlled hero.
func solo_hero() -> Hero:
	var team := squad()
	for hero in team.heroes:
		if hero != team.active:
			hero.free()
	team.heroes.assign([team.active])
	return team.active


## A sitting enemy (no AI) with lots of HP, so damage can be measured.
func spawn_target(at: Vector2, scene: PackedScene = CHASER) -> Enemy:
	var enemy := spawn_enemy(at, scene)
	enemy.set_physics_process(false)
	enemy.health.max_health = 1_000_000
	return enemy


func spawn_enemy(at: Vector2, scene: PackedScene = CHASER) -> Enemy:
	var enemy: Enemy = scene.instantiate()
	enemy.position = at
	current_scene.add_child(enemy)
	return enemy


func damage_taken(enemy: Enemy) -> int:
	return enemy.health.max_health - enemy.health.current


func wait(physics_frames: int) -> void:
	for i in physics_frames:
		await physics_frame


func count_projectiles() -> int:
	return current_scene.get_children().filter(func(node: Node) -> bool: return node is Projectile).size()


## The title of the result screen, or "" when none is shown.
func result_title() -> String:
	var screen := current_scene.find_child("ResultScreen", false, false)
	return screen.get_node("%Title").text if screen else ""


## Waits until a SceneFader transition (fade out, scene swap, fade back in) has finished.
func wait_for_fade() -> void:
	await create_timer(SceneFader.FADE_TIME * 2.0 + 0.2).timeout


func press_result_button() -> void:
	var screen := current_scene.find_child("ResultScreen", false, false)
	if screen:
		screen.get_node("%Button").pressed.emit()
	await wait_for_fade()


## Every real level, in play order, following next_level from the first level.
func level_chain() -> Array[String]:
	var chain: Array[String] = []
	var path: String = StartMenu.FIRST_LEVEL
	while path and path not in chain:
		chain.append(path)
		var level: Level = load(path).instantiate()
		path = ResourceUID.ensure_path(level.next_level) if level.next_level else ""
		level.free()
	return chain
