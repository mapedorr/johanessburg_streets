extends Node
#warning-ignore-all:unused_signal

signal character_clicked(node)
signal character_popup_closed

enum SellerSide { LEFT, UP, RIGHT, DOWN }

var clicked := false


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func character_clicked(character: Character) -> void:
	if clicked: return
	
	clicked = true
	emit_signal('character_clicked', character)
