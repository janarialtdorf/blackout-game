class_name Hurtbox
extends Area2D
## The area where its owner can be hit. Give it a CollisionShape2D child and put it on the
## owner's hurtbox physics layer (hero_hurtbox / enemy_hurtbox). Damage goes to `health`.

@export var health: HealthComponent


## Returns the damage actually dealt.
func take_hit(damage: int) -> int:
	return health.take_damage(damage)
