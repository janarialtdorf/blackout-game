class_name KnockbackComponent
extends Node
## A push that slows to a stop. The owner adds step() to its movement every physics frame.

## How fast a push slows down, in px/s².
const DECELERATION := 2000.0

var _velocity := Vector2.ZERO


## The push speed that slides `distance` pixels before stopping.
static func speed_for(distance: float) -> float:
	# Moving in physics steps adds half a step of travel; solving for it makes the distance exact.
	var half_step := 0.5 / Engine.physics_ticks_per_second
	return DECELERATION * (sqrt(half_step * half_step + 2.0 * distance / DECELERATION) - half_step)


func push(velocity: Vector2) -> void:
	_velocity = velocity


func is_active() -> bool:
	return _velocity != Vector2.ZERO


## This frame's push velocity (zero when there is none).
func step(delta: float) -> Vector2:
	var current := _velocity
	_velocity = _velocity.move_toward(Vector2.ZERO, DECELERATION * delta)
	return current
