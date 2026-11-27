class_name DialogueLine
extends Resource
## One line of a Dialogue: who says it, what they say, and which side they stand on.

@export var speaker: Speaker
@export_multiline var text := ""
## Stand in the right portrait slot (mirrored) instead of the left.
@export var right := false
