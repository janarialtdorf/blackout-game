extends GameTest
## Hero death, mission fail and retry, level exits, level progression and the win screen.


func _run() -> void:
	# --- Death
	await load_scene(TEST_ROOM, true)
	var team := squad()
	var fighter := team.heroes[0]
	var sniper := team.heroes[1]
	var chaser := spawn_enemy(Vector2(240, 280))
	chaser.target = fighter
	var meter_before := sniper.ultimate.charge
	var death_spot := fighter.global_position
	fighter.health.take_damage(fighter.health.max_health)
	await wait(2)
	check(team.active == sniper and sniper.controlled, "when the controlled hero dies, control moves to a living hero")
	check(sniper.ultimate.charge >= meter_before and sniper.ultimate.charge < 100.0, "the forced switch doesn't fire an ultimate")
	check(not fighter.is_in_group(&"heroes"), "a dead hero is no longer an enemy target")
	check(chaser.target != fighter, "enemies drop a dead target")
	check(not team.try_switch(0), "you can't switch to a dead hero")
	check(is_instance_valid(fighter), "a dead hero stays on the floor")
	check(fighter.global_position == death_spot, "a forced switch on death does not swap places")
	check(result_title() == "", "no result screen while heroes are alive")

	# --- Wipe and retry
	for hero in team.heroes:
		hero.health.take_damage(hero.health.max_health)
	await process_frame
	check(result_title() == "Mission failed" and paused, "all heroes down shows 'Mission failed' and pauses")
	var old_scene := current_scene
	await press_result_button()
	check(not paused and current_scene != old_scene and current_scene.scene_file_path == TEST_ROOM, "'Retry' restarts the same level")
	check(squad().heroes.all(func(hero: Hero) -> bool: return hero.is_alive()), "after a retry every hero is back")

	# --- Exit on a level with a next level
	var chain := level_chain()
	await load_scene(chain[0], true)
	team = squad()
	var exit: LevelExit = current_scene.find_children("*", "LevelExit")[0]
	team.heroes[1].global_position = exit.global_position # an AI teammate first: should not count
	await wait(5)
	check(current_scene.scene_file_path == chain[0], "an AI teammate on the exit does nothing")
	team.active.global_position = exit.global_position
	await wait(5)
	await wait_for_fade()
	check(current_scene.scene_file_path == chain[1], "the controlled hero on the exit loads the next level")

	# --- Last level: win screen, then back to level 1
	await load_scene(chain[-1])
	exit = current_scene.find_children("*", "LevelExit")[0]
	for enemy: Enemy in get_nodes_in_group(&"enemies"):
		enemy.health.take_damage(enemy.health.max_health) # killed, not freed: a boss must die to unlock the exit
	await wait(2)
	squad().active.global_position = exit.global_position
	await wait(5)
	check(result_title() == "Mission complete!" and paused, "the last level's exit shows 'Mission complete!'")
	await press_result_button()
	check(current_scene.scene_file_path == chain[0] and not paused, "'Play again' goes back to level 1")
