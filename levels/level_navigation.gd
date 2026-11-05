class_name LevelNavigation
extends NavigationRegion2D
## Builds the walkable area for NavigationAgent2D at level start: everything inside the
## tile map, minus the walls, shrunk by agent_radius so paths don't clip wall corners.
## Repaint the level freely; this re-bakes every time the level loads.

@export var tiles: TileMapLayer
## Keep paths this far from walls. Should be >= the largest walker's collision radius.
@export var agent_radius: float = 14.0


func _ready() -> void:
	var area := Rect2(tiles.get_used_rect().position * tiles.tile_set.tile_size, tiles.get_used_rect().size * tiles.tile_set.tile_size)
	var polygon := NavigationPolygon.new()
	polygon.agent_radius = agent_radius
	polygon.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_STATIC_COLLIDERS
	polygon.parsed_collision_mask = 1 # walls
	polygon.add_outline(PackedVector2Array([area.position, Vector2(area.end.x, area.position.y), area.end, Vector2(area.position.x, area.end.y)]))
	var source := NavigationMeshSourceGeometryData2D.new()
	NavigationServer2D.parse_source_geometry_data(polygon, source, tiles)
	NavigationServer2D.bake_from_source_geometry_data(polygon, source)
	navigation_polygon = polygon
