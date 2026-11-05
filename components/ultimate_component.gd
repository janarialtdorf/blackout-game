class_name UltimateComponent
extends Node
## A hero's ultimate meter (0-100 %). Fills over time and from damage the hero deals.

signal charge_changed(charge: float)

## Percent gained per second while the hero is alive.
@export var passive_per_second: float = 0.5
## Percent gained per point of damage dealt (0.2 = 1 % per 5 damage).
@export var per_damage: float = 0.2

var charge: float = 0.0


func _process(delta: float) -> void:
	_add(passive_per_second * delta)


func add_damage(amount: int) -> void:
	_add(amount * per_damage)


func is_full() -> bool:
	return charge >= 100.0


func consume() -> void:
	charge = 0.0
	charge_changed.emit(charge)


func _add(amount: float) -> void:
	if is_full():
		return
	charge = minf(charge + amount, 100.0)
	charge_changed.emit(charge)
