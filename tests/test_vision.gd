extends GameTest
## Darkness and limited vision: you only see enemies your active hero can see.


func _run() -> void:
	await load_scene(TEST_ROOM, true)
	check(current_scene.get_node("Darkness").visible, "the darkness is switched on in-game")
	var hero := solo_hero()
	hero.set_physics_process(false) # don't turn toward the (absent) mouse
	hero.rotation = 0.0 # face right
	var vision := hero.vision

	check(vision.can_see(Vector2(240, 112)), "sees a point ahead in the open")
	check(not vision.can_see(Vector2(320, 112)), "a wall blocks sight")
	check(not vision.can_see(Vector2(100, 112)), "doesn't see behind itself")
	check(vision.can_see(Vector2(176 - 30, 112)), "always sees right next to itself")
	check(not vision.can_see(hero.global_position + Vector2(vision.vision_range + 10, 0)), "doesn't see past its range")

	var enemy := spawn_target(Vector2(320, 112))
	check(not enemy.visible, "enemies start hidden")
	await wait(2)
	check(not enemy.visible, "an enemy behind a wall stays hidden")
	enemy.position = Vector2(240, 112)
	await wait(2)
	check(enemy.visible, "an enemy in the cone is shown")
	enemy.position = Vector2(320, 112)
	await wait(2)
	check(not enemy.visible, "an enemy that leaves sight is hidden again")

	VisionComponent.reveal_all(0.2)
	await wait(2)
	check(enemy.visible, "a reveal shows hidden enemies")
	await create_timer(0.3).timeout
	await wait(2)
	check(not enemy.visible, "the reveal wears off")

	VisionComponent.grant_wall_sight(0.2)
	await wait(2)
	check(enemy.visible and not vision.shadow_enabled, "team wall-sight sees through walls")
	await create_timer(0.3).timeout
	await wait(2)
	check(not enemy.visible and vision.shadow_enabled, "team wall-sight wears off")

	hero.vision.active = false
	enemy.position = Vector2(240, 112)
	await wait(2)
	check(not enemy.visible and not hero.vision.enabled, "an inactive vision lights nothing and reveals nothing")
