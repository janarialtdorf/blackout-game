class_name SightCone
extends Node2D
## Draws an enemy's view cone as a faint yellow area that stops at walls. Faces +X like the art.

const COLOR := Color(1.0, 0.9, 0.3, 0.18)
const DEGREES_PER_RAY := 3.0

@export var sight_range: float = 250.0
@export var angle_degrees: float = 90.0


func _process(_delta: float) -> void:
	if is_visible_in_tree():
		queue_redraw()


func _draw() -> void:
	var rays := ceili(angle_degrees / DEGREES_PER_RAY)
	var points := PackedVector2Array([Vector2.ZERO])
	for i in rays + 1:
		var direction := Vector2.from_angle(global_rotation + deg_to_rad(angle_degrees * (float(i) / rays - 0.5)))
		points.append(to_local(LineOfSight.reach(self, global_position, global_position + direction * sight_range)))
	draw_colored_polygon(points, COLOR)
