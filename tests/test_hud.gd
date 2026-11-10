extends GameTest
## The squad HUD: one card per hero with HP and ultimate bars, plus the switch cooldown bar.


func _run() -> void:
	await load_scene(TEST_ROOM, true)
	var team := squad()
	var hud := team.get_node("HUD")
	var cards: Array[Node] = hud.find_children("*", "HeroCard", true, false)
	check(cards.size() == team.heroes.size(), "one card per hero")
	var card: HeroCard = cards[0]
	var fighter := team.heroes[0]
	check(card.get_node("%Title").text == "1   Fighter", "a card shows the hero's key and name")
	check(card.get_theme_stylebox(&"panel") == card.active_style, "the controlled hero's card is highlighted")
	check(cards[1].get_theme_stylebox(&"panel") == cards[1].normal_style, "other cards are not")

	fighter.health.take_damage(30)
	var health_bar: ProgressBar = card.get_node("%HealthBar")
	check(health_bar.value == fighter.health.current and health_bar.max_value == fighter.health.max_health, "the HP bar follows the hero's health")

	fighter.ultimate.set_process(false)
	fighter.ultimate.charge = 50.0
	fighter.ultimate.add_damage(5)
	var ultimate_bar: ProgressBar = card.get_node("%UltimateBar")
	check(ultimate_bar.value == fighter.ultimate.charge, "the ultimate bar follows the meter")
	check(ultimate_bar.get_theme_stylebox(&"fill") != card.ultimate_full_style, "a part-full ultimate bar keeps its normal colour")
	fighter.ultimate.add_damage(1000)
	check(ultimate_bar.get_theme_stylebox(&"fill") == card.ultimate_full_style, "a full ultimate bar changes colour (gold)")

	var cooldown_bar: ProgressBar = hud.get_node("%SwitchCooldownBar")
	check(team.try_switch(1), "switch to hero 2")
	await process_frame
	check(cards[1].get_theme_stylebox(&"panel") == cards[1].active_style and card.get_theme_stylebox(&"panel") == card.normal_style, "the highlight moves on switch")
	check(cooldown_bar.value > 0.0 and cooldown_bar.max_value == 3.0, "the cooldown bar shows the switch cooldown")
	check(hud.get_node("%Seconds").text == "3", "the cooldown box shows the seconds left")

	team.heroes[2].health.take_damage(team.heroes[2].health.max_health)
	check(cards[2].modulate != Color.WHITE, "a dead hero's card is greyed out")
