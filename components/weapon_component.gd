class_name WeaponComponent
extends Node2D
## Fires projectiles in the direction this node faces. Place it at the muzzle.

## Emitted whenever one of this weapon's projectiles damages something.
signal damage_dealt(amount: int)

const PROJECTILE_SCENE := preload("res://weapons/projectile.tscn")

@export var stats: WeaponStats
## What stops this weapon's bullets: walls + the targets' hurtbox layer.
@export_flags_2d_physics var hit_mask: int = 1

@onready var _cooldown: Timer = $Cooldown


## Returns true if a shot was fired (false while on cooldown).
func try_fire() -> bool:
	if not use_cooldown():
		return false
	for i in stats.pellet_count:
		fire_projectile(global_rotation + deg_to_rad(_pellet_angle(i)), stats.damage)
	return true


## Starts the fire-rate cooldown without shooting. Returns false if it is still running.
## For custom attack patterns that fire their own projectiles.
func use_cooldown() -> bool:
	if not _cooldown.is_stopped():
		return false
	_cooldown.start(1.0 / stats.fire_rate)
	return true


## Fires one projectile right now, ignoring the cooldown (used by abilities too).
func fire_projectile(angle: float, damage: int) -> void:
	var projectile: Projectile = PROJECTILE_SCENE.instantiate()
	projectile.speed = stats.projectile_speed
	projectile.max_distance = stats.max_range
	projectile.damage = damage
	projectile.hit_mask = hit_mask
	projectile.pierces = stats.pierces
	projectile.weapon = self
	projectile.position = global_position
	projectile.rotation = angle
	projectile.add_child(stats.projectile_visual.instantiate())
	# Added to the level, not to us, so bullets don't move with the shooter.
	get_tree().current_scene.add_child(projectile)


func _pellet_angle(i: int) -> float:
	if stats.pellet_count == 1:
		return 0.0
	var half := stats.spread_degrees / 2.0
	return lerpf(-half, half, float(i) / (stats.pellet_count - 1))
