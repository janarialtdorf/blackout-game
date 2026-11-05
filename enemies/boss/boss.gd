class_name Boss
extends Enemy
## An Enemy with a different attack: alternates an aimed burst with a ring of bullets.
## A level keeps its exit locked while any Boss in it is alive (see level.gd).

## Emitted once: the first time a hero sees the boss, or the boss notices a hero.
signal appeared

@export var burst_count: int = 3
## Seconds between the shots of a burst.
@export var burst_interval: float = 0.15
@export var ring_count: int = 12

var _ring_next := false
var _has_appeared := false


func _physics_process(delta: float) -> void:
	super(delta)
	if not _has_appeared and (visible or is_instance_valid(target)):
		_has_appeared = true
		appeared.emit()


func _attack() -> void:
	if not weapon.use_cooldown():
		return
	visual.play(&"shoot")
	_ring_next = not _ring_next
	if not _ring_next:
		for i in ring_count:
			weapon.fire_projectile(TAU * i / ring_count, weapon.stats.damage)
		return
	for i in burst_count:
		if health.current == 0:
			return
		weapon.fire_projectile(weapon.global_rotation, weapon.stats.damage)
		await get_tree().create_timer(burst_interval, false).timeout
