class_name BeamAbility
extends Ability
## Instantly hits every enemy along a straight beam where the hero aims.

## Enemies are hit when their center is within width / 2 + this of the beam (their hurtbox radius).
const ENEMY_RADIUS := 14.0

@export var damage: int = 60
@export var length: float = 650.0
@export var width: float = 28.0
@export var through_walls: bool = true
## Drawn 100 px long (along +X, starting at the hero) and 100 px wide; stretched to the
## beam's size. Must free itself when done.
@export var beam_effect: PackedScene = preload("res://abilities/beam_effect.tscn")


func _apply(hero: Hero) -> void:
	var start := hero.global_position
	var end := start + Vector2.from_angle(hero.global_rotation) * length
	for enemy: Node2D in hero.get_tree().get_nodes_in_group(&"enemies"):
		var closest := Geometry2D.get_closest_point_to_segment(enemy.global_position, start, end)
		if closest.distance_to(enemy.global_position) > width / 2.0 + ENEMY_RADIUS:
			continue
		if not through_walls and not LineOfSight.is_clear(hero, start, closest):
			continue
		var health: HealthComponent = enemy.get_node_or_null(^"HealthComponent")
		if health:
			hero.ultimate.add_damage(health.take_damage(damage))
	if beam_effect:
		var effect: Node2D = beam_effect.instantiate()
		effect.position = start
		effect.rotation = hero.global_rotation
		effect.scale = Vector2(length, width) / 100.0
		hero.get_tree().current_scene.add_child(effect)
