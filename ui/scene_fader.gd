extends CanvasLayer
## Autoload "SceneFader" (Project Settings → Globals → Autoload). Every scene change goes through
## SceneFader.change_scene(): it fades to black, swaps the scene while the screen is black, and
## fades back in. An autoload lives above every scene, so it survives the change. It also fades the
## game in at launch.

## Seconds for each half of a fade (to black, and back).
const FADE_TIME := 0.5

var _busy := false

@onready var _black: ColorRect = $Black


func _ready() -> void:
	_black.color.a = 1.0
	_fade_to(0.0)


## Fades out, loads `path` (empty = restart the current scene) and fades back in.
func change_scene(path: String = "") -> void:
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
