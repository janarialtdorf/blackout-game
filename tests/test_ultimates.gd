extends GameTest
## Ultimate meters, and each hero's ultimate firing when you switch to it with a full meter.


func _run() -> void:
	await load_scene(TEST_ROOM, true)
	var team := squad()
	var fighter := team.heroes[0]
	var sniper := team.heroes[1]
	var seer := team.heroes[2]
	for hero in team.heroes:
		hero.set_physics_process(false) # nobody moves or shoots on their own
		hero.ultimate.set_process(false) # no passive charge, so the numbers below are exact
		hero.ultimate.charge = 0.0

	# --- Meter
	var meter := fighter.ultimate
	check(is_equal_approx(meter.per_damage, 0.2), "the meter gains 1 % per 5 damage dealt")
	meter._process(0.1)
	var passive := meter.passive_per_second * 0.1
	check(passive > 0.0 and is_equal_approx(meter.charge, passive), "the meter fills over time")
	var target := spawn_target(fighter.global_position + Vector2(60, 0))
	fighter.weapon.fire_projectile(0.0, 25)
	await wait(10)
	check(is_equal_approx(meter.charge, passive + 25 * 0.2), "damage a hero deals charges its own meter")
	check(sniper.ultimate.charge == 0.0, "other heroes' meters don't get the credit")
	meter.charge = 99.9
	meter.add_damage(1000)
	check(meter.charge == 100.0 and meter.is_full(), "the meter caps at 100 %")
	target.free()

	# --- Below full: switching in fires nothing
	var close := spawn_target(fighter.global_position + Vector2(0, 60))
	close.set_physics_process(true) # a knockback is applied in its physics step
	var start := close.global_position
	for hero in team.heroes:
		hero.ultimate.charge = 99.0
		hero.switch_in()
	await physics_frame
	check(damage_taken(close) == 0, "nothing fires on switch-in with a meter below full")
	check(team.heroes.all(func(hero: Hero) -> bool: return hero.ultimate.charge == 99.0), "a part-full meter is kept")

	# --- Fighter: 100-damage shockwave with knockback
	fighter.ultimate.charge = 100.0
	fighter.switch_in()
	check(damage_taken(close) == 100, "Fighter's ultimate deals 100 damage around it")
	check(fighter.ultimate.charge == 0.0, "firing the ultimate empties the meter")
	await wait(10)
	check(close.global_position.distance_to(fighter.global_position) > start.distance_to(fighter.global_position), "Fighter's ultimate knocks enemies away")
	var behind_wall := spawn_target(Vector2(300, 112))
	fighter.ultimate.charge = 100.0
	fighter.switch_in()
	check(damage_taken(behind_wall) == 0, "Fighter's shockwave is blocked by walls")
	check(fighter.ultimate.charge == 0.0, "ultimate damage does not recharge the meter")
	close.free()
	behind_wall.free()

	# --- Sniper: aimed 150-damage beam through walls
	sniper.global_position = Vector2(176, 112)
	sniper.rotation = 0.0 # aiming right, through the wall column at x = 256..288
	var in_line := spawn_target(Vector2(330, 112))
	var off_line := spawn_target(Vector2(330, 112 + 80))
	sniper.ultimate.charge = 100.0
	sniper.stats.ultimate.activate(sniper) # switch_in would aim at the (absent) mouse
	check(damage_taken(in_line) == 150, "Sniper's beam hits through walls for 150")
	check(damage_taken(off_line) == 0, "Sniper's beam only hits along where it is aimed")
	in_line.free()
	off_line.free()

	# --- Seer: 8 s team wall-sight and reveal
	var hidden := spawn_target(Vector2(336, 80)) # behind the wall column
	await wait(2)
	check(not hidden.visible, "an enemy behind a wall starts hidden")
	seer.ultimate.charge = 100.0
	team.get_node("SwitchCooldown").stop()
	check(team.try_switch(2), "switch to the Seer")
	await wait(2)
	check(hidden.visible, "Seer's ultimate reveals hidden enemies")
	var reveal: RevealAbility = seer.stats.ultimate
	check(reveal.duration == 8.0 and reveal.team_wall_sight, "Seer's ultimate lasts 8 s and gives the team wall-sight")
	fighter.global_position = Vector2(176, 112)
	fighter.rotation = 0.0
	check(fighter.vision.can_see(Vector2(320, 112)), "during the Seer's ultimate the Fighter sees through walls too")
