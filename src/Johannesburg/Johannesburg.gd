extends Node2D
#warning-ignore-all:return_value_discarded

# Guardar las referencias a los nodos de la escena para usarlos en los cálculos
# de la lógica del juego.
onready var _pedestrians_routes: Node2D = find_node('PedestriansRoutes')
onready var _taxis_routes: Node2D = find_node('TaxisRoutes')
onready var _characters_group: YSort = find_node('Characters')
onready var _taxis_group: YSort = find_node('Taxis')
onready var _traffic_lights_timer: Timer = find_node('TrafficLightsTimer')
onready var _traffic_lights: YSort = find_node('TrafficLights')

# La referencia a los taxis que se pueden poner a andar por la ciudad.
var _taxis := [
	preload('res://src/Characters/Taxi/TaxiWhite.tscn'),
	preload('res://src/Characters/Taxi/Taxi.tscn'),
	preload('res://src/Characters/Taxi/TaxiGreen.tscn'),
	preload('res://src/Characters/Taxi/TaxiYellow.tscn'),
]
# Mapa de rutas y sus puntos
var _routes_points := {}
# Mapa de uniones de las cuadras
var _routes_join := {}
# Se usará para saber si en un punto de semáforo ya hay otro personaje esperando
var _characters_in_point := {}


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	# Recorre las rutas de los peatones, y guarda una referencia a los puntos
	# de cada cuadra.
	for p in _pedestrians_routes.get_children():
		if p.is_exclusive:
			continue
		
		# Esto hace que ignore los cruces.
		if p.name.find('-') > -1:
			continue
		
		# Para cada cuadra (p. ej. B1) guarda un arreglo del 0 al 3.
		_routes_points[p.name] = range((p as Path2D).curve.get_point_count())
		
		# Recorrer los puntos de la cuadra para ir creando el diccionario de
		# conexión de cuadras
		for idx in _routes_points[p.name]:
			var point_string := str((p as Path2D).curve.get_point_position(idx))
			
			if not _routes_join.has(point_string):
				# Guarda la coordenada de un punto dentro de la cuadra y lo
				# relaciona con el cruce con el que coincide.
				_routes_join[point_string] = {}
				_routes_join[point_string][p.name] = idx
	
	# Aquí se guarda la cuadra como una de las posibles rutas a tomar en los
	# puntos de cruce de la misma cuadra. Esto se hizo para que entre las opciones
	# de lo que hacen los personajes al llegar a un punto con cruce, estuviera
	# la de darle la vuelta a la cuadra por donde ya venían caminando.
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
	
	# Aquí nos conectamos a la señal de que cada semáforo cambio de color.
	for tl in _traffic_lights.get_children():
		if tl is TrafficLight:
			(tl as TrafficLight).connect('state_changed', self, '_cross')
	
	# Esto es lo que hace que los semáforos cambien de color cada X segundos.
	_traffic_lights_timer.connect('timeout', self, '_change_traffic_lights')
	
	# Que comience la fiesta
	_start()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
# Esta función hace que todos los taxis y los personajes se ubiequen en una ruta
# y empiecen a andar la ciudad.
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
			# Escoger una cuadra al azar para empezar a caminar
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
			# Aquí se calcula el índice del punto al que se va a mover el
			# personaje.
			character.target_point_idx = _get_target_point_in_route(
				starting_point, route.curve
			)
			# Y aquí, el personaje empieza a caminar hacia la coordenada del punto
			# al que decidió moverse.
			character.move_to(
				route.curve.get_point_position(character.target_point_idx)
			)
		
		if not character.target_route:
			# Aquí se elimina el punto que escogió el personaje para arrancar de
			# la lista de posibles puntos donde pueden arrancar los demás
			# personajes.
			(_routes_points[route.name] as Array).remove(starting_point)
			
			# Si la cuadra se quedó sin puntos, se elimina de la lista de posibles
			# cuadras a tomar para arrancar.
			if _routes_points[route.name].empty():
				_routes_points.erase(route.name)
		
		character.connect('point_achieved', self, '_select_new_target')
	
	# Crear X taxis
	var whites_count := 0
	for i in range(10):
		var taxi: Character
		
		if whites_count <= 4:
			taxi = _taxis[0].instance()
			whites_count = posmod(whites_count + 1, 6)
		else:
			taxi = _taxis[randi() % 3 + 1].instance()
			whites_count = 0
	
		_taxis_group.add_child(taxi)
		
		var avenue: Path2D = _taxis_routes.get_child(
			randi() % _taxis_routes.get_child_count()
		)
		taxi.current_route = avenue
		taxi.target_point_idx = 1
		taxi.position = avenue.curve.get_point_position(0)
		taxi.speed = randi() % 250 + 180
		taxi.look_towards(avenue.curve.get_point_position(1))
		taxi.move_to(avenue.curve.get_point_position(1), randi() % 15 + 5)
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
	
	var delay := 0.0
	
	# Los taxis deben reiniciar el recorrido si ya llegaron al final -----------
	if character.target_point_idx == 0 and character.restart_on_end:
		character.disable_stop_collision_shapes()
		
		delay = 5.0
		
		character.position = target_curve.get_point_position(0)
		character.target_point_idx = 1
		character.look_towards(target_curve.get_point_position(1))
	# --------------------------------------------------------------------------
	
	character.move_to(
		target_curve.get_point_position(character.target_point_idx),
		delay
	)


func _change_traffic_lights() -> void:
	for tl in _traffic_lights.get_children():
		if not tl is TrafficLight:
			continue
		
		tl.change_state()


func _cross(traffic_light: TrafficLight) -> void:
	var position_str := ''
	
	for c in traffic_light.waiting_characters:
		if c.is_in_group('Taxis'):
			# Verificar que no haya trancón antes de arrancar.
			c.enable_raycast()
			continue
		
		var character: Character = c
		
		position_str = str(character.waiting_position)
		
		character.target_point_idx = _get_target_point_in_route(
			character.target_point_idx,
			character.current_route.curve
		)
		
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
	if character.is_in_group('Taxis'): return
	
	var position_str := str(character.position)
	if _characters_in_point.has(position_str):
		character.queue(_characters_in_point[position_str].size())
		_characters_in_point[position_str].append(
			character.get_instance_id()
		)
	else:
		_characters_in_point[position_str] = [character.get_instance_id()]
