extends GameTest
## Chaser and shooter AI: idle until they see a hero or get hit, then chase and attack.


func _run() -> void:
	await load_scene(TEST_ROOM, true)
	var hero := solo_hero()
	hero.set_physics_process(false) # stand still
	hero.health.max_health = 1_000_000 # never wipe (and reload the room) mid-test

	var hidden := spawn_enemy(Vector2(336, 80)) # behind the wall column, within sight range
	var near := spawn_enemy(Vector2(240, 112)) # in the open, two tiles right of the hero
	await wait(120)
	check(hidden.target == null and hidden.position.is_equal_approx(Vector2(336, 80)), "an enemy that can't see a hero stays idle")
	check(near.target == hero, "an enemy that sees a hero targets it")
	check(hero.health.current < hero.health.max_health, "a chaser walks up and hits the hero in melee")

	hidden.health.take_damage(1)
	check(hidden.target == hero, "getting hurt wakes an idle enemy")
	var start_distance := hidden.global_position.distance_to(hero.global_position)
	await wait(120)
	check(hidden.global_position.distance_to(hero.global_position) < start_distance - 48, "a woken enemy paths around the wall toward the hero")

	near.knock_back(Vector2(-600, 0) if near.global_position.x < hero.global_position.x else Vector2(600, 0))
	var before_push := near.global_position.distance_to(hero.global_position)
	await wait(6)
	check(near.global_position.distance_to(hero.global_position) > before_push, "a knockback pushes the enemy away")

	near.health.take_damage(near.health.max_health)
	hidden.health.take_damage(hidden.health.max_health)
	await wait(30) # the die animation plays first
	check(not is_instance_valid(near) and not is_instance_valid(hidden), "an enemy is removed when it dies")

	# --- Shooter keeps its distance and fires from range
	hero.global_position = Vector2(176, 280) # open floor
	var hp_before := hero.health.current
	var shooter := spawn_enemy(Vector2(400, 280), SHOOTER)
	await wait(180)
	var distance := shooter.global_position.distance_to(hero.global_position)
	check(distance > 100.0, "a shooter stops at its preferred distance instead of closing in")
	check(hero.health.current < hp_before, "a shooter hits the hero from range")
