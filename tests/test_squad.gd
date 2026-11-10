extends GameTest
## Switching heroes with 1/2/3 and the AI teammates.


func _run() -> void:
	await load_scene(TEST_ROOM, true)
	var team := squad()
	var fighter := team.heroes[0]
	var sniper := team.heroes[1]
	var seer := team.heroes[2]

	check(team.active == fighter and fighter.controlled and fighter.vision.active, "starts as hero 1 with its vision on")
	check(not sniper.vision.active and not seer.vision.active, "teammates' vision is off")

	var fighter_spot := fighter.global_position
	var sniper_spot := sniper.global_position
	_press("switch_2")
	check(sniper.global_position == fighter_spot and fighter.global_position == sniper_spot, "switching swaps the two heroes' places")
	var sniper_player: AnimationPlayer = sniper.visual.get_node("AnimationPlayer")
	check(sniper_player.current_animation == &"land", "the hero you switch to drops in")
	sniper.health.take_damage(1) # a hit mid-drop must not leave it stuck oversized
	await wait(30)
	check(sniper.visual.scale == Vector2.ONE and sniper.visual.modulate == Color.WHITE, "after the drop (even if hit mid-drop) the hero is normal size")
	await physics_frame
	check(team.active == sniper and sniper.controlled and not fighter.controlled, "key 2 switches control to hero 2")
	check(sniper.vision.active and not fighter.vision.active, "vision moves with control")
	_press("switch_3")
	await physics_frame
	check(team.active == sniper, "switching again right away is blocked by the shared cooldown")
	check(not team.try_switch(1), "switching to the active hero does nothing")
	check(is_equal_approx(team.get_node("SwitchCooldown").wait_time, 3.0), "the switch cooldown is 3 s")
	team.get_node("SwitchCooldown").stop()
	check(team.try_switch(2) and team.active == seer, "after the cooldown, switching works again")

	# Teleport the leader across the room; the AI teammates walk after it.
	seer.set_physics_process(false)
	seer.global_position = Vector2(464, 272)
	var spot := seer.global_position + fighter.follow_offset.rotated(seer.global_rotation)
	check(fighter.global_position.distance_to(spot) > Hero.FOLLOW_SLACK, "the teleport puts the teammate outside its free area")
	await wait(180)
	# A small margin: the teammate stops on the first frame it is inside the free area.
	check(fighter.global_position.distance_to(spot) <= Hero.FOLLOW_SLACK + 8.0, "AI teammates walk back into their free area behind the leader")
	check(fighter.global_position.distance_to(sniper.global_position) > 20.0, "teammates take different spots behind the leader")

	# An enemy in a teammate's clear line of fire gets shot.
	var target: Enemy
	for offset: Vector2 in [Vector2(60, 0), Vector2(0, 60), Vector2(-60, 0), Vector2(0, -60)]:
		if LineOfSight.is_clear(fighter, fighter.global_position, fighter.global_position + offset):
			target = spawn_target(fighter.global_position + offset)
			break
	await wait(60)
	check(damage_taken(target) > 0, "AI teammates shoot enemies they have a clear line to")


func _press(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	root.push_input(event)
