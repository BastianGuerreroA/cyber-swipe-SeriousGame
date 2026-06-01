extends Control

@onready var label_titulo = $PanelContainer/MarginContainer/VBoxContainer/LabelTituloCapsula
@onready var rich_text_contenido = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/TextoEstudio
@onready var boton_volver = $PanelContainer/MarginContainer/VBoxContainer/BotonVolver

func _ready() -> void:
	boton_volver.pressed.connect(_on_volver_pressed)
	
	# Cargar los datos de la cápsula activa
	var datos_capsula = CapsulaManager.obtener_capsula(CapsulaManager.capsula_activa_id)
	if not datos_capsula.is_empty():
		label_titulo.text = datos_capsula["titulo"]
		# Usamos parse_bbcode o .text según si usas formato enriquecido
		rich_text_contenido.text = datos_capsula["contenido_estudio"]

func _on_volver_pressed() -> void:
	# Regresar a la escena de selección de cápsulas
	get_tree().change_scene_to_file("res://capsula_selector/capsula_selector.tscn")
