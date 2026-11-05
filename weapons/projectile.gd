class_name Projectile
extends Node2D
## Flies straight forward until it hits something in hit_mask or reaches max_distance.

var speed: float
var max_distance: float
var damage: int
## Physics layers that stop this bullet: walls + the targets' hurtbox layer.
var hit_mask: int = 1
## Pass through hurtboxes (each is hit once); only walls stop the bullet.
var pierces: bool = false
## The weapon that fired this, told about damage dealt (may be gone by the time we hit).
var weapon: WeaponComponent

var _travelled := 0.0
var _already_hit: Array[RID] = []


# Casts a ray over the distance moved this frame, so nothing is skipped at any speed.
func _physics_process(delta: float) -> void:
	var step := speed * delta
	var target := global_position + transform.x * step
	var query := PhysicsRayQueryParameters2D.create(global_position, target, hit_mask)
	query.collide_with_areas = true
	query.hit_from_inside = true
	query.exclude = _already_hit
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	# A piercing bullet re-casts past each hurtbox it hits, until a wall or nothing.
	while hit and pierces and hit.collider is Hurtbox:
		_damage(hit.collider)
		_already_hit.append(hit.rid)
		query.exclude = _already_hit
		hit = get_world_2d().direct_space_state.intersect_ray(query)
	if hit:
		if hit.collider is Hurtbox:
			_damage(hit.collider)
		queue_free()
		return
	global_position = target
	_travelled += step
	if _travelled >= max_distance:
		queue_free()


func _damage(hurtbox: Hurtbox) -> void:
	var dealt := hurtbox.take_hit(damage)
	if is_instance_valid(weapon):
		weapon.damage_dealt.emit(dealt)
