class_name TrafficLight
extends Sprite

signal state_changed

enum State { RED, GREEN }
export(State) var initial_state := State.RED
export(Array, NodePath) var linked_routes_paths := []
export(Array, NodePath) var linked_lights := []

var waiting_characters := []
var _linked_routes := []

onready var current_state := initial_state
onready var _red_light: Sprite = get_node('Red')
onready var _yellow_light: Sprite = get_node('Yellow')
onready var _green_light: Sprite = get_node('Green')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	for path in linked_routes_paths:
		_linked_routes.append(get_node(path).get_instance_id())
	
	_update_lights()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func change_state() -> void:
	if current_state == State.RED:
		current_state = State.GREEN
	else:
		current_state = State.RED
	
	_update_lights()
	
	emit_signal('state_changed', self)


func has_route(route_id: int) -> bool:
	return _linked_routes.has(route_id)


func is_red() -> bool:
	return current_state == State.RED


func add_character(character: Character) -> void:
	if not waiting_characters.has(character):
		waiting_characters.append(character)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _update_lights() -> void:
	_red_light.modulate.a = 1.0 if is_red() else 0.3
	_yellow_light.modulate.a = 0.3
	_green_light.modulate.a = 0.3 if is_red() else 1.0
