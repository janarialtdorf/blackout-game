class_name BlastAbility
extends Ability
## Damages and pushes away every enemy within radius that the hero has a clear line to.

@export var radius: float = 120.0
@export var damage: int = 15
## Push speed in px/s, fading out quickly.
@export var knockback: float = 500.0


func _apply(hero: Hero) -> void:
	for enemy: Node2D in hero.get_tree().get_nodes_in_group(&"enemies"):
		var distance := hero.global_position.distance_to(enemy.global_position)
		if distance > radius or not LineOfSight.is_clear(hero, hero.global_position, enemy.global_position):
			continue
		var health: HealthComponent = enemy.get_node_or_null(^"HealthComponent")
		if health:
			hero.ultimate.add_damage(health.take_damage(damage))
		if enemy is Enemy:
			enemy.knock_back(hero.global_position.direction_to(enemy.global_position) * knockback)


func _effect_scale() -> float:
	return radius / 100.0
