extends "res://src/Characters/Character.gd"


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	$Timer.connect('timeout', self, '_check_if_sweep')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func sweep() -> void:
	$AnimatedSprite.play('sweep' + _animation_suffix)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _check_if_sweep() -> void:
	if randf() > 0.5:
		if _moving:
			$Tween.stop_all()
		
		sweep()
		
		yield(get_tree().create_timer(3.0), 'timeout')
		
		if _moving:
			$AnimatedSprite.play('move' + _animation_suffix)
			$Tween.resume_all()
		else:
			$AnimatedSprite.play('idle' + _animation_suffix)
