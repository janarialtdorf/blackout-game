class_name ObjectivePanel
extends CanvasLayer
## Top-right box with the current goal. The Level sets the text.

@onready var _goal: Label = %Goal


func show_objective(text: String) -> void:
	_goal.text = text
