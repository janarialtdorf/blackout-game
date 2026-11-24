extends AnimatedSprite2D
## "!" shown above an enemy when it notices a hero. Plays once, then frees itself.

const HEIGHT := 30.0 # px above the enemy's centre


# The enemy rotates to face its target; keep the mark upright and above it.
func _process(_delta: float) -> void:
	global_rotation = 0.0
	global_position = get_parent().global_position + Vector2(0, -HEIGHT)
