extends GameTest
## The Juggernaut: its front shield blocks normal bullets, not piercing ones or hits from behind; it turns slowly.

const JUGGERNAUT := preload("res://enemies/juggernaut/juggernaut.tscn")


func _run() -> void:
	await load_scene(TEST_ROOM, true)
	var hero := solo_hero()
	hero.set_physics_process(false)
	hero.health.max_health = 1_000_000 # never wipe (and reload the room) mid-test

	# --- Shield (bullets come from the left, along y = 280)
	var target := spawn_target(Vector2(300, 280), JUGGERNAUT)
	target.rotation = PI # shield facing the shooter
	await physics_frame
	var bullet := spawn_bullet(Vector2(176, 280), 0.0, 10, 400.0)
	await wait(20)
	check(damage_taken(target) == 0 and not is_instance_valid(bullet), "the shield stops a normal bullet from the front")

	spawn_bullet(Vector2(176, 280), 0.0, 10, 400.0, true)
	await wait(20)
	check(damage_taken(target) == 10, "a piercing bullet goes through the shield")

	target.rotation = 0.0 # back to the shooter
	await physics_frame
	spawn_bullet(Vector2(176, 280), 0.0, 10, 400.0)
	await wait(20)
	check(damage_taken(target) == 20, "a normal bullet from behind hits")

	target.health.take_damage(target.health.current)
	await wait(2)
	check(target.get_node("Shield").collision_layer == 0, "a dead juggernaut's shield stops blocking")

	# --- Slow turning: the hero is behind it, so it has to turn around
	var turner := spawn_enemy(Vector2(240, 112), JUGGERNAUT) # facing right, away from the hero
	turner.target = hero
	await wait(30) # 0.5 s
	var turned := absf(angle_difference(0.0, turner.rotation))
	check(turned > 0.0 and turned <= deg_to_rad(turner.stats.turn_speed * 0.5 + 2.0), "it turns toward its target no faster than turn_speed")
