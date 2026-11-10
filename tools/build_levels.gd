extends SceneTree
## Turns every text map in res://levels/maps/ into a level scene res://levels/<name>.tscn.
## Run from the project folder:
##   & "C:\Program Files\Godot\Godot.exe.exe" --headless --path . --script res://tools/build_levels.gd
## WARNING: overwrites levels/<name>.tscn. Once you edit a level in the editor, delete its .txt.
##
## Map legend:  # wall   . floor   (space = nothing)   + every letter in PLACE (on floor):
##              P squad   X exit   C chaser   S shooter   B boss (locks the exit until dead)

const TILE_SIZE := 32
const TILE_SET_PATH := "res://levels/tiles/tile_set.tres"
const FLOOR := Vector2i(0, 0)
const WALL := Vector2i(1, 0)
const MAPS_DIR := "res://levels/maps/"
## Map letter -> scene placed on that tile.
const PLACE := {
	"P": preload("res://heroes/squad.tscn"),
	"X": preload("res://levels/level_exit.tscn"),
	"C": preload("res://enemies/chaser/chaser.tscn"),
	"S": preload("res://enemies/shooter/shooter.tscn"),
	"B": preload("res://enemies/boss/boss.tscn"),
}


func _init() -> void:
	var tile_set := _get_tile_set()
	for file in DirAccess.get_files_at(MAPS_DIR):
		if file.ends_with(".txt"):
			_build_level(file.get_basename(), tile_set)
	quit()


# Only created if missing, so art you add to the tile set in the editor is kept.
func _get_tile_set() -> TileSet:
	if ResourceLoader.exists(TILE_SET_PATH):
		return load(TILE_SET_PATH)
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1) # "walls" layer
	var source := TileSetAtlasSource.new()
	# Tiles stay invisible (they only carry collision and vision blocking); level_drawing.gd on the Tiles node draws the look.
	var blank := GradientTexture2D.new()
	blank.gradient = Gradient.new()
	blank.gradient.colors = PackedColorArray([Color.TRANSPARENT, Color.TRANSPARENT])
	blank.width = TILE_SIZE * 2
	blank.height = TILE_SIZE
	source.texture = blank
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	source.create_tile(FLOOR)
	source.create_tile(WALL)
	tile_set.add_source(source, 0)
	var half := TILE_SIZE / 2.0
	var square := PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)])
	var wall := source.get_tile_data(WALL, 0)
	wall.add_collision_polygon(0)
	wall.set_collision_polygon_points(0, 0, square)
	# Walls cast shadows for vision lights.
	tile_set.add_occlusion_layer()
	var occluder := OccluderPolygon2D.new()
	occluder.polygon = square
	wall.set_occluder_polygons_count(0, 1)
	wall.set_occluder_polygon(0, 0, occluder)
	ResourceSaver.save(tile_set, TILE_SET_PATH)
	tile_set.take_over_path(TILE_SET_PATH) # so levels link to the file instead of embedding a copy
	return tile_set


func _build_level(level_name: String, tile_set: TileSet) -> void:
	var root := Node2D.new()
	root.name = level_name.to_pascal_case()
	root.set_script(preload("res://levels/level.gd"))
	# level_<n> continues to level_<n + 1> when that map exists.
	if level_name.begins_with("level_"):
		var next := "level_%d" % (level_name.trim_prefix("level_").to_int() + 1)
		if FileAccess.file_exists(MAPS_DIR + next + ".txt"):
			root.next_level = "res://levels/%s.tscn" % next
	var tiles := LevelDrawing.new()
	tiles.name = "Tiles"
	tiles.tile_set = tile_set
	_add(root, tiles)
	var navigation := LevelNavigation.new()
	navigation.name = "LevelNavigation"
	navigation.tiles = tiles
	_add(root, navigation)
	var darkness := CanvasModulate.new()
	darkness.name = "Darkness"
	darkness.set_script(preload("res://levels/darkness.gd"))
	darkness.color = Color(0.5, 0.5, 0.5) # vision lights add the other half back (VisionComponent energy 0.5)
	darkness.visible = false
	_add(root, darkness)

	var lines := FileAccess.get_file_as_string(MAPS_DIR + level_name + ".txt").split("\n")
	for y in lines.size():
		for x in lines[y].length():
			var c := lines[y][x]
			var cell := Vector2i(x, y)
			if c == " " or c == "\r":
				continue
			tiles.set_cell(cell, 0, WALL if c == "#" else FLOOR)
			if c in PLACE:
				# Edit state = saved as a link to the scene, only changed properties stored.
				var placed: Node2D = PLACE[c].instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
				placed.position = tiles.map_to_local(cell)
				_add(root, placed)

	var scene := PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, "res://levels/%s.tscn" % level_name)
	root.free()
	print("Built level: ", level_name)


# Nodes are only saved into a scene if their owner is the scene root.
func _add(parent: Node, child: Node) -> void:
	parent.add_child(child, true) # readable names for duplicates: Chaser, Chaser2, ...
	child.owner = parent if parent.owner == null else parent.owner
