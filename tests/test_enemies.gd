extends GameTest
## Chaser and shooter AI: idle (or patrol) until they see a hero in their view cone or get hit, then chase and attack.


func _run() -> void:
	await load_scene(TEST_ROOM, true)
	var hero := solo_hero()
	hero.set_physics_process(false) # stand still
	hero.health.max_health = 1_000_000 # never wipe (and reload the room) mid-test

	var turned_away := spawn_enemy(Vector2(240, 112)) # in the open, facing right, away from the hero
	turned_away.patrol = false # standing guards, so only noticing is tested here
	await wait(30)
	check(turned_away.target == null, "an enemy doesn't notice a hero behind its view cone")
	turned_away.free()

	var hidden := spawn_enemy(Vector2(336, 80)) # behind the wall column, within sight range
	hidden.patrol = false
	var near := spawn_enemy(Vector2(240, 112)) # in the open, two tiles right of the hero
	near.rotation = PI # facing the hero
	await wait(120)
	check(hidden.target == null and hidden.position.is_equal_approx(Vector2(336, 80)), "an enemy that can't see a hero stays idle")
	check(near.target == hero, "an enemy that sees a hero targets it")
	check(hero.health.current < hero.health.max_health, "a chaser walks up and hits the hero in melee")

	hidden.health.take_damage(1)
	check(hidden.target == hero, "getting hurt wakes an idle enemy")
	check(hidden.has_node(^"Exclamation"), "an enemy shows a \"!\" when it notices a hero")
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
	shooter.rotation = PI
	await wait(180)
	var distance := shooter.global_position.distance_to(hero.global_position)
	check(distance > 100.0, "a shooter stops at its preferred distance instead of closing in")
	check(hero.health.current < hp_before, "a shooter hits the hero from range")
	shooter.free()

	# --- Patrol: walks where it faces and turns around at a wall
	hero.global_position = Vector2(176, 112)
	var patroller := spawn_enemy(Vector2(176, 272)) # open corridor, the hero is out of its cone
	patroller.rotation = PI # toward the left wall at x = 32
	await wait(30)
	check(patroller.global_position.x < 176 - 20, "a patrolling enemy walks where it faces")
	check(patroller.sight_cone.visible, "an enemy shows its view cone")
	await wait(150)
	check(absf(angle_difference(patroller.rotation, 0.0)) < 0.01 and patroller.target == null, "a patrolling enemy turns around at a wall")
	patroller.health.take_damage(1)
	await wait(2)
	check(patroller.sight_cone.visible, "the view cone stays visible while chasing")
