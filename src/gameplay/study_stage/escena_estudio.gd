extends Control

@onready var label_etapa = $PanelContainer/MarginContainer/VBoxContainer/HeaderContainer/HBoxContainer/LabelEtapa
@onready var label_titulo = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/VBoxScrollContent/TitlePanel/MarginContainer/VBoxContainer/LabelTitulo
@onready var label_subtitulo = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/VBoxScrollContent/TitlePanel/MarginContainer/VBoxContainer/LabelSubtitulo
@onready var rich_text_contenido = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/VBoxScrollContent/ContentPanel/MarginContainer/VBoxContainer/TextoEstudio
@onready var boton_volver = $PanelContainer/MarginContainer/VBoxContainer/HeaderContainer/HBoxContainer/BotonVolver
@onready var icon_rect = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/VBoxScrollContent/IconPanel/MarginContainer/IconRect
@onready var scroll_container = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer
@onready var musica_fondo = $MusicaFondo

# Variables para soporte de arrastre táctil en móviles
var arrastrando_scroll: bool = false
var ultimo_pos_y: float = 0.0

func _ready() -> void:
	boton_volver.pressed.connect(_on_volver_pressed)
	
	# Asegurar bucle infinito de música de fondo
	if not musica_fondo.finished.is_connected(_on_musica_finished):
		musica_fondo.finished.connect(_on_musica_finished)
	
	# Garantizar que el texto no bloquee los eventos de deslizamiento táctil
	rich_text_contenido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Cargar los datos de la cápsula activa
	var id_capsula = CapsulaManager.capsula_activa_id
	var datos_capsula = CapsulaManager.obtener_capsula(id_capsula)
	if not datos_capsula.is_empty():
		# 1. Configurar etapa y textos
		label_etapa.text = "📖 ETAPA " + str(id_capsula) + ": ESTUDIAR"
		label_titulo.text = datos_capsula.get("titulo", "Cápsula de Estudio")
		label_subtitulo.text = datos_capsula.get("subtitulo", "")
		rich_text_contenido.text = datos_capsula.get("contenido_estudio", "")
		
		# 2. Configurar icono de la cápsula dinámicamente (garantizado en APK exportada)
		icon_rect.texture = CapsulaManager.obtener_icono_capsula(id_capsula)

func _on_musica_finished() -> void:
	musica_fondo.play()

func _input(event: InputEvent) -> void:
	# Soporte universal de deslizamiento táctil (pantalla táctil / mouse)
	if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		if event.pressed:
			arrastrando_scroll = true
			ultimo_pos_y = event.position.y
		else:
			arrastrando_scroll = false

	elif (event is InputEventScreenDrag or event is InputEventMouseMotion) and arrastrando_scroll:
		var delta_y = ultimo_pos_y - event.position.y
		scroll_container.scroll_vertical += int(delta_y)
		ultimo_pos_y = event.position.y

func _on_volver_pressed() -> void:
	# Regresar a la escena de selección de cápsulas
	get_tree().change_scene_to_file("res://src/ui/capsula_selector/capsula_selector.tscn")
