extends "res://src/Characters/Character.gd"

export var wash_x_offset := 16.0
export var wash_flip := false


func _ready() -> void:
	$SituationArea.connect('area_entered', self, '_check_if_wash')


func _check_if_wash(area: Area2D) -> void:
	prints(area.name)
	if randf() < 0.75:
		if _moving:
			$Tween.stop_all()
		
		position.x += wash_x_offset
		z_index += 2
		
		if wash_flip:
			scale.x = -1.0
		
		$AnimatedSprite.play('wash')
		yield($AnimatedSprite, 'animation_finished')
		
		scale.x = 1.0	
		position.x -= wash_x_offset
		z_index -= 2
		
		if _moving:
			$AnimatedSprite.play('move' + _animation_suffix)
			$Tween.resume_all()
		else:
			$AnimatedSprite.play('idle' + _animation_suffix)
