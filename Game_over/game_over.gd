extends Control

@onready var label_valor_puntaje = $PanelContainer/MarginContainer/VBoxContainer/PanelContainer/MarginContainer/HBoxContainer/ValorPuntaje
@onready var label_valor_record = $PanelContainer/MarginContainer/VBoxContainer/Record
@onready var label_causa_fallo = $PanelContainer/MarginContainer/VBoxContainer/PanelFeedback/MarginContainer/VBoxContainer/CausaFallo
@onready var label_consejo = $PanelContainer/MarginContainer/VBoxContainer/PanelFeedback/MarginContainer/VBoxContainer/Consejo

func _ready() -> void:
	# Mostrar los puntajes
	var record = CapsulaManager.obtener_record_capsula(CapsulaManager.capsula_activa_id)
	label_valor_puntaje.text = str(CapsulaManager.puntaje_ronda_actual)
	label_valor_record.text = "Récord: " + str(record)
	
	# Mostrar retroalimentación pedagógica
	var metrica = CapsulaManager.metrica_fallida
	if metrica != "":
		label_causa_fallo.text = "⚠️ RECURSO AGOTADO: " + metrica.to_upper()
		if CapsulaManager.CONSEJOS_DERROTA.has(metrica):
			label_consejo.text = CapsulaManager.CONSEJOS_DERROTA[metrica]
		else:
			label_consejo.text = "Recuerda vigilar todas las métricas de ciberseguridad."
	else:
		label_causa_fallo.text = "⚠️ INCIDENTE DE SEGURIDAD"
		label_consejo.text = "Intenta mantener el balance de tus métricas."

# "Reanudar LSG" -> Continuar donde quedaste gastando puntos con lsg
func _on_reanudar_pressed() -> void:
	#get_tree().paused = false
	pass

# "Reintentar" -> Cargar el juego de nuevo
func _on_reintentar_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://EscenaPrincipal/escena_principal.tscn")

func _on_exit_game_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://capsula_selector/capsula_selector.tscn")
