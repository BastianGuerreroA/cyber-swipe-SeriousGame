extends PanelContainer

# Referencias a los nodos hijos según tu estructura .tscn
@onready var label_titulo = $MarginContainer/VBoxHeader/HBoxContainer/VBoxContainer/LabelTitulo
@onready var label_Subtitulo = $MarginContainer/VBoxHeader/HBoxContainer/VBoxContainer/Subtitulo
@onready var label_estado = $MarginContainer/VBoxHeader/HBoxContainer/HBoxContainer/PanelContainer/MarginContainer/Estado
@onready var boton_chevron = $MarginContainer/VBoxHeader/HBoxContainer/HBoxContainer/TextureButton
@onready var contenedor_desplegable = $MarginContainer/VBoxHeader/VBoxContainer
@onready var rich_text_mini_desc = $MarginContainer/VBoxHeader/VBoxContainer/MiniDescripcion
@onready var boton_estudiar = $MarginContainer/VBoxHeader/VBoxContainer/HBoxContainer/VBoxContainer/Button
@onready var boton_practicar = $MarginContainer/VBoxHeader/VBoxContainer/HBoxContainer/VBoxContainer2/Button2
@onready var panel_estado = $MarginContainer/VBoxHeader/HBoxContainer/HBoxContainer/PanelContainer


var id_capsula: int = -1

func _ready() -> void:
	# Ajustar el punto de pivote al centro de la textura para que gire sobre su propio eje
	if boton_chevron.texture_normal:
		boton_chevron.pivot_offset = boton_chevron.texture_normal.get_size() / 2
		
	# 1. Por defecto, ocultamos la parte desplegable (acordeón cerrado)
	contenedor_desplegable.visible = false
	
	# 2. Conectamos las señales de los botones
	boton_chevron.pressed.connect(_on_chevron_pressed)
	boton_estudiar.pressed.connect(_on_estudiar_pressed)
	boton_practicar.pressed.connect(_on_practicar_pressed)

# Llena la información de la cápsula dinámicamente desde el manager
func configurar(datos: Dictionary) -> void:
	id_capsula = datos["id"]
	label_titulo.text = datos["titulo"]
	label_estado.text = datos["estado"]
	
	label_Subtitulo.text = datos["subtitulo"]
	rich_text_mini_desc.text = datos["mini_descripcion"]
	
	if datos["estado"] == "Bloqueado":
		boton_practicar.disabled = true
		boton_estudiar.disabled = true
		
		panel_estado.theme_type_variation = &"PanelVarianteRojo"
		modulate = Color(0.64, 0.64, 0.64, 1.0)
		
		
	else:
		boton_practicar.disabled = false
		boton_estudiar.disabled = false
		
		panel_estado.theme_type_variation = &"PanelVarianteVerde"
		modulate = Color(1.0, 1.0, 1.0, 1.0)


# Alterna la visibilidad del acordeón con animación del chevron
func _on_chevron_pressed() -> void:
	var esta_visible = contenedor_desplegable.visible
	contenedor_desplegable.visible = !esta_visible
	
	# Rotación del botón flecha usando Tween para un toque premium
	var tween = create_tween()
	var angulo_destino = 180.0 if !esta_visible else 0.0
	tween.tween_property(boton_chevron, "rotation_degrees", angulo_destino, 0.25).set_trans(Tween.TRANS_SINE)

func _on_estudiar_pressed() -> void:
	# Establecemos la cápsula activa
	CapsulaManager.capsula_activa_id = id_capsula
	# Cambiamos a la escena de estudio (la crearemos en el paso 6)
	get_tree().change_scene_to_file("res://EscenaEstudio/escena_estudio.tscn")

func _on_practicar_pressed() -> void:
	CapsulaManager.capsula_activa_id = id_capsula
	# Cambiamos a tu escena principal de juego (Swipe de cartas)
	get_tree().change_scene_to_file("res://EscenaPrincipal/escena_principal.tscn")
