extends Node2D
## Placeholder burst: a ring at radius 100 px (scaled by the ability) that fades out and frees itself.
## To use art instead: make a scene that plays your animation, then calls queue_free().

@export var color := Color(1, 0.9, 0.6)


func _ready() -> void:
	var tween := create_tween()
	tween.tween_property(self, ^"modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 100.0, Color(color, 0.15))
	draw_arc(Vector2.ZERO, 100.0, 0.0, TAU, 64, color, 3.0)
