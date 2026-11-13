class_name Level
extends Node2D
## Root of every level. Runs the mission: a wiped squad fails it; reaching a LevelExit goes
## to next_level, or wins the game if there is none. While any Boss in the level is alive,
## the exits stay locked.
## Expects a child named "Squad".

const RESULT_SCREEN := preload("res://ui/result_screen.tscn")
const BOSS_BAR := preload("res://ui/boss_bar.tscn")
const OBJECTIVE_PANEL := preload("res://ui/objective_panel.tscn")

## The level to load when the exit is reached. Empty = this is the last level.
@export_file("*.tscn") var next_level: String

var _exits: Array[LevelExit] = []
var _bosses_alive := 0
var _objective: ObjectivePanel


func _ready() -> void:
	$Squad.wiped.connect(_on_squad_wiped)
	_exits.assign(find_children("*", "LevelExit"))
	for exit in _exits:
		exit.reached.connect(_on_exit_reached)
	for boss: Boss in find_children("*", "Boss"):
		_bosses_alive += 1
		boss.health.died.connect(_on_boss_died)
		boss.appeared.connect(_show_boss_bar.bind(boss))
	_objective = OBJECTIVE_PANEL.instantiate()
	add_child(_objective)
	_set_exits_locked(_bosses_alive > 0)


func _show_boss_bar(boss: Boss) -> void:
	var bar: BossBar = BOSS_BAR.instantiate()
	add_child(bar)
	bar.show_boss(boss)


func _on_boss_died() -> void:
	_bosses_alive -= 1
	_set_exits_locked(_bosses_alive > 0)


func _set_exits_locked(locked: bool) -> void:
	for exit in _exits:
		exit.locked = locked
	_objective.show_objective("Defeat the boss" if locked else "Reach the exit")


func _on_squad_wiped() -> void:
	_show_result("Mission failed", "Retry", SceneFader.change_scene)


func _on_exit_reached() -> void:
	if next_level:
		SceneFader.change_scene(next_level)
	else:
		_show_result("Mission complete!", "Play again", SceneFader.change_scene.bind(StartMenu.FIRST_LEVEL))


func _show_result(title: String, button_text: String, on_confirmed: Callable) -> void:
	var screen: ResultScreen = RESULT_SCREEN.instantiate()
	add_child(screen)
	screen.show_result(title, button_text)
	screen.confirmed.connect(on_confirmed)
	get_tree().paused = true
