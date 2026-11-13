extends GameTest
## The game opens on the start menu; its Start button loads the first level.


func _run() -> void:
	var main: String = ProjectSettings.get_setting("application/run/main_scene")
	check(main == "res://ui/start_menu.tscn", "the game opens on the start menu")
	await load_scene(main)
	var start: TextureButton = current_scene.get_node("%Start")
	check(start.texture_hover != start.texture_normal, "the Start button changes look on hover")
	check(start.has_focus(), "Start has keyboard focus, so Enter works too")
	start.pressed.emit()
	check(current_scene.scene_file_path == ProjectSettings.get_setting("application/run/main_scene"), "the menu stays while the screen fades out")
	await wait_for_fade()
	check(current_scene.scene_file_path == StartMenu.FIRST_LEVEL, "Start loads the first level")
