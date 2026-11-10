@tool
class_name BodyDrawing
extends Node2D
## Flat agar.io-style body: a solid shape, an outline in a darker shade of the same colour,
## and an optional gun barrel on +X. Shared by every hero, enemy, boss and bullet look.
## @tool makes it draw in the editor too, so you see colour/size changes right away.

enum Shape { CIRCLE, TRIANGLE }

const BARREL_COLOR := Color(0.1, 0.1, 0.1)
## Hurt flash colour: an off-white, so it shows on red enemies too.
const FLASH_COLOR := Color(0.85, 0.85, 0.85)

@export var color := Color.WHITE:
	set(value): color = value; queue_redraw()
@export var radius := 12.0:
	set(value): radius = value; queue_redraw()
@export var shape := Shape.CIRCLE:
	set(value): shape = value; queue_redraw()
@export var barrel := true:
	set(value): barrel = value; queue_redraw()
@export var outline_width := 3.0:
	set(value): outline_width = value; queue_redraw()
## 0 = normal colour, 1 = fully FLASH_COLOR. The "hurt" animation drives this.
@export_range(0.0, 1.0) var flash := 0.0:
	set(value): flash = value; queue_redraw()


func _draw() -> void:
	if barrel:
		draw_rect(Rect2(radius * 0.4, -radius * 0.3, radius, radius * 0.6), BARREL_COLOR)
	# A triangle's edges are only half as far from its centre as its corners, so inset twice as much.
	var inset := outline_width * (2.0 if shape == Shape.TRIANGLE else 1.0)
	_draw_shape(radius, color.darkened(0.35))
	_draw_shape(radius - inset, color.lerp(FLASH_COLOR, flash))


func _draw_shape(r: float, fill: Color) -> void:
	if shape == Shape.CIRCLE:
		draw_circle(Vector2.ZERO, r, fill, true, -1.0, true)
	else:
		var tip := Vector2(r, 0.0)
		draw_colored_polygon(PackedVector2Array([tip, tip.rotated(TAU / 3.0), tip.rotated(-TAU / 3.0)]), fill)
