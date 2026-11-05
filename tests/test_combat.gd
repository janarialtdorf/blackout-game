extends GameTest
## Weapons, bullets, health and hits.

const PROJECTILE := preload("res://weapons/projectile.tscn")
const DUMMY := preload("res://enemies/target_dummy.tscn")


func _run() -> void:
	await load_scene(TEST_ROOM, true)
	var hero := solo_hero()
	hero.set_physics_process(false)

	# --- Health
	var health := HealthComponent.new()
	health.max_health = 50
	var deaths := [0]
	health.died.connect(func() -> void: deaths[0] += 1)
	check(health.current == 50, "setting max health fills current health")
	check(health.take_damage(20) == 20 and health.current == 30, "damage lowers health and returns what was dealt")
	check(health.take_damage(100) == 30 and health.current == 0, "health never drops below 0; only the remaining HP counts as dealt")
	check(health.take_damage(10) == 0 and deaths[0] == 1, "'died' fires once; a dead thing takes no more damage")
	health.free()

	# --- Weapon
	var weapon := hero.weapon
	var before := count_projectiles()
	check(weapon.try_fire(), "a ready weapon fires")
	check(count_projectiles() - before == weapon.stats.pellet_count, "one projectile per pellet")
	check(not weapon.try_fire(), "firing again right away is blocked by the fire-rate cooldown")
	weapon.get_node("Cooldown").stop()
	check(weapon.try_fire(), "fires again once the cooldown is over")
	await wait(120) # let the shots hit the wall and go away

	# --- Bullets
	var bullet := _bullet(hero.global_position, PI, 10, INF)
	await wait(120)
	check(not is_instance_valid(bullet), "a bullet stops at a wall")

	bullet = _bullet(Vector2(176, 280), 0.0, 10, 50.0)
	await wait(10)
	check(not is_instance_valid(bullet), "a bullet disappears at its max range")

	var dummy: Node2D = DUMMY.instantiate()
	dummy.position = Vector2(300, 280)
	current_scene.add_child(dummy)
	var dummy_health: HealthComponent = dummy.get_node("HealthComponent")
	_bullet(Vector2(176, 280), 0.0, 60, 400.0)
	await wait(20)
	check(dummy_health.current == dummy_health.max_health - 60, "a bullet deals its damage to what it hits")
	_bullet(Vector2(176, 280), 0.0, 60, 400.0)
	await wait(20)
	check(not is_instance_valid(dummy), "a target dummy is removed at 0 HP")

	var lined_up: Array[Enemy] = []
	for x in [260, 320, 380]:
		lined_up.append(spawn_target(Vector2(x, 280)))
	await physics_frame
	_bullet(Vector2(176, 280), 0.0, 30, 400.0, true)
	await wait(20)
	check(lined_up.all(func(enemy: Enemy) -> bool: return damage_taken(enemy) == 30), "a piercing bullet hits every enemy in its path exactly once")
	for enemy in lined_up:
		enemy.free()

	# --- No friendly fire
	var shooter := spawn_target(Vector2(176, 280), SHOOTER)
	var buddy := spawn_target(Vector2(240, 280))
	shooter.weapon.fire_projectile(0.0, 50)
	await wait(20)
	check(damage_taken(buddy) == 0, "enemy bullets pass through other enemies")
	hero.global_position = Vector2(176, 340)
	var second: Hero = preload("res://heroes/hero.tscn").instantiate()
	second.stats = hero.stats
	second.position = Vector2(240, 340)
	current_scene.add_child(second)
	second.set_physics_process(false)
	hero.weapon.fire_projectile(0.0, 50)
	await wait(20)
	check(second.health.current == second.health.max_health, "hero bullets pass through other heroes")


func _bullet(at: Vector2, angle: float, damage: int, max_distance: float, pierces := false) -> Projectile:
	var bullet: Projectile = PROJECTILE.instantiate()
	bullet.position = at
	bullet.rotation = angle
	bullet.speed = 700.0
	bullet.max_distance = max_distance
	bullet.damage = damage
	bullet.hit_mask = 1 | 16 # walls + enemy_hurtbox
	bullet.pierces = pierces
	current_scene.add_child(bullet)
	return bullet
