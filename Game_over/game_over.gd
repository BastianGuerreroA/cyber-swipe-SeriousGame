extends Control

@onready var label_valor_puntaje = $PanelContainer/MarginContainer/VBoxContainer/PanelContainer/MarginContainer/HBoxContainer/ValorPuntaje
@onready var label_valor_record = $PanelContainer/MarginContainer/VBoxContainer/Record

func _ready() -> void:
	
	# Mostrar los puntajes
	var record = CapsulaManager.obtener_record_capsula(CapsulaManager.capsula_activa_id)
	label_valor_puntaje.text = str(CapsulaManager.puntaje_ronda_actual)
	label_valor_record.text = "Récord: " + str(record)

# "Reanudar LSG" -> Continuar donde quedaste gastando puntos con lsg
func _on_reanudar_pressed() -> void:
	get_tree().paused = false
	pass

# "Reintentar" -> Cargar el juego de nuevo
func _on_reintentar_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://EscenaPrincipal/escena_principal.tscn")


func _on_exit_game_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://capsula_selector/capsula_selector.tscn")
