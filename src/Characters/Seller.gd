tool
extends "res://src/Characters/Character.gd"

export(E.SellerSide) var selling_side := E.SellerSide.RIGHT

var _selling := false


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	$SituationArea.connect('body_entered', self, '_check_buyier')
	
	disable_situation_area()
	
	match initial_animation:
		'idle_down':
			$SituationArea/Down.disabled = false
		'idle_up':
			$SituationArea/Up.disabled = false
		_:
			$SituationArea/Side.disabled = false


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _check_buyier(body: Node) -> void:
	if _selling or not body.is_in_group('Pedestrians'): return
	
	randomize()
	if randf() < 0.6:
		_selling = true # Para que sólo haya un comprador por vendedor.
		
		if not can_move:
			(body as Character).stop(self.position, selling_side)
			yield(get_tree().create_timer(60.0), 'timeout')
			(body as Character).continue_moving()
		else:
			# TODO: Hacer la lógica para que el vendedor también se quede quieto
			#		y ver cómo se determina hacia donde mira el comprador y esas
			#		cosas
			pass
		
		_selling = false


func disable_situation_area() -> void:
	for cs in $SituationArea.get_children():
		(cs as CollisionShape2D).disabled = true
