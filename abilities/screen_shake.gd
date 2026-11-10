extends Node
## Shakes the current camera for a moment, fading out. Add it to an effect scene; it nudges the
## camera's offset (not its position), so the camera keeps following the hero.

## How far the view jumps at the start, in pixels.
@export var strength := 4.0
@export var duration := 0.25

var _camera: Camera2D
var _time_left := 0.0


func _ready() -> void:
	_camera = get_viewport().get_camera_2d()
	_time_left = duration


func _process(delta: float) -> void:
	_time_left = maxf(_time_left - delta, 0.0)
	if _camera:
		_camera.offset = Vector2.from_angle(randf() * TAU) * strength * _time_left / duration


# The effect may be freed mid-shake; never leave the view shifted.
func _exit_tree() -> void:
	if is_instance_valid(_camera):
		_camera.offset = Vector2.ZERO
