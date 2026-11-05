extends SceneTree
## Opens a window, plays the main scene for ~1 s and saves a screenshot. Not a pass/fail test.
## Run (NOT headless):
##   Godot.exe --path . --script res://tests/screenshot.gd -- <output.png> [hero_rotation_degrees] [hero_index]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
	await process_frame
	await process_frame
	var squad: Squad = current_scene.get_node_or_null("Squad")
	if squad and args.size() > 2:
		squad.try_switch(int(args[2]))
	if squad and args.size() > 1:
		squad.active.set_physics_process(false)
		squad.active.rotation_degrees = float(args[1])
	for i in 60:
		await process_frame
	root.get_texture().get_image().save_png(args[0])
	quit()
