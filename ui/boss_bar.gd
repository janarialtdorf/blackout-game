class_name BossBar
extends CanvasLayer
## A big health bar at the top of the screen for one boss. Frees itself when the boss dies.

@onready var _name: Label = %Name
@onready var _bar: ProgressBar = %Bar


func show_boss(boss: Enemy) -> void:
	_name.text = boss.stats.display_name
	_bar.max_value = boss.health.max_health
	_bar.value = boss.health.current
	boss.health.health_changed.connect(_on_health_changed)
	boss.health.died.connect(queue_free)


func _on_health_changed(current: int, _maximum: int) -> void:
	_bar.value = current
