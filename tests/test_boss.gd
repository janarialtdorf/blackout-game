extends GameTest
## The boss: aimed 3-burst and 12-bullet ring, knockback resistance, health bar, locked exit.

const BOSS := preload("res://enemies/boss/boss.tscn")

var _spawned := 0


func _run() -> void:
	await load_scene(TEST_ROOM, true)
	solo_hero() # AI teammates would shoot the boss and add projectiles
	var boss: Boss = spawn_enemy(Vector2(500, 280), BOSS)
	boss.set_physics_process(false) # attacks are triggered by hand
	current_scene.child_entered_tree.connect(func(node: Node) -> void:
		if node is Projectile:
			_spawned += 1)
	boss._attack()
	await wait(30)
	check(_spawned == 3, "first attack is an aimed burst of 3")
	check(not boss.weapon.use_cooldown(), "attacks share the weapon's fire-rate cooldown")
	boss.weapon.get_node("Cooldown").stop()
	_spawned = 0
	boss._attack()
	check(_spawned == 12, "next attack is a ring of 12")

	boss.set_physics_process(true)
	var start := boss.global_position
	boss.knock_back(Vector2(900, 0))
	await wait(15)
	check(boss.global_position.distance_to(start) < 40.0, "the boss barely moves when knocked back")

	# --- In a real level: boss bar and locked exit
	var boss_level := ""
	for path in level_chain():
		var level: Level = load(path).instantiate()
		if level.find_children("*", "Boss").size() > 0:
			boss_level = path
		level.free()
		if boss_level:
			break
	check(boss_level != "", "a level has a boss")
	await load_scene(boss_level)
	var exit: LevelExit = current_scene.find_children("*", "LevelExit")[0]
	boss = current_scene.find_children("*", "Boss")[0]
	check(exit.locked, "the exit starts locked while the boss lives")
	check(current_scene.find_child("BossBar", false, false) == null, "no boss bar before the boss appears")
	squad().active.global_position = exit.global_position
	await wait(5)
	check(result_title() == "" and current_scene.scene_file_path == boss_level, "a locked exit does nothing")

	boss.target = squad().active # the boss notices a hero
	await wait(2)
	var bar: BossBar = current_scene.find_child("BossBar", false, false)
	check(bar != null and bar.get_node("%Name").text == boss.stats.display_name, "the boss bar appears with the boss's name")
	boss.health.take_damage(500)
	check(bar.get_node("%Bar").value == boss.health.current, "the boss bar follows the boss's HP")
	boss.health.take_damage(boss.health.max_health)
	await process_frame
	check(not is_instance_valid(bar), "the boss bar goes away when the boss dies")
	check(not exit.locked, "killing the boss unlocks the exit")
