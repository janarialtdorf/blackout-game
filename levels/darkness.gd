extends CanvasModulate
## Darkens the whole level; heroes' vision lights cut through it.
## Saved hidden so the level stays bright while you paint it in the editor; turned on in-game.
## Colour 50% grey + VisionComponent energy 0.5 = lit things show their true colours.


func _ready() -> void:
	visible = true
