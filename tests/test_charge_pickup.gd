extends GameTest
## Charge pickups: the hero you control touches one and its hero's ultimate meter fills.

const SNIPER_CHARGE := preload("res://levels/charge_pickup_sniper.tscn")
const SEER_CHARGE := preload("res://levels/charge_pickup_seer.tscn")


func _run() -> void:
	await load_scene(TEST_ROOM, true)
	var team := squad()
	var fighter: Hero = team.heroes[0]
	var sniper: Hero = team.heroes[1]
	var seer: Hero = team.heroes[2]
	for hero in team.heroes:
		hero.set_physics_process(false) # stand where the test puts them
	check(team.active == fighter, "the Fighter starts controlled")

	# --- An AI teammate walking over it does nothing
	var pickup := _spawn(SNIPER_CHARGE, Vector2(176, 340))
	sniper.global_position = pickup.position
	await wait(3)
	check(is_instance_valid(pickup) and not sniper.ultimate.is_full(), "an AI teammate can't pick up a charge")

	# --- The controlled hero picks it up for the hero it names
	sniper.global_position = Vector2(176, 112)
	fighter.global_position = pickup.position
	await wait(3)
	check(sniper.ultimate.is_full(), "touching a Sniper charge fills the Sniper's meter")
	check(not fighter.ultimate.is_full(), "it doesn't charge the hero who touched it")
	check(not is_instance_valid(pickup), "a charge is used up")

	# --- A dead hero's charge stays
	fighter.global_position = Vector2(176, 112)
	await wait(3)
	pickup = _spawn(SEER_CHARGE, Vector2(240, 340))
	seer.health.take_damage(seer.health.current)
	await physics_frame
	fighter.global_position = pickup.position
	await wait(3)
	check(is_instance_valid(pickup), "a dead hero's charge can't be picked up and stays")


func _spawn(scene: PackedScene, at: Vector2) -> ChargePickup:
	var pickup: ChargePickup = scene.instantiate()
	pickup.position = at
	current_scene.add_child(pickup)
	return pickup
