class_name LineOfSight
## Shared "is there a wall in between?" check used by enemies, vision and AI teammates.


static func is_clear(any_node: Node2D, from: Vector2, to: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(from, to, 1) # walls
	return any_node.get_world_2d().direct_space_state.intersect_ray(query).is_empty()


## Where a straight line from `from` to `to` first hits a wall, or `to` if nothing is in the way.
static func reach(any_node: Node2D, from: Vector2, to: Vector2) -> Vector2:
	var query := PhysicsRayQueryParameters2D.create(from, to, 1) # walls
	return any_node.get_world_2d().direct_space_state.intersect_ray(query).get("position", to)
