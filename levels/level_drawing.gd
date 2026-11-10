@tool
class_name LevelDrawing
extends TileMapLayer
## The level's tiles, drawn in the flat art style: the whole map area in one floor colour, plus
## a thick line wherever a wall tile meets a non-wall tile. The tile texture itself is invisible;
## tiles only carry collision and vision blocking. @tool so the editor redraws while you paint.

const WALL := Vector2i(1, 0)
const SIDES: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

## Near-white, so it looks bright inside vision; the Darkness dims it to grey everywhere else.
@export var floor_color := Color(0.93, 0.93, 0.92):
	set(value): floor_color = value; queue_redraw()
@export var line_color := Color.BLACK:
	set(value): line_color = value; queue_redraw()
@export var line_width := 4.0:
	set(value): line_width = value; queue_redraw()


# Godot calls this whenever cells are loaded, painted or erased.
func _update_cells(_coords: Array[Vector2i], _forced_cleanup: bool) -> void:
	queue_redraw()


func _draw() -> void:
	if not tile_set:
		return
	var size := Vector2(tile_set.tile_size)
	for cell in get_used_cells():
		draw_rect(Rect2(map_to_local(cell) - size / 2.0, size), floor_color)
	for cell in get_used_cells_by_id(0, WALL):
		for side in SIDES:
			if get_cell_atlas_coords(cell + side) != WALL:
				var middle := map_to_local(cell) + Vector2(side) * size / 2.0
				# Half a line longer at each end, so lines meet without gaps at corners.
				var along := Vector2(side).orthogonal() * (size.x + line_width) / 2.0
				draw_line(middle - along, middle + along, line_color, line_width)
