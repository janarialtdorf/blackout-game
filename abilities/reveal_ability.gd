class_name RevealAbility
extends Ability
## Shows every hidden enemy for a while; optionally lets the whole team see through walls.

@export var duration: float = 3.0
@export var team_wall_sight: bool = false


func _apply(_hero: Hero) -> void:
	VisionComponent.reveal_all(duration)
	if team_wall_sight:
		VisionComponent.grant_wall_sight(duration)
