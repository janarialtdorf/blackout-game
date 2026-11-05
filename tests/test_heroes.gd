extends GameTest
## The three heroes match the design, and the controlled hero follows player input.


func _run() -> void:
	await load_scene(TEST_ROOM, true)
	var team := squad()
	var names := team.heroes.map(func(hero: Hero) -> String: return hero.stats.display_name)
	check(names == ["Fighter", "Sniper", "Seer"], "the squad is Fighter, Sniper, Seer in key order")
	var fighter := team.heroes[0]
	var sniper := team.heroes[1]
	var seer := team.heroes[2]

	check(fighter.health.max_health > seer.health.max_health and seer.health.max_health > sniper.health.max_health, "HP: Fighter high, Sniper low")
	check(fighter.weapon.stats.pellet_count > 1, "Fighter shoots a shotgun spread")
	check(sniper.weapon.stats.pierces, "Sniper's shot pierces")
	check(sniper.weapon.stats.projectile_speed > fighter.weapon.stats.projectile_speed, "Sniper's shot is the fastest bullet")
	check(seer.weapon.stats.fire_rate > fighter.weapon.stats.fire_rate and seer.weapon.stats.damage < fighter.weapon.stats.damage, "Seer's gun is fast and weak")

	check(sniper.vision.vision_range > fighter.vision.vision_range and sniper.vision.angle_degrees < fighter.vision.angle_degrees, "Sniper sees further in a narrower cone than the Fighter")
	check(seer.vision.angle_degrees == 360.0 and seer.vision.sees_through_walls, "Seer sees a full circle through walls")
	check(seer.vision.vision_range < fighter.vision.vision_range, "Seer's circle is small")
	check(not fighter.vision.sees_through_walls and not sniper.vision.sees_through_walls, "Fighter and Sniper are blocked by walls")

	# --- Player input
	var hero := solo_hero()
	var start := hero.global_position
	Input.action_press("move_down")
	await wait(20)
	Input.action_release("move_down")
	check(hero.global_position.y > start.y + 20, "the move actions walk the controlled hero")
	var before := count_projectiles()
	Input.action_press("shoot")
	await physics_frame
	await physics_frame
	Input.action_release("shoot")
	check(count_projectiles() > before, "the shoot action fires the controlled hero's weapon")
