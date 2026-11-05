class_name EnemyStats
extends Resource
## All tunable numbers and the look of one enemy type. A new enemy type = a new .tres of this.

## Shown on the boss health bar.
@export var display_name: String = "Enemy"
@export var max_health: int = 40
@export var move_speed: float = 120.0
## How far the enemy can see a hero (walls still block sight).
@export var sight_range: float = 250.0
## The enemy stops moving closer once it is this near a hero it can see.
@export var preferred_distance: float = 24.0
## The enemy only fires when a hero is within this distance.
@export var attack_range: float = 40.0
@export var weapon: WeaponStats
## How far pushes (e.g. the Fighter's shockwave) move this enemy. 0 = immovable.
@export var knockback_scale: float = 1.0
## A scene whose root uses visual.gd. Point this at your art scene to reskin the enemy.
@export var visual_scene: PackedScene
