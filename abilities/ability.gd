class_name Ability
extends Resource
## A hero's ultimate: fires when the player switches to the hero with a full meter.
## Subclasses implement _apply(). Their numbers are @export, so each .tres tunes them.

## Optional one-shot effect spawned at the hero. It must free itself when done.
@export var effect_scene: PackedScene


func activate(hero: Hero) -> void:
	if effect_scene:
		var effect: Node2D = effect_scene.instantiate()
		effect.position = hero.global_position
		effect.scale *= _effect_scale()
		hero.get_tree().current_scene.add_child(effect)
	_apply(hero)


func _apply(_hero: Hero) -> void:
	pass


## Effects are authored at a radius of 100 px; override to fit the ability's size.
func _effect_scale() -> float:
	return 1.0
