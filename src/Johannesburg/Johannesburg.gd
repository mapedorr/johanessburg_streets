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
var _characters_in_point := {}


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
			
			for path in character.blocks_to_ignore:
				routes.erase(character.get_node(path).name)
			
			randomize()
			route = _pedestrians_routes.get_node(
				routes[randi() % routes.size()]
			)
			
			randomize()
			starting_point = randi() % _routes_points[route.name].size()
		
		# Poner al personaje en la ruta y hacerlo caminar
		character.current_route = route
		character.position = route.curve.get_point_position(starting_point)
		character.target_point_idx = starting_point
		
		# Que el personaje mire en dirección al punto al que se va a mover
		character.look_towards(route.curve.get_point_position(
			posmod(starting_point + 1, route.curve.get_point_count())
		))
		
		# Ver si la nueva ruta tiene un semáforo asociado y verificar
		# el estado del semáforo
		var autostart := true
		for tl in _traffic_lights.get_children():
			if not tl is TrafficLight:
				continue
			
			if tl.has_route(character.current_route.get_instance_id())\
			and tl.is_red():
				tl.add_character(character)
				
				# Ver si ya hay un personaje en ese punto para ponerse a hacer cola
				_check_if_has_to_queue(character)
				
				autostart = false
		
		if autostart:
			character.target_point_idx = _get_target_point_in_route(
				starting_point, route.curve
			)
			character.move_to(
				route.curve.get_point_position(character.target_point_idx)
			)
		
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
	var position_str := str(character.position)
	
	if character.can_change_route:
		# Cambiar de ruta
		if _routes_join.has(position_str):
			var keys: Array = _routes_join[position_str].keys()
			keys.erase(character.current_route.name)
			
			# Eliminar de la lista de opciones las rutas que vayan a cuadras
			# prohibidas.
			for path in character.blocks_to_ignore:
				var block_name := character.get_node(path).name
				
				keys.erase(block_name)
				
				var positions_to_remove := []
				for idx in keys.size():
					if Array(keys[idx].split('-')).find(block_name) > -1:
						positions_to_remove.append(idx)
				
				for idx in positions_to_remove:
					keys.remove(idx)
			
			if not keys.empty():
				keys.shuffle()
				
				character.current_route = _pedestrians_routes.get_node(keys[0])
				target_curve = character.current_route.curve
				character.target_point_idx =\
				_routes_join[position_str][keys[0]]
				picked_route = true
	
	# Que el personaje mire en dirección al punto al que se va a mover
	character.look_towards(target_curve.get_point_position(
		posmod(character.target_point_idx + 1, target_curve.get_point_count())
	))
	
	# Ver si la nueva ruta tiene un semáforo asociado y verificar
	# el estado del semáforo
	for tl in _traffic_lights.get_children():
		if not tl is TrafficLight:
			continue
		
		if tl.has_route(character.current_route.get_instance_id())\
		and tl.is_red():
			tl.add_character(character)
			
			# Ver si ya hay un personaje en ese punto para ponerse a hacer cola
			_check_if_has_to_queue(character)
			
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
	
	character.move_to(target_curve.get_point_position(
		character.target_point_idx)
	)


func _change_traffic_lights() -> void:
	for tl in _traffic_lights.get_children():
		if not tl is TrafficLight:
			continue
		
		tl.change_state()


func _cross(traffic_light: TrafficLight) -> void:
	var position_str := ''
	
	for c in traffic_light.waiting_characters:
		var character: Character = c
		
		position_str = str(character.waiting_position)
		
		character.target_point_idx = _get_target_point_in_route(
			character.target_point_idx,
			character.current_route.curve
		)
		
		# Los taxis deben reiniciar el recorrido si ya llegaron al final -------
		if character.target_point_idx == 0 and character.restart_on_end:
			yield(get_tree().create_timer(5.0), 'timeout')
			
			character.position =\
				character.current_route.curve.get_point_position(0)
			character.target_point_idx = 1
		# ----------------------------------------------------------------------
		
		randomize()
		character.move_to(character.current_route.curve.get_point_position(
			character.target_point_idx
		), randi() % 8)
	
	traffic_light.waiting_characters.clear()
	
	# Limpiar las listas de personajes esperando en semáforos
	_characters_in_point.erase(position_str)


func _get_target_point_in_route(starting_point: int, route: Curve2D) -> int:
	return posmod(starting_point + 1, route.get_point_count())


func _check_if_has_to_queue(character: Character) -> void:
	var position_str := str(character.position)
	if _characters_in_point.has(position_str):
		character.queue(_characters_in_point[position_str].size())
		_characters_in_point[position_str].append(
			character.get_instance_id()
		)
	else:
		_characters_in_point[position_str] = [character.get_instance_id()]
