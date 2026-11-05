class_name LevelExit
extends Area2D
## The end of a level. Fires `reached` when the hero you control steps on it (unless locked).

signal reached

## A locked exit is dimmed and ignores heroes. The Level unlocks it when every boss is dead.
@export var locked := false:
	set(value):
		locked = value
		modulate = Color(0.35, 0.35, 0.35, 0.6) if locked else Color.WHITE


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not locked and body is Hero and body.controlled:
		reached.emit()
