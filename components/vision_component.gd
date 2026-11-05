class_name VisionComponent
extends PointLight2D
## A hero's sight: lights up its vision shape (a cone, or a circle at 360 degrees) and,
## while active, hides every node in the "hidden_in_dark" group that it can't see.
## The light shape is generated from the numbers, so no texture asset is needed.

const TEXTURE_SIZE := 256

# Timed team-wide effects (Seer abilities), shared by every VisionComponent.
static var _reveal_until_msec := 0
static var _wall_sight_until_msec := 0

## Only the hero you control is active: its light is on and it decides what is visible.
@export var active: bool = true:
	set(value):
		active = value
		enabled = value

var vision_range: float
var angle_degrees: float
var sees_through_walls: bool
## Always see this close around the hero, even outside the cone.
var near_radius: float = 40.0


## Every hidden node is shown for this long, whatever the active hero can see.
static func reveal_all(seconds: float) -> void:
	_reveal_until_msec = Time.get_ticks_msec() + int(seconds * 1000.0)


## Every hero's vision sees through walls for this long.
static func grant_wall_sight(seconds: float) -> void:
	_wall_sight_until_msec = Time.get_ticks_msec() + int(seconds * 1000.0)


## Call once from the owner with its stats.
func configure(range_px: float, angle: float, through_walls: bool) -> void:
	vision_range = range_px
	angle_degrees = angle
	sees_through_walls = through_walls
	shadow_enabled = not through_walls
	texture = _make_texture()
	texture_scale = vision_range / (TEXTURE_SIZE / 2.0)


func _physics_process(_delta: float) -> void:
	if not active:
		return
	shadow_enabled = not _sees_through_walls_now()
	var revealed := Time.get_ticks_msec() < _reveal_until_msec
	for node: Node2D in get_tree().get_nodes_in_group(&"hidden_in_dark"):
		node.visible = revealed or can_see(node.global_position)


func can_see(point: Vector2) -> bool:
	var offset := point - global_position
	var distance := offset.length()
	if distance > vision_range:
		return false
	var in_cone := absf(angle_difference(global_rotation, offset.angle())) <= deg_to_rad(angle_degrees) / 2.0
	if distance > near_radius and not in_cone:
		return false
	return _sees_through_walls_now() or LineOfSight.is_clear(self, global_position, point)


func _sees_through_walls_now() -> bool:
	return sees_through_walls or Time.get_ticks_msec() < _wall_sight_until_msec


# White inside the vision shape, fading out toward the edge; black outside.
func _make_texture() -> ImageTexture:
	var image := Image.create_empty(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_L8)
	var center := Vector2.ONE * TEXTURE_SIZE / 2.0
	var near := near_radius / vision_range
	var half_angle := deg_to_rad(angle_degrees) / 2.0
	for y in TEXTURE_SIZE:
		for x in TEXTURE_SIZE:
			var offset := Vector2(x, y) + Vector2(0.5, 0.5) - center
			var distance := offset.length() / center.x # 0 at the hero, 1 at vision_range
			var in_shape := distance <= near or absf(offset.angle()) <= half_angle
			var brightness := clampf((1.0 - distance) / 0.25, 0.0, 1.0) if in_shape else 0.0
			image.set_pixel(x, y, Color(brightness, brightness, brightness))
	return ImageTexture.create_from_image(image)
