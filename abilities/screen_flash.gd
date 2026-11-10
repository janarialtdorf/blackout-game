extends CanvasLayer
## Tints the whole screen (HUD included) and fades out. Add it to an effect scene and set its colour
## there; it goes away with the effect, so keep fade_time no longer than the effect's animation.

@export var color := Color(1, 0.9, 0, 0.3)
@export var fade_time := 0.4


func _ready() -> void:
	$Color.color = color
	create_tween().tween_property($Color, ^"modulate:a", 0.0, fade_time)
