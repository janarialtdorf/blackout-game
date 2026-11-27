class_name Collectible
extends Area2D
## A mission objective (intel file, server terminal, ...). The hero you control collects it by
## touching it, or, with a hold_time, by standing in it that long (a ring shows the progress;
## leaving pauses it). The Level keeps its exits locked while a required one is left.

signal collected

## Shown in the objective panel as "<label> (found/total)". Same label = counted together.
@export var label := "Collect intel"
## 0 = collected on touch. More = seconds the controlled hero must stand in it.
@export var hold_time := 0.0
## A bonus objective: shown in the panel, but the exit does not wait for it.
@export var required := true
## Colour of the hold-progress ring.
@export var color := Color(1.0, 0.8, 0.1)
## Half the sprite size: the hold ring is drawn just outside it.
@export var radius := 16.0
## Optional: played once on top when a hold objective is done (not greyed out with the item).
@export var done_effect: AnimatedSprite2D

var is_collected := false
var _progress := 0.0


func _physics_process(delta: float) -> void:
	if is_collected or not get_overlapping_bodies().any(_is_controlled_hero):
		return
	_progress += delta
	queue_redraw()
	if _progress >= hold_time:
		_collect()


func _collect() -> void:
	is_collected = true
	# A picked-up item disappears; a used terminal stays, greyed out.
	if hold_time > 0.0:
		self_modulate = Color(0.5, 0.5, 0.5)
		$Sprite.modulate = Color(0.5, 0.5, 0.5)
		if done_effect:
			done_effect.show()
			done_effect.play()
	else:
		# Out of the group, or the VisionComponent would show it again when seen.
		remove_from_group(&"hidden_in_dark")
		hide()
	collected.emit()


func _is_controlled_hero(body: Node2D) -> bool:
	return body is Hero and body.controlled


func _draw() -> void:
	if hold_time > 0.0:
		var ring := radius + 8.0
		draw_arc(Vector2.ZERO, ring, 0.0, TAU, 32, color.darkened(0.35), 2.0)
		draw_arc(Vector2.ZERO, ring, -PI / 2.0, -PI / 2.0 + TAU * minf(_progress / hold_time, 1.0), 32, color, 4.0)
