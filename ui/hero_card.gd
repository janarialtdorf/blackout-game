class_name HeroCard
extends PanelContainer
## One hero's box in the HUD: key + name, HP bar and ultimate bar.
## It only listens to the hero's signals; it never changes the hero.

@export var normal_style: StyleBox
## Panel look for the hero you control.
@export var active_style: StyleBox
@export var ultimate_full_style: StyleBox

var _ultimate_fill_style: StyleBox

@onready var _title: Label = %Title
@onready var _portrait: TextureRect = %Portrait
@onready var _health_bar: ProgressBar = %HealthBar
@onready var _ultimate_bar: ProgressBar = %UltimateBar


func _ready() -> void:
	_ultimate_fill_style = _ultimate_bar.get_theme_stylebox(&"fill")


func show_hero(hero: Hero, key: int) -> void:
	_title.text = "%d   %s" % [key, hero.stats.display_name]
	_portrait.texture = hero.stats.portrait
	_portrait.visible = hero.stats.portrait != null
	_on_health_changed(hero.health.current, hero.health.max_health)
	_on_charge_changed(hero.ultimate.charge)
	hero.health.health_changed.connect(_on_health_changed)
	hero.health.died.connect(_on_died)
	hero.ultimate.charge_changed.connect(_on_charge_changed)


func set_active(active: bool) -> void:
	add_theme_stylebox_override(&"panel", active_style if active else normal_style)


# A full ultimate bar pulses so it catches the eye.
func _process(_delta: float) -> void:
	if _ultimate_bar.value >= _ultimate_bar.max_value:
		_ultimate_bar.self_modulate.a = 0.75 + 0.25 * sin(Time.get_ticks_msec() / 120.0)


func _on_health_changed(current: int, maximum: int) -> void:
	_health_bar.max_value = maximum
	_health_bar.value = current


func _on_charge_changed(charge: float) -> void:
	_ultimate_bar.value = charge
	var full := charge >= _ultimate_bar.max_value
	_ultimate_bar.add_theme_stylebox_override(&"fill", ultimate_full_style if full else _ultimate_fill_style)
	if not full:
		_ultimate_bar.self_modulate.a = 1.0


func _on_died() -> void:
	modulate = Color(0.45, 0.45, 0.45, 0.8)
