extends Node
## Runs one test or tool script inside the real game, so everything (autoloads included) works as
## when playing. The script is the first argument after `--`; the rest are passed to it:
##   Godot.exe --headless --path . res://tools/run.tscn -- res://tests/test_<name>.gd
## The script's node is added to the root, not under this scene, so it survives scene changes.


func _ready() -> void:
	var node: Node = load(OS.get_cmdline_user_args()[0]).new()
	get_tree().root.add_child.call_deferred(node)
