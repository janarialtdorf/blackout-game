class_name Squad
extends Node2D
## The player's team. Its Hero children are the squad in key order (1, 2, 3...).
## Number keys switch which hero you control; the others follow as AI teammates.

## Every hero is down.
signal wiped

## Where teammates walk to, behind the hero you control (x = forward, y = sideways).
const FOLLOW_OFFSETS: Array[Vector2] = [Vector2(-120, -90), Vector2(-80, 60)]

## Seconds after a switch before you can switch again (shared by all heroes).
@export var switch_cooldown: float = 3.0

var heroes: Array[Hero] = []
var active: Hero

@onready var camera: Camera2D = $Camera2D
@onready var _cooldown: Timer = $SwitchCooldown
@onready var _hud: HUD = $HUD


func _ready() -> void:
	heroes.assign(get_children().filter(func(node: Node) -> bool: return node is Hero))
	for hero in heroes:
		hero.health.died.connect(_on_hero_died.bind(hero))
	_hud.show_squad(heroes, _cooldown)
	_set_active(heroes[0])
	camera.global_position = active.global_position
	camera.reset_smoothing()


func _physics_process(_delta: float) -> void:
	camera.global_position = active.global_position


func _unhandled_input(event: InputEvent) -> void:
	for i in heroes.size():
		if event.is_action_pressed("switch_%d" % (i + 1)):
			try_switch(i)


## Switches control to heroes[index]. Returns false if it's already active, dead, or on cooldown.
func try_switch(index: int) -> bool:
	var hero := heroes[index]
	if hero == active or not hero.is_alive() or not _cooldown.is_stopped():
		return false
	_cooldown.start(switch_cooldown)
	_set_active(hero)
	hero.switch_in()
	return true


func _set_active(hero: Hero) -> void:
	active = hero
	_hud.set_active(hero)
	var slot := 0
	for member in heroes:
		member.controlled = member == hero and member.is_alive()
		member.leader = hero
		if member != hero and member.is_alive():
			member.follow_offset = FOLLOW_OFFSETS[slot % FOLLOW_OFFSETS.size()]
			slot += 1


# Losing the hero you control hands control to a living one (no ultimate: it wasn't your choice).
func _on_hero_died(hero: Hero) -> void:
	var living := heroes.filter(func(member: Hero) -> bool: return member.is_alive())
	if living.is_empty():
		wiped.emit()
	elif hero == active:
		_set_active(living[0])
