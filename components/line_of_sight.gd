class_name LineOfSight
## Shared "is there a wall in between?" check used by enemies, vision and AI teammates.


static func is_clear(any_node: Node2D, from: Vector2, to: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(from, to, 1) # walls
	return any_node.get_world_2d().direct_space_state.intersect_ray(query).is_empty()
