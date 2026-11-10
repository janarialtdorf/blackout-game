class_name Hero
extends CharacterBody2D
## One squad member. Controlled by the player, or (when not controlled) an AI teammate
## that follows the leader and shoots the nearest enemy it has a clear line to.

## Teammates stop walking once they are this close to their spot behind the leader.
const FOLLOW_SLACK := 120.0

@export var stats: HeroStats

## Set by the Squad. The controlled hero takes input and owns the vision.
var controlled := true:
	set(value):
		controlled = value
		vision.active = value
var leader: Hero
## Where this teammate walks to, relative to the leader (rotates with the leader).
var follow_offset := Vector2.ZERO
var visual: Visual

@onready var weapon: WeaponComponent = $WeaponComponent
@onready var health: HealthComponent = $HealthComponent
@onready var vision: VisionComponent = $VisionComponent
@onready var nav: NavigationAgent2D = $NavigationAgent2D
@onready var ultimate: UltimateComponent = $UltimateComponent


func _ready() -> void:
	visual = stats.visual_scene.instantiate()
	add_child(visual)
	weapon.stats = stats.weapon
	health.max_health = stats.max_health
	vision.configure(stats.vision_range, stats.vision_angle, stats.sees_through_walls)
	health.health_changed.connect(func(_current: int, _maximum: int) -> void: visual.play(&"hurt"))
	health.died.connect(_on_died)
	weapon.damage_dealt.connect(ultimate.add_damage)


## Called by the Squad when the player switches to this hero: fires the ultimate if the meter is full.
func switch_in() -> void:
	if ultimate.is_full() and stats.ultimate:
		look_at(get_global_mouse_position())
		stats.ultimate.activate(self)
		ultimate.consume() # after, so the ultimate's own damage doesn't recharge it


func _physics_process(_delta: float) -> void:
	if controlled:
		_player_control()
	else:
		_ai_control()
	move_and_slide()
	visual.play(&"walk" if velocity != Vector2.ZERO else &"idle")


func _player_control() -> void:
	velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down") * stats.move_speed
	look_at(get_global_mouse_position())
	if Input.is_action_pressed("shoot"):
		_fire()


func _ai_control() -> void:
	var spot := leader.global_position + follow_offset.rotated(leader.global_rotation)
	if global_position.distance_to(spot) > FOLLOW_SLACK:
		nav.target_position = spot
		velocity = global_position.direction_to(nav.get_next_path_position()) * stats.move_speed
	else:
		velocity = Vector2.ZERO
	var enemy := _nearest_shootable_enemy()
	if enemy:
		look_at(enemy.global_position)
		_fire()
	elif velocity != Vector2.ZERO:
		rotation = velocity.angle()


func _fire() -> void:
	if weapon.try_fire():
		visual.play(&"shoot")


func _nearest_shootable_enemy() -> Node2D:
	var nearest: Node2D = null
	var nearest_distance := stats.weapon.max_range
	for enemy: Node2D in get_tree().get_nodes_in_group(&"enemies"):
		var distance := global_position.distance_to(enemy.global_position)
		if distance < nearest_distance and LineOfSight.is_clear(self, global_position, enemy.global_position):
			nearest = enemy
			nearest_distance = distance
	return nearest


func is_alive() -> bool:
	return health.current > 0


# Dead heroes stay on the floor for the rest of the level. The Squad handles switching away.
func _on_died() -> void:
	remove_from_group(&"heroes") # enemies stop targeting it
	set_physics_process(false)
	ultimate.set_process(false)
	vision.active = false
	set_deferred(&"collision_layer", 0)
	$Hurtbox.set_deferred(&"collision_layer", 0)
	await visual.play_to_end(&"die")
	visual.modulate = Color(0.35, 0.35, 0.35, 0.7)
