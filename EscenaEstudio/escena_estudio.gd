extends Control

@onready var label_etapa = $PanelContainer/MarginContainer/VBoxContainer/HeaderContainer/HBoxContainer/LabelEtapa
@onready var label_titulo = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/VBoxScrollContent/TitlePanel/MarginContainer/VBoxContainer/LabelTitulo
@onready var label_subtitulo = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/VBoxScrollContent/TitlePanel/MarginContainer/VBoxContainer/LabelSubtitulo
@onready var rich_text_contenido = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/VBoxScrollContent/ContentPanel/MarginContainer/VBoxContainer/TextoEstudio
@onready var boton_volver = $PanelContainer/MarginContainer/VBoxContainer/BotonVolver
@onready var icon_rect = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/VBoxScrollContent/IconPanel/MarginContainer/IconRect

func _ready() -> void:
	boton_volver.pressed.connect(_on_volver_pressed)
	
	# Cargar los datos de la cápsula activa
	var id_capsula = CapsulaManager.capsula_activa_id
	var datos_capsula = CapsulaManager.obtener_capsula(id_capsula)
	if not datos_capsula.is_empty():
		# 1. Configurar etapa y textos
		label_etapa.text = "📖 ETAPA " + str(id_capsula) + ": ESTUDIAR"
		label_titulo.text = datos_capsula.get("titulo", "Cápsula de Estudio")
		label_subtitulo.text = datos_capsula.get("subtitulo", "")
		rich_text_contenido.text = datos_capsula.get("contenido_estudio", "")
		
		# 2. Configurar icono de la cápsula dinámicamente
		# Busca en la carpeta que creaste res://assests/IconosCapsulas/capsula_#.png
		var ruta_icono = "res://assests/IconosCapsulas/capsula_" + str(id_capsula) + ".png"
		if FileAccess.file_exists(ruta_icono):
			icon_rect.texture = load(ruta_icono)
		else:
			# Si no existe, usamos MedallaPixelArt como placeholder por defecto
			var ruta_defecto = "res://assests/IconosPixelArt/MedallaPixelArt.png"
			if FileAccess.file_exists(ruta_defecto):
				icon_rect.texture = load(ruta_defecto)

func _on_volver_pressed() -> void:
	# Regresar a la escena de selección de cápsulas
	get_tree().change_scene_to_file("res://capsula_selector/capsula_selector.tscn")
