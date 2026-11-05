class_name ResultScreen
extends CanvasLayer
## Full-screen message over the paused game (mission failed / level complete) with one button.
## Runs while the game is paused (process mode "Always").

## Emitted when the button is pressed. The game is unpaused first.
signal confirmed

@onready var _title: Label = %Title
@onready var _button: Button = %Button


func _ready() -> void:
	_button.pressed.connect(_on_button_pressed)


func show_result(title: String, button_text: String) -> void:
	_title.text = title
	_button.text = button_text
	_button.grab_focus()


func _on_button_pressed() -> void:
	get_tree().paused = false
	confirmed.emit()
