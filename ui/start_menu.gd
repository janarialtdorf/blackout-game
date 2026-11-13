class_name StartMenu
extends Control
## The title screen the game opens on. Start loads the first level.

## Where a new game begins. "Play again" and the tests use this too.
const FIRST_LEVEL := "res://levels/level_1.tscn"


func _ready() -> void:
	%Start.grab_focus() # so Enter / Space also press Start


func _on_start_pressed() -> void:
	SceneFader.change_scene(FIRST_LEVEL)
