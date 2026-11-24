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
@export var color := Color(1.0, 0.8, 0.1)
@export var radius := 10.0

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
		modulate = Color(0.5, 0.5, 0.5)
	else:
		hide()
	collected.emit()


func _is_controlled_hero(body: Node2D) -> bool:
	return body is Hero and body.controlled


func _draw() -> void:
	var diamond := PackedVector2Array([
		Vector2(0, -radius), Vector2(radius, 0), Vector2(0, radius), Vector2(-radius, 0)])
	draw_colored_polygon(diamond, color)
	diamond.append(diamond[0])
	draw_polyline(diamond, color.darkened(0.35), 3.0)
	if hold_time > 0.0:
		var ring := radius + 8.0
		draw_arc(Vector2.ZERO, ring, 0.0, TAU, 32, color.darkened(0.35), 2.0)
		draw_arc(Vector2.ZERO, ring, -PI / 2.0, -PI / 2.0 + TAU * minf(_progress / hold_time, 1.0), 32, color, 4.0)
