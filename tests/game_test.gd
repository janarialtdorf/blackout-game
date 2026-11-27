class_name GameTest
extends Node
## Base for every tests/test_*.gd. A test overrides _run(); failures are counted and the
## process exits with code 1 if any check failed. Tests run inside the real game via
## tools/run.tscn, so autoloads and everything else work as when playing. Run one test:
##   Godot.exe --headless --path . res://tools/run.tscn -- res://tests/test_<name>.gd
## The test room: squad spawns at (176, 112); a wall column at x = 256..288 blocks rows 1-3.

const TEST_ROOM := "res://levels/test_room.tscn"
const CHASER := preload("res://enemies/chaser/chaser.tscn")
const SHOOTER := preload("res://enemies/shooter/shooter.tscn")

# The game tree's members under their own names, so tests can write `current_scene` or
# `await physics_frame` instead of `get_tree().current_scene`.
var current_scene: Node:
	get: return get_tree().current_scene
var paused: bool:
	get: return get_tree().paused
	set(value): get_tree().paused = value
var root: Window:
	get: return get_tree().root
var physics_frame: Signal:
	get: return get_tree().physics_frame
var process_frame: Signal:
	get: return get_tree().process_frame

var _failures := 0


func _ready() -> void:
	Level.intros_enabled = false # loading a level would otherwise stop on its intro
	await _run()
	paused = false
	current_scene.queue_free() # stops playing sounds, which would otherwise leak at exit
	SceneFader.get_node(^"Music").stop() # the soundtrack lives in the autoload, not the scene
	await create_timer(0.5).timeout # shortcut: timed wait for the audio thread to drop stopped sounds (0.1 s was too short), raise it if "resources still in use" returns
	get_tree().quit(1 if _failures else 0)


func get_nodes_in_group(group: StringName) -> Array[Node]:
	return get_tree().get_nodes_in_group(group)


func create_timer(seconds: float) -> SceneTreeTimer:
	return get_tree().create_timer(seconds)


func _run() -> void:
	pass


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok:
		_failures += 1


## Loads a scene and waits until its nodes are ready. empty = free the enemies placed in it.
func load_scene(path: String, empty := false) -> Node:
	paused = false
	get_tree().change_scene_to_file(path)
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


## A hero bullet (it hits walls + enemy hurtboxes) flying from `at` toward `angle`.
func spawn_bullet(at: Vector2, angle: float, damage: int, max_distance: float, pierces := false) -> Projectile:
	var bullet: Projectile = preload("res://weapons/projectile.tscn").instantiate()
	bullet.position = at
	bullet.rotation = angle
	bullet.speed = 700.0
	bullet.max_distance = max_distance
	bullet.damage = damage
	bullet.hit_mask = 1 | 16 # walls + enemy_hurtbox
	bullet.pierces = pierces
	current_scene.add_child(bullet)
	return bullet


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


## Collects every objective in the current level, as if the hero had picked them all up.
func complete_objectives() -> void:
	for item: Collectible in current_scene.find_children("*", "Collectible"):
		if not item.is_collected:
			item._collect()


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
