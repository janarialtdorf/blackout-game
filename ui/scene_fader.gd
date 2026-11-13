class_name SceneFader
extends CanvasLayer
## Every scene change goes through SceneFader.change_scene(): it fades to black, swaps the scene
## while the screen is black, and fades back in. The black overlay is created on first use and kept
## on the tree's root, above every scene, so it survives scene changes.

## Seconds for each half of a fade (to black, and back).
const FADE_TIME := 0.5

var _busy := false

@onready var _black: ColorRect = $Black


## Fades out, loads `path` (empty = restart the current scene) and fades back in.
static func change_scene(path: String = "") -> void:
	var root := (Engine.get_main_loop() as SceneTree).root
	var fader: SceneFader = root.get_node_or_null(^"SceneFader")
	if not fader:
		fader = load("res://ui/scene_fader.tscn").instantiate()
		root.add_child(fader)
	fader._fade_through_black(path)


func _fade_through_black(path: String) -> void:
	if _busy: # e.g. an exit touched twice during the fade
		return
	_busy = true
	_black.mouse_filter = Control.MOUSE_FILTER_STOP # no clicks while the old scene fades away
	get_tree().paused = true # the game freezes while it fades out
	await _fade_to(1.0)
	if path:
		get_tree().change_scene_to_file(path)
	else:
		get_tree().reload_current_scene()
	get_tree().paused = false
	await _fade_to(0.0)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


func _fade_to(alpha: float) -> void:
	await create_tween().tween_property(_black, ^"color:a", alpha, FADE_TIME).finished
