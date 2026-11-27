class_name DialogueBox
extends CanvasLayer
## Ren'Py-style conversation over the paused game: a portrait slot on each side and a text box
## with the speaker's name. Text types out; advancing shows the whole line first, then the next.
## Runs while the game is paused (process mode "Always").

## After the last line. The box frees itself once its click sound has played.
signal finished

## The speaker who isn't talking is dimmed to this.
const INACTIVE := Color(0.45, 0.45, 0.45)
## Seconds for a character to fade in when it appears (Ren'Py's "dissolve").
const DISSOLVE_TIME := 0.3

@export var chars_per_second := 40.0

var _lines: Array[DialogueLine] = []
var _index := -1
var _typing: Tween
var _shown: Array[Speaker] = [null, null] # who stands in the left and right slot

@onready var _slots: Array[Control] = [%Left, %Right]
@onready var _name_tab: PanelContainer = %NameTab
@onready var _name: Label = %Name
@onready var _text: Label = %Text


func play(dialogue: Dialogue) -> void:
	_lines = dialogue.lines
	_next()


# On release, not press: the last line unpauses the game, and a still-held mouse button would shoot.
func _input(event: InputEvent) -> void:
	if not event.is_action_released("advance_dialogue"):
		return
	get_viewport().set_input_as_handled()
	$ClickSound.play()
	if _text.visible_ratio < 1.0:
		_typing.kill()
		_text.visible_ratio = 1.0
	else:
		_next()


func _next() -> void:
	_index += 1
	if _index >= _lines.size():
		hide()
		set_process_input(false)
		finished.emit()
		$ClickSound.finished.connect(queue_free)
		return
	var line := _lines[_index]
	_name.text = line.speaker.display_name
	_name_tab.self_modulate = line.speaker.color # tints the white tab, keeps its black border and the label
	_text.text = line.text
	_text.visible_ratio = 0.0
	_typing = create_tween()
	_typing.tween_property(_text, ^"visible_ratio", 1.0, line.text.length() / chars_per_second)
	for slot in _slots:
		slot.modulate = INACTIVE
	if line.speaker.on_screen:
		_show_in(int(line.right), line.speaker)


func _show_in(side: int, speaker: Speaker) -> void:
	var slot := _slots[side]
	slot.modulate = Color.WHITE
	if _shown[side] == speaker:
		return
	_shown[side] = speaker
	slot.show()
	slot.get_node(^"Picture").texture = speaker.portrait
	var placeholder: BodyDrawing = slot.get_node(^"Placeholder")
	placeholder.visible = speaker.portrait == null
	placeholder.color = speaker.color
	slot.modulate.a = 0.0
	create_tween().tween_property(slot, ^"modulate:a", 1.0, DISSOLVE_TIME)
