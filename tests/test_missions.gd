extends GameTest
## Mission objectives (Collectible): pick up on touch, hold-to-hack, bonus items, objective
## text, locked exits, and each real level's mission.

const COLLECTIBLE := preload("res://levels/collectible.tscn")


func _run() -> void:
	# The Level counts its collectibles in _ready, so they are added before the room enters the tree.
	var level: Level = load(TEST_ROOM).instantiate()
	var intel_a := _add(level, Vector2(176, 240), "Collect intel")
	var intel_b := _add(level, Vector2(112, 240), "Collect intel")
	var terminal := _add(level, Vector2(176, 336), "Hack terminal", 0.5)
	var bonus := _add(level, Vector2(112, 336), "Bonus intel")
	bonus.required = false
	get_tree().change_scene_to_node(level)
	await process_frame
	await process_frame
	for enemy in get_nodes_in_group(&"enemies"):
		enemy.free()
	var team := squad()
	var exit: LevelExit = current_scene.find_children("*", "LevelExit")[0]
	check(exit.locked, "the exit starts locked while objectives are left")
	check(_goal() == "Collect intel (0/2)\nHack terminal (0/1)\nBonus intel (0/1)", "the objective lists every goal with its count")
	check(intel_a.is_in_group(&"objectives"), "collectibles are in the 'objectives' group")

	team.heroes[1].global_position = intel_a.global_position
	await wait(5)
	check(not intel_a.is_collected, "an AI teammate can't pick up an objective")
	team.heroes[1].global_position = Vector2(176, 112)

	team.active.global_position = intel_a.global_position
	await wait(3)
	check(intel_a.is_collected and not intel_a.visible, "the controlled hero picks up intel by touching it, and it disappears")
	check(_goal().begins_with("Collect intel (1/2)"), "the count goes up")

	team.active.global_position = terminal.global_position
	await wait(10)
	check(not terminal.is_collected, "a terminal needs the hero to stay for its hold_time")
	team.active.global_position = Vector2(176, 112)
	await wait(40)
	check(not terminal.is_collected, "walking away pauses the hack")
	team.active.global_position = terminal.global_position
	await wait(25)
	check(terminal.is_collected and terminal.visible, "staying long enough hacks it; it stays visible (greyed out)")

	team.active.global_position = intel_b.global_position
	await wait(3)
	check(not exit.locked, "when every required objective is done the exit unlocks")
	check(_goal() == "Reach the exit\nBonus intel (0/1)", "then the objective says to reach the exit; the bonus stays listed")
	team.active.global_position = bonus.global_position
	await wait(3)
	check(_goal() == "Reach the exit\nBonus intel (1/1)", "the bonus counts when picked up")

	# --- Each real level has its own mission
	var chain := level_chain()
	var missions := [["Collect intel", 0.0, true], ["Hack server", 1.0, true], ["Bonus intel", 0.0, false]]
	for i in chain.size():
		var real: Level = load(chain[i]).instantiate()
		var items: Array[Node] = real.find_children("*", "Collectible")
		var name := chain[i].get_file()
		if i < missions.size():
			var mission: Array = missions[i]
			check(not items.is_empty() and items.all(func(item: Collectible) -> bool:
				return item.label.begins_with(mission[0]) and (item.hold_time > 0.0) == (mission[1] > 0.0) and item.required == mission[2]),
				name + ": its mission is '" + mission[0] + "'")
		real.free()
	await load_scene(chain[0])
	check(current_scene.find_children("*", "LevelExit")[0].locked, "level 1's exit starts locked")
	complete_objectives()
	check(not current_scene.find_children("*", "LevelExit")[0].locked, "collecting everything in level 1 unlocks its exit")


func _add(level: Level, at: Vector2, label: String, hold_time := 0.0) -> Collectible:
	var item: Collectible = COLLECTIBLE.instantiate()
	item.position = at
	item.label = label
	item.hold_time = hold_time
	level.add_child(item)
	item.owner = level # find_children() only finds nodes the scene owns, like ones placed in the editor
	return item


func _goal() -> String:
	return current_scene.find_child("ObjectivePanel", false, false).get_node("%Goal").text
