extends PanelContainer

# Referencias a los nodos hijos según tu estructura .tscn
@onready var label_titulo = $MarginContainer/VBoxHeader/HBoxContainer/VBoxContainer/LabelTitulo
@onready var label_mini_desc = $MarginContainer/VBoxHeader/HBoxContainer/VBoxContainer/LabelMiniDescripcion
@onready var label_estado = $MarginContainer/VBoxHeader/HBoxContainer/HBoxContainer/PanelContainer/MarginContainer/Estado
@onready var boton_chevron = $MarginContainer/VBoxHeader/HBoxContainer/HBoxContainer/TextureButton
@onready var contenedor_desplegable = $MarginContainer/VBoxHeader/VBoxContainer
@onready var rich_text_desc = $MarginContainer/VBoxHeader/VBoxContainer/RichTextLabel
@onready var boton_estudiar = $MarginContainer/VBoxHeader/VBoxContainer/HBoxContainer/VBoxContainer/Button
@onready var boton_practicar = $MarginContainer/VBoxHeader/VBoxContainer/HBoxContainer/VBoxContainer2/Button2

var id_capsula: int = -1

func _ready() -> void:
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
	label_mini_desc.text = datos["mini_descripcion"]
	label_estado.text = datos["estado"]
	rich_text_desc.text = datos["contenido_estudio"]
	
	# Si la cápsula está bloqueada, desactivamos los botones
	if datos["estado"] == "Bloqueado":
		boton_practicar.disabled = true
		boton_estudiar.disabled = true
		modulate = Color(0.6, 0.6, 0.6, 1.0) # Apariencia deshabilitada

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
