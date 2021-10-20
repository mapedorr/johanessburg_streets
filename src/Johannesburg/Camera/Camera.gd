extends Camera2D
#warning-ignore-all:return_value_discarded

export (NodePath) var target

var target_return_enabled = true
var target_return_rate = 0.02
var min_zoom = 0.5
var max_zoom = 2
var zoom_sensitivity = 10
var zoom_speed = 0.05
var events = {}
var last_drag_distance = 0

var _can_drag := true


func _ready() -> void:
	E.connect('character_clicked', self, '_disable_drag')
	E.connect('character_popup_closed', self, '_enable_drag')


func _process(_delta):
	if target and target_return_enabled and events.size() == 0:
		position = lerp(position, get_node(target).position, target_return_rate)


func _unhandled_input(event):
	if not _can_drag: return
	
	if event is InputEventScreenTouch:
		if event.pressed:
			events[event.index] = event
		else:
			events.erase(event.index)

	if event is InputEventScreenDrag:
		events[event.index] = event
		if events.size() == 1:
			position += event.relative.rotated(rotation) * zoom.x

	if event is InputEventScreenDrag:
		events[event.index] = event
		if events.size() == 1:
			# Al multiplicar el event.relative por -2.0 hacemos que el movimiento
			# de la cámara sea a la inversa (como en las aplicaciones touch).
			# ¿Por qué? Nunca lo sabremos.
			position += (event.relative.rotated(rotation) * -2.0) * zoom.x
		elif events.size() == 2:
			var drag_distance = events[0].position.distance_to(events[1].position)
			if abs(drag_distance - last_drag_distance) > zoom_sensitivity:
				var new_zoom = (1 + zoom_speed) if drag_distance < last_drag_distance else (1 - zoom_speed)
				new_zoom = clamp(zoom.x * new_zoom, min_zoom, max_zoom)
				zoom = Vector2.ONE * new_zoom
				last_drag_distance = drag_distance


func _disable_drag(_character: KinematicBody2D) -> void:
	_can_drag = false


func _enable_drag() -> void:
	yield(get_tree().create_timer(0.3), 'timeout')
	_can_drag = true
