extends Button

func _on_pressed() -> void:
	#Descongelar el juego antes de irnos
	get_tree().paused = false 
	#cambiamos de escena
	get_tree().change_scene_to_file("res://menu_principal/menu_principal.tscn")
