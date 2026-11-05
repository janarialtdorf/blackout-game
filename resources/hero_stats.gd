class_name HeroStats
extends Resource
## All tunable numbers and the look of one hero. A new hero = a new .tres of this.

@export var display_name: String = "Hero"
## Optional HUD picture. Leave empty to show just the name.
@export var portrait: Texture2D
@export var max_health: int = 100
@export var move_speed: float = 200.0
@export var weapon: WeaponStats
## Fires when the player switches to this hero while its ultimate meter is full.
@export var ultimate: Ability
@export_group("Vision")
## How far the hero can see, in pixels.
@export var vision_range: float = 260.0
## Width of the vision cone. 360 = a full circle.
@export_range(10.0, 360.0) var vision_angle: float = 90.0
## Sees (and lights up) through walls.
@export var sees_through_walls: bool = false
@export_group("")
## A scene whose root uses visual.gd. Point this at your art scene to reskin the hero.
@export var visual_scene: PackedScene
