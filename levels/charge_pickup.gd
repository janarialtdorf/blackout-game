class_name ChargePickup
extends Area2D
## Fills one hero's ultimate meter when the hero you control touches it, so switching to that
## hero fires its ultimate. Used once; stays put while that hero is dead.

## The hero it charges (matched by stats). The look's colour should match that hero.
@export var hero: HeroStats

const RING_COLOR := Color(1.0, 0.8, 0.1) # gold: the ultimate colour
const RING_RADIUS := 11.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not (body is Hero and body.controlled):
		return
	for member: Hero in get_tree().get_nodes_in_group(&"heroes"): # living heroes only
		if member.stats == hero:
			member.ultimate.fill()
			queue_free()
			return


func _draw() -> void:
	draw_arc(Vector2.ZERO, RING_RADIUS, 0.0, TAU, 32, RING_COLOR, 2.0, true)
