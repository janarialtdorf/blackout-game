class_name HUD
extends CanvasLayer
## The squad panel on the left. The Squad calls show_squad() once and set_active() on every switch.

const HERO_CARD := preload("res://ui/hero_card.tscn")

var _switch_cooldown: Timer
var _cards: Dictionary[Hero, HeroCard] = {}

@onready var _card_list: VBoxContainer = %Cards
@onready var _cooldown_bar: ProgressBar = %SwitchCooldownBar
@onready var _cooldown_seconds: Label = %Seconds


func show_squad(heroes: Array[Hero], switch_cooldown: Timer) -> void:
	_switch_cooldown = switch_cooldown
	for i in heroes.size():
		var card: HeroCard = HERO_CARD.instantiate()
		_card_list.add_child(card)
		card.show_hero(heroes[i], i + 1)
		_cards[heroes[i]] = card


func set_active(active: Hero) -> void:
	for hero in _cards:
		_cards[hero].set_active(hero == active)


func _process(_delta: float) -> void:
	if _switch_cooldown:
		_cooldown_bar.max_value = _switch_cooldown.wait_time
		_cooldown_bar.value = _switch_cooldown.time_left
		_cooldown_seconds.text = str(ceili(_switch_cooldown.time_left)) if _switch_cooldown.time_left > 0.0 else ""
