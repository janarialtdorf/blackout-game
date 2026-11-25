class_name RevealAbility
extends Ability
## Shows every hidden enemy for a while; optionally lets the whole team see through walls.

@export var duration: float = 3.0
@export var team_wall_sight: bool = false
## Camera zoom while the effect lasts and you play this hero (below 1 = see more). 0 = unchanged.
@export var camera_zoom: float = 0.0


func _apply(hero: Hero) -> void:
	VisionComponent.reveal_all(duration)
	if camera_zoom > 0.0:
		hero.override_camera_zoom(camera_zoom, duration)
	if team_wall_sight:
		VisionComponent.grant_wall_sight(duration)
