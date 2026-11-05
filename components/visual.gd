class_name Visual
extends Node2D
## The swap point for art. Root of every hero/enemy/projectile look.
## To add art: put an AnimatedSprite2D and/or AnimationPlayer as a child of this node
## (art should face RIGHT). Gameplay calls play() with: idle, walk, shoot, hurt, die.
## Missing animations are simply ignored, so the game works with any subset.
## Untick "loop" on shoot/hurt/die: a looping animation (idle, walk) never cuts off
## a non-looping one that is still playing.


func play(anim: StringName) -> void:
	for child in get_children():
		if child is AnimatedSprite2D and child.sprite_frames and child.sprite_frames.has_animation(anim):
			var frames: SpriteFrames = child.sprite_frames
			if not (child.is_playing() and not frames.get_animation_loop(child.animation) and frames.get_animation_loop(anim)):
				child.play(anim)
		elif child is AnimationPlayer and child.has_animation(anim):
			if not (child.is_playing() and not _loops(child, child.current_animation) and _loops(child, anim)):
				child.play(anim)


## Plays anim and waits for it to end. Returns at once if there is no such animation.
## Use with `await`, e.g. `await visual.play_to_end(&"die")`.
func play_to_end(anim: StringName) -> void:
	for child in get_children():
		if (child is AnimatedSprite2D and child.sprite_frames and child.sprite_frames.has_animation(anim)) \
				or (child is AnimationPlayer and child.has_animation(anim)):
			child.play(anim)
			await child.animation_finished
			return


func _loops(player: AnimationPlayer, anim: StringName) -> bool:
	return player.get_animation(anim).loop_mode != Animation.LOOP_NONE
