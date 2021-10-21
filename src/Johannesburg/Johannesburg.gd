extends Node2D
#warning-ignore-all:return_value_discarded

onready var _pedestrians_routes: Node2D = find_node('PedestriansRoutes')
onready var _taxis_routes: Node2D = find_node('TaxisRoutes')
onready var _characters_group: YSort = find_node('Characters')
onready var _taxis_group: YSort = find_node('Taxis')
onready var _traffic_lights_timer: Timer = find_node('TrafficLightsTimer')
onready var _traffic_lights: YSort = find_node('TrafficLights')

var _taxi := preload('res://src/Characters/Taxi/Taxi.tscn')
# Mapa de rutas y sus puntos
var _routes_points := {}
var _routes_join := {}


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	for p in _pedestrians_routes.get_children():
		if p.is_exclusive:
			continue
		
		if p.name.find('-') > -1:
			continue
		
		_routes_points[p.name] = range((p as Path2D).curve.get_point_count())
		
		# Recorrer los puntos de la ruta para ir creando el diccionario de
		# conexión de rutas
		for idx in _routes_points[p.name]:
			var point_string := str((p as Path2D).curve.get_point_position(idx))
			
			if not _routes_join.has(point_string):
				_routes_join[point_string] = {}
				_routes_join[point_string][p.name] = idx
	
	for p in _pedestrians_routes.get_children():
		if p.is_exclusive:
			continue
		
		if p.name.find('-') < 0:
			continue
		
		var curve: Curve2D = (p as Path2D).curve
		for point_idx in curve.get_point_count():
			var point_string := str(curve.get_point_position(point_idx))
			if _routes_join.has(point_string):
				_routes_join[point_string][p.name] = point_idx
	
	for tl in _traffic_lights.get_children():
		if tl is TrafficLight:
			(tl as TrafficLight).connect('state_changed', self, '_cross')
	
	_traffic_lights_timer.connect('timeout', self, '_change_traffic_lights')
	
	# Que comience la fiesta
	_start()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _start() -> void:
	for c in _characters_group.get_children():
		var character: Character = c
		
		if not character.can_move:
			continue
		
		var route: Route = null
		var starting_point := 0
		
		if character.target_route:
			route = character.target_route
		else:
			# Escoger una ruta al azar para empezar a caminar
			var routes: Array = _routes_points.keys()
			
			randomize()
			route = _pedestrians_routes.get_node(
				routes[randi() % routes.size()]
			)
			
			randomize()
			starting_point = randi() % _routes_points[route.name].size()
		
		# Poner al personaje en la ruta y hacerlo caminar
		character.current_route = route
		
		character.position = route.curve.get_point_position(starting_point)
		
		# Ver si la nueva ruta tiene un semáforo asociado y verificar
		# el estado del semáforo
		var autostart := true
		for tl in _traffic_lights.get_children():
			if not tl is TrafficLight:
				continue
			
			if tl.has_route(character.current_route.get_instance_id()) and tl.is_red():
				tl.add_character(character)
				autostart = false
		
		if autostart:
			character.target_point_idx = _get_target_point_in_route(
				starting_point, route.curve
			)
			character.move_to(route.curve.get_point_position(character.target_point_idx))
		else:
			character.target_point_idx = starting_point
		
		if not character.target_route:
			(_routes_points[route.name] as Array).remove(starting_point)
			
			if _routes_points[route.name].empty():
				_routes_points.erase(route.name)
		
		character.connect('point_achieved', self, '_select_new_target')
	
	# Crear un taxi por avenida y ponerlo a andar
	for avenue in _taxis_routes.get_children():
		var taxi: Character = _taxi.instance()
		_taxis_group.add_child(taxi)
		
		taxi.current_route = avenue
		taxi.target_point_idx = 1
		taxi.position = avenue.curve.get_point_position(0)
		taxi.move_to(avenue.curve.get_point_position(1))
		taxi.connect(
			'point_achieved',
			self,
			'_select_new_target'
		)


func _select_new_target(character: KinematicBody2D) -> void:
	# Evaluar si ese punto coincide con el de otra ruta y decidir si va a
	# tomarla o a seguir en la que ya iba
	var target_curve: Curve2D = character.current_route.curve
	var picked_route := false
	
	if character.can_change_route:
		# Cambiar de ruta
		var character_position_str := str(character.position)
		if _routes_join.has(character_position_str):
			var keys: Array = _routes_join[character_position_str].keys()
			keys.erase(character.current_route.name)
			
			if not keys.empty():
				keys.shuffle()
				
				character.current_route = _pedestrians_routes.get_node(keys[0])
				target_curve = character.current_route.curve
				character.target_point_idx = _routes_join[character_position_str][keys[0]]
				picked_route = true
	
	# Ver si la nueva ruta tiene un semáforo asociado y verificar
	# el estado del semáforo
	for tl in _traffic_lights.get_children():
		if not tl is TrafficLight:
			continue
		
		if tl.has_route(character.current_route.get_instance_id()) and tl.is_red():
			tl.add_character(character)
			return
	
	character.target_point_idx = _get_target_point_in_route(
		character.target_point_idx,
		target_curve
	)
	
	# Los taxis deben reiniciar el recorrido si ya llegaron al final -----------
	if character.target_point_idx == 0 and character.restart_on_end:
		yield(get_tree().create_timer(5.0), 'timeout')
		
		character.position = target_curve.get_point_position(0)
		character.target_point_idx = 1
	# --------------------------------------------------------------------------
	
	character.move_to(target_curve.get_point_position(character.target_point_idx))


func _change_traffic_lights() -> void:
	for tl in _traffic_lights.get_children():
		if not tl is TrafficLight:
			continue
		
		tl.change_state()


func _cross(traffic_light: TrafficLight) -> void:
	for c in traffic_light.waiting_characters:
		var character: Character = c
		
		character.target_point_idx = _get_target_point_in_route(
			character.target_point_idx,
			character.current_route.curve
		)
		
		# Los taxis deben reiniciar el recorrido si ya llegaron al final -------
		if character.target_point_idx == 0 and character.restart_on_end:
			yield(get_tree().create_timer(5.0), 'timeout')
			
			character.position = character.current_route.curve.get_point_position(0)
			character.target_point_idx = 1
		# ----------------------------------------------------------------------
		
		randomize()
		character.move_to(character.current_route.curve.get_point_position(
			character.target_point_idx
		), randi() % 8)
	
	traffic_light.waiting_characters.clear()


func _get_target_point_in_route(starting_point: int, route: Curve2D) -> int:
	return posmod(starting_point + 1, route.get_point_count())
