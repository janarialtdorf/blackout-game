extends Node2D
## Placeholder beam: a 100 x 100 px bar starting at the origin along +X (scaled by the ability)
## that fades out and frees itself. To use art instead: a scene that plays your beam, then queue_free().

@export var color := Color(0.6, 0.9, 1)


func _ready() -> void:
	var tween := create_tween()
	tween.tween_property(self, ^"modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)


func _draw() -> void:
	draw_rect(Rect2(0, -50, 100, 100), Color(color, 0.35))
	draw_rect(Rect2(0, -15, 100, 30), color)
