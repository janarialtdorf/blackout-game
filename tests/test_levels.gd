extends GameTest
## Every real level is built correctly and its exit can be walked to from the spawn.


func _run() -> void:
	var chain := level_chain()
	check(chain[0] == "res://levels/level_1.tscn", "the game starts at level 1")
	check(chain.size() >= 3, "levels 1 -> 2 -> 3 are chained")
	for path in chain:
		var level: Level = await load_scene(path)
		var name := path.get_file()
		check(level.get_node_or_null("Squad") is Squad, name + ": has a Squad")
		check(level.get_node_or_null("Darkness") is CanvasModulate, name + ": has Darkness")
		check(level.find_children("*", "LevelNavigation").size() == 1, name + ": has a LevelNavigation")
		check(level.find_children("*", "LevelExit").size() >= 1, name + ": has an exit")
		check(get_nodes_in_group(&"enemies").size() >= 6, name + ": has enemies")
		var map := level.get_world_2d().navigation_map
		var exit: LevelExit = level.find_children("*", "LevelExit")[0]
		var start := squad().active.global_position
		var reached := false
		for i in 60: # the level's navigation joins the map during a later physics step
			await physics_frame
			var path_to_exit := NavigationServer2D.map_get_path(map, start, exit.global_position, true)
			reached = path_to_exit.size() > 1 and path_to_exit[-1].distance_to(exit.global_position) < 16.0
			if reached:
				break
		check(reached, name + ": the exit can be walked to from the spawn")
