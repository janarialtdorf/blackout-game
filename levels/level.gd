class_name Level
extends Node2D
## Root of every level. Runs the mission: a wiped squad fails it; reaching a LevelExit goes
## to next_level, or wins the game if there is none. While any enemy in the level is alive,
## the exits stay locked.
## Expects a child named "Squad".

const RESULT_SCREEN := preload("res://ui/result_screen.tscn")
const BOSS_BAR := preload("res://ui/boss_bar.tscn")
const OBJECTIVE_PANEL := preload("res://ui/objective_panel.tscn")
const GAME_OVER_SOUND := preload("res://assets/audio/game_over.wav")

## The level to load when the exit is reached. Empty = this is the last level.
@export_file("*.tscn") var next_level: String

var _exits: Array[LevelExit] = []
var _enemies_alive := 0
var _bosses_alive := 0
var _objective: ObjectivePanel


func _ready() -> void:
	VisionComponent.clear_effects() # every level starts with no ultimate effects active
	$Squad.wiped.connect(_on_squad_wiped)
	_exits.assign(find_children("*", "LevelExit"))
	for exit in _exits:
		exit.reached.connect(_on_exit_reached)
	for enemy: Enemy in find_children("*", "Enemy"):
		_enemies_alive += 1
		enemy.health.died.connect(_on_enemy_died.bind(enemy is Boss))
		if enemy is Boss:
			_bosses_alive += 1
			enemy.appeared.connect(_show_boss_bar.bind(enemy))
	_objective = OBJECTIVE_PANEL.instantiate()
	add_child(_objective)
	_update_exits()


func _show_boss_bar(boss: Boss) -> void:
	var bar: BossBar = BOSS_BAR.instantiate()
	add_child(bar)
	bar.show_boss(boss)


func _on_enemy_died(was_boss: bool) -> void:
	_enemies_alive -= 1
	if was_boss:
		_bosses_alive -= 1
	_update_exits()


func _update_exits() -> void:
	for exit in _exits:
		exit.locked = _enemies_alive > 0
	if _bosses_alive > 0:
		_objective.show_objective("Defeat the boss")
	elif _enemies_alive > 0:
		_objective.show_objective("Defeat all enemies")
	else:
		_objective.show_objective("Reach the exit")


func _on_squad_wiped() -> void:
	_show_result("Mission failed", "Retry", SceneFader.change_scene, GAME_OVER_SOUND)


func _on_exit_reached() -> void:
	if next_level:
		SceneFader.change_scene(next_level)
	else:
		_show_result("Mission complete!", "Play again", SceneFader.change_scene.bind(StartMenu.FIRST_LEVEL))


func _show_result(title: String, button_text: String, on_confirmed: Callable, sound: AudioStream = null) -> void:
	var screen: ResultScreen = RESULT_SCREEN.instantiate()
	add_child(screen)
	screen.show_result(title, button_text, sound)
	screen.confirmed.connect(on_confirmed)
	get_tree().paused = true
