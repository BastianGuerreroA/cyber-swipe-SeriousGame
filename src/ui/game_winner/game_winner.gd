extends Control

@export var escena_capsulas: PackedScene

@onready var label_valor_puntaje = $PanelContainer/MarginContainer/VBoxContainer/PanelContainer/MarginContainer/HBoxContainer/ValorPuntaje
@onready var label_valor_record = $PanelContainer/MarginContainer/VBoxContainer/Record
@onready var label_titulo_logro = $PanelContainer/MarginContainer/VBoxContainer/PanelFeedback/MarginContainer/VBoxContainer/TituloLogro
@onready var label_consejo = $PanelContainer/MarginContainer/VBoxContainer/PanelFeedback/MarginContainer/VBoxContainer/Consejo

func _ready() -> void:
	# Mostrar los puntajes
	var record = CapsulaManager.obtener_record_capsula(CapsulaManager.capsula_activa_id)
	label_valor_puntaje.text = str(CapsulaManager.puntaje_ronda_actual)
	label_valor_record.text = "Récord: " + str(record)
	
	# Mostrar retroalimentación pedagógica de victoria
	var id_capsula = CapsulaManager.capsula_activa_id
	label_titulo_logro.text = "🏆 CÁPSULA " + str(id_capsula) + " COMPLETADA"
	label_consejo.text = CapsulaManager.obtener_consejo_victoria(id_capsula)

# "Reintentar" -> Carga de nuevo la escena del juego
func _on_reintentar_pressed() -> void:
	get_tree().paused = false
	LsgCore.reset_active_mechanics()
	get_tree().change_scene_to_file("res://src/gameplay/main_stage/escena_principal.tscn")

func _on_exit_game_pressed() -> void:
	get_tree().paused = false
	LsgCore.reset_active_mechanics()
	get_tree().change_scene_to_packed(escena_capsulas)
