extends "res://src/Characters/Character.gd"


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func repositionate() -> void:
	match $AnimatedSprite.animation:
		'move_up', 'move_down':
			$CollisionShape2D.disabled = true
			$VerticalCollisionShape.disabled = false
			$AnimatedSprite.position = Vector2(0.0, -84.0)
		_:
			$CollisionShape2D.disabled = false
			$VerticalCollisionShape.disabled = true
			$AnimatedSprite.position = Vector2(69.0, -62.0)


func check_flip(have_to_flip: bool) -> void:
	if _animation_suffix == '':
		.check_flip(have_to_flip)
