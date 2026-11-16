class_name Enemy
extends CharacterBody2D
## Idles (or patrols) until it sees a hero or gets hurt, then walks to preferred_distance and attacks.

const PATROL_SPEED_SCALE := 0.5
const NOTICE_MARK := preload("res://enemies/exclamation.tscn")

@export var stats: EnemyStats
## While idle, walk straight ahead (where the enemy faces) and turn around at walls.
@export var patrol: bool = false

var visual: Visual
var target: Node2D:
	set(value):
		if value != null and value != target:
			add_child(NOTICE_MARK.instantiate()) # "!" when it notices a hero
		target = value

@onready var health: HealthComponent = $HealthComponent
@onready var weapon: WeaponComponent = $WeaponComponent
@onready var nav: NavigationAgent2D = $NavigationAgent2D
@onready var knockback: KnockbackComponent = $KnockbackComponent
@onready var sight_cone: SightCone = $SightCone


func _ready() -> void:
	visible = false # hidden until a hero's vision sees it
	visual = stats.visual_scene.instantiate()
	add_child(visual)
	health.max_health = stats.max_health
	sight_cone.sight_range = stats.sight_range
	sight_cone.angle_degrees = stats.sight_angle
	sight_cone.visible = stats.sight_angle < 360.0 # an all-round view would just be a blob
	weapon.stats = stats.weapon
	health.health_changed.connect(_on_hurt)
	health.died.connect(_on_died)


## Pushes the enemy; the push fades out over a fraction of a second.
func knock_back(push: Vector2) -> void:
	knockback.push(push * stats.knockback_scale)


func _physics_process(delta: float) -> void:
	if knockback.is_active():
		velocity = knockback.step(delta)
		move_and_slide()
		return
	if not is_instance_valid(target) or not target.is_in_group(&"heroes"): # gone or dead
		target = _find_visible_hero()
		_idle()
		return
	var sees := _can_see(target)
	if sees and global_position.distance_to(target.global_position) <= stats.preferred_distance:
		velocity = Vector2.ZERO
	else:
		nav.target_position = target.global_position
		velocity = global_position.direction_to(nav.get_next_path_position()) * stats.move_speed
	move_and_slide()
	visual.play(&"walk" if velocity != Vector2.ZERO else &"idle")
	if sees:
		look_at(target.global_position)
		if global_position.distance_to(target.global_position) <= stats.attack_range:
			_attack()


func _idle() -> void:
	if not patrol:
		visual.play(&"idle")
		return
	velocity = Vector2.from_angle(rotation) * stats.move_speed * PATROL_SPEED_SCALE
	move_and_slide()
	if is_on_wall():
		rotation += PI
	visual.play(&"walk")


## Called every physics frame while a target is visible and in attack range. Override for other attacks.
func _attack() -> void:
	if weapon.try_fire():
		visual.play(&"shoot")


# Noticing uses the view cone; once it has a target the enemy turns to face it anyway.
func _find_visible_hero() -> Node2D:
	for hero: Node2D in get_tree().get_nodes_in_group(&"heroes"):
		var off_center := absf(angle_difference(global_rotation, global_position.angle_to_point(hero.global_position)))
		if off_center <= deg_to_rad(stats.sight_angle) / 2.0 and _can_see(hero):
			return hero
	return null


func _can_see(hero: Node2D) -> bool:
	if global_position.distance_to(hero.global_position) > stats.sight_range:
		return false
	return LineOfSight.is_clear(self, global_position, hero.global_position)


# Getting shot wakes the enemy up even if it can't see the shooter.
func _on_hurt(_current: int, _maximum: int) -> void:
	visual.play(&"hurt")
	if not is_instance_valid(target) or not target.is_in_group(&"heroes"):
		target = _closest_hero()


func _closest_hero() -> Node2D:
	var closest: Node2D = null
	for hero: Node2D in get_tree().get_nodes_in_group(&"heroes"):
		if closest == null or global_position.distance_to(hero.global_position) < global_position.distance_to(closest.global_position):
			closest = hero
	return closest


func _on_died() -> void:
	set_physics_process(false)
	sight_cone.hide()
	set_deferred(&"collision_layer", 0)
	$Hurtbox.set_deferred(&"collision_layer", 0)
	await visual.play_to_end(&"die")
	queue_free()
