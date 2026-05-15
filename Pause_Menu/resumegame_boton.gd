extends Button

func _on_pressed() -> void:
	# 1. Descongelamos el juego
	get_tree().paused = false
	# 2. Ocultamos el menú de pausa
	owner.visible = false
	# 3. Le decimos a su "Padre" (el CanvasLayer) que vuelva a hacer visible el BotonPausa
	if owner.get_parent().has_node("BotonPausa"):
		owner.get_parent().get_node("BotonPausa").visible = true
