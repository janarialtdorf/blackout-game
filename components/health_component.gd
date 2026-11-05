class_name HealthComponent
extends Node
## Tracks hit points. Owners listen to the signals to react (flash, die, update HUD).

signal health_changed(current: int, maximum: int)
signal died

## Setting this (e.g. from a stats file) also refills current health.
@export var max_health: int = 100:
	set(value):
		max_health = value
		current = value

var current: int = max_health


## Returns the damage actually dealt (never more than the health that was left).
func take_damage(amount: int) -> int:
	var dealt := mini(amount, current)
	if dealt <= 0:
		return 0
	current -= dealt
	health_changed.emit(current, max_health)
	if current == 0:
		died.emit()
	return dealt
