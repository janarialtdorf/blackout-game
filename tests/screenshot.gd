extends Node
## Opens a window, plays the first level for ~1 s and saves a screenshot. Not a pass/fail test.
## Run (NOT headless):
##   Godot.exe --path . res://tools/run.tscn -- res://tests/screenshot.gd <output.png> [hero_rotation_degrees] [hero_index]


func _ready() -> void:
	var args := OS.get_cmdline_user_args().slice(1) # the first one is this script's path
	get_tree().change_scene_to_file(StartMenu.FIRST_LEVEL)
	await get_tree().process_frame
	await get_tree().process_frame
	var squad: Squad = get_tree().current_scene.get_node_or_null("Squad")
	if squad and args.size() > 2:
		squad.try_switch(int(args[2]))
	if squad and args.size() > 1:
		squad.active.set_physics_process(false)
		squad.active.rotation_degrees = float(args[1])
	for i in 60:
		await get_tree().process_frame
	get_tree().root.get_texture().get_image().save_png(args[0])
	get_tree().quit()
