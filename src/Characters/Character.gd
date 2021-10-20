tool
class_name Character
extends KinematicBody2D
#warning-ignore-all:return_value_discarded

signal point_achieved

export var speed := 50.0
export var can_move := true
export var can_change_route := true
export var restart_on_end := false
export(String, 'idle', 'idle_down', 'idle_up') var initial_animation := 'idle'
export var target_route_path: NodePath = ''
export var character_name := ''
export(String, MULTILINE) var character_description := ''
export var greeting_sfx := ''
export var photo: Texture = null
export var audio := ''

var target_point_idx := -1
var current_route: Path2D = null
var can_cross := true setget _set_can_cross

var _animation_suffix := ''

onready var target_route: Route = get_node_or_null(target_route_path)

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	$Tween.connect('tween_all_completed', self, '_move_finished')
	self.connect('input_event', self, '_on_input_event')
	
	$AnimatedSprite.play(initial_animation)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func repositionate() -> void:
	pass


func check_flip(have_to_flip: bool) -> void:
	scale.x = -1.0 if have_to_flip else 1.0


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func move_to(target_position: Vector2, delay := 0) -> void:
	yield(get_tree().create_timer(delay), 'timeout')
	
	$Tween.interpolate_property(
		self, 'position',
		position, target_position,
		position.distance_to(target_position) / speed,
		Tween.TRANS_LINEAR, Tween.EASE_IN
	)
	
	if position.y < target_position.y:
		_animation_suffix = '_down'
		$AnimatedSprite.play('move_down')
	elif position.y > target_position.y:
		_animation_suffix = '_up'
		$AnimatedSprite.play('move_up')
	else:
		_animation_suffix = ''
		$AnimatedSprite.play('move')
	
	$Tween.start()
	
	repositionate()
	check_flip(position.x < target_position.x)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _move_finished() -> void:
	$AnimatedSprite.play('idle' + _animation_suffix)
	emit_signal('point_achieved', self)


func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventScreenTouch:
		if not event.pressed and photo:
			E.emit_signal('character_clicked', self)


func _set_can_cross(value: bool) -> void:
	can_cross = value
	if not can_cross:
		$Tween.stop_all()
	else:
		$Tween.resume_all()
