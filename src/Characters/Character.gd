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
export(Array, NodePath) var blocks_to_ignore := []
export(Array, NodePath) var blocks_to_take := []

var character_name := ''
var character_description := ''
var character_greeting_sfx := ''
var character_photo: Texture = null
var character_audio := ''
var target_point_idx := -1
var current_route: Path2D = null
var can_cross := true setget _set_can_cross
var waiting_position := Vector2.ZERO

var _animation_suffix := ''
var _last_position := Vector2.ZERO

onready var target_route: Route = get_node_or_null(target_route_path)

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	$Tween.connect('tween_all_completed', self, '_move_finished')
	self.connect('input_event', self, '_on_input_event')
	
	$AnimatedSprite.play(initial_animation)
	$PopupAnimatedSprite.hide()


func _get_property_list() -> Array:
	var properties = []
	
	properties.append({
		name = "Detalle del personaje",
		type = TYPE_NIL,
		hint_string = "character_",
		usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
	})
	properties.append({
		name = "character_name",
		type = TYPE_STRING
	})
	properties.append({
		name = "character_description",
		type = TYPE_STRING,
		hint = PROPERTY_HINT_MULTILINE_TEXT
	})
	properties.append({
		name = "character_greeting_sfx",
		type = TYPE_STRING
	})
	properties.append({
		name = "character_photo",
		type = TYPE_OBJECT,
		hint = PROPERTY_HINT_RESOURCE_TYPE,
		hint_string = 'Texture'
	})
	properties.append({
		name = "character_audio",
		type = TYPE_STRING
	})
	
	return properties


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func repositionate() -> void:
	pass


func check_flip(have_to_flip: bool) -> void:
	scale.x = -1.0 if have_to_flip else 1.0


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func move_to(target_position: Vector2, delay := 0) -> void:
	_last_position = position
	
	yield(get_tree().create_timer(delay), 'timeout')
	
	if waiting_position:
#		position = waiting_position
		waiting_position = Vector2.ZERO
	
	$Tween.interpolate_property(
		self, 'position',
		position, target_position,
		position.distance_to(target_position) / speed,
		Tween.TRANS_LINEAR, Tween.EASE_IN
	)
	
	$AnimatedSprite.play('move' + _animation_suffix)
	
	$Tween.start()
	
	repositionate()
	check_flip(position.x < target_position.x)


func queue(people: int) -> void:
	waiting_position = position
	
	var next_position := current_route.curve.get_point_position(
		posmod(target_point_idx + 1, current_route.curve.get_point_count())
	)
	
	if waiting_position.x != next_position.x:
		position.y += 16 * people
	if waiting_position.y != next_position.y:
		position.x += 16 * people


func look_towards(future_position: Vector2) -> void:
	if position.y < future_position.y:
		_animation_suffix = '_down'
		$AnimatedSprite.play('idle_down')
	elif position.y > future_position.y:
		_animation_suffix = '_up'
		$AnimatedSprite.play('idle_up')
	else:
		_animation_suffix = ''
		$AnimatedSprite.play('idle')
	
	check_flip(position.x < future_position.x)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _move_finished() -> void:
	$Tween.remove_all()
	
	$AnimatedSprite.play('idle' + _animation_suffix)
	emit_signal('point_achieved', self)


func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventScreenTouch:
		if not event.pressed and character_description:
			E.emit_signal('character_clicked', self)


func _set_can_cross(value: bool) -> void:
	can_cross = value
	if not can_cross:
		$Tween.stop_all()
	else:
		$Tween.resume_all()
