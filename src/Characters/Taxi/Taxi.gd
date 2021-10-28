tool
extends "res://src/Characters/Character.gd"


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	add_to_group('Taxis')
	
	$StopArea.connect('body_entered', self, '_stop')
	$StopArea.connect('body_exited', self, '_continue')
	
	disable_stop_collision_shapes()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func repositionate() -> void:
	disable_stop_collision_shapes()
	
	match $AnimatedSprite.animation:
		'move_up', 'move_down':
			$CollisionShape2D.disabled = true
			$VerticalCollisionShape.disabled = false
			$AnimatedSprite.position = Vector2(0.0, -84.0)
			continue
		'move_up':
			$StopArea/BackStop.disabled = false
		'move_down':
			$StopArea/FrontStop.disabled = false
		_:
			$CollisionShape2D.disabled = false
			$VerticalCollisionShape.disabled = true
			$AnimatedSprite.position = Vector2(69.0, -62.0)
			$StopArea/SideStop.disabled = false


func check_flip(have_to_flip: bool) -> void:
	if _animation_suffix == '':
		.check_flip(have_to_flip)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func disable_stop_collision_shapes() -> void:
	for cs in $StopArea.get_children():
		(cs as CollisionShape2D).disabled = true


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _stop(body: Node) -> void:
	if body.is_in_group('Taxis'):
		$AnimatedSprite.play('idle' + _animation_suffix)
		$Tween.stop_all()


func _continue(body: Node) -> void:
	if body.is_in_group('Taxis'):
		$AnimatedSprite.play('move' + _animation_suffix)
		$Tween.resume_all()
