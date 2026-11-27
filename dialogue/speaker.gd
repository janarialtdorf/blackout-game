class_name Speaker
extends Resource
## Someone who talks in a cutscene. One .tres per character, shared by every Dialogue.

@export var display_name := ""
## The name tab colour, and the placeholder circle's colour.
@export var color := Color.WHITE
## Tall art facing right (e.g. 400×600); the right slot mirrors it. Empty = a big circle in `color`.
@export var portrait: Texture2D
## Off = a voice only (e.g. HQ): name tab, no portrait.
@export var on_screen := true
