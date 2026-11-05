class_name WeaponStats
extends Resource
## All tunable numbers and the projectile look of one weapon.

## Damage per projectile (a shotgun shot deals this per pellet).
@export var damage: int = 10
## Shots per second.
@export var fire_rate: float = 2.0
@export var projectile_speed: float = 700.0
## How far a projectile flies before disappearing, in pixels.
@export var max_range: float = 400.0
## Projectiles per shot (more than 1 = shotgun).
@export var pellet_count: int = 1
## Total fan angle the pellets are spread across.
@export var spread_degrees: float = 0.0
## Bullets pass through enemies (hitting each once) and only stop at walls.
@export var pierces: bool = false
## A scene whose root uses visual.gd. Point this at your art scene to reskin the bullet.
@export var projectile_visual: PackedScene
