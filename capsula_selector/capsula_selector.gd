extends Control

@onready var label_usuario = $MarginContainer/VBoxMain/PanelContainer/MarginContainer/VBoxContainer/HContainer_Usuario/Usuario
@onready var label_puntos = $MarginContainer/VBoxMain/PanelContainer/MarginContainer/VBoxContainer/HContainer_Usuario/HBoxContainer/Puntos
@onready var label_progreso = $MarginContainer/VBoxMain/PanelContainer/MarginContainer/VBoxContainer/Hcontainer_Progreso/HBoxContainer/Label
@onready var label_total_capsulas = $MarginContainer/VBoxMain/PanelContainer/MarginContainer/VBoxContainer/Hcontainer_Progreso/HBoxContainer/TotalCapsulas
@onready var contenedor_capsulas = $MarginContainer/VBoxMain/ScrollContainer/VBoxContainer_capsulas
@onready var progress_bar = $MarginContainer/VBoxMain/PanelContainer/MarginContainer/VBoxContainer/ProgressBar
@onready var boton_volver = $MarginContainer/VBoxMain/BotonVolver

# Precargamos la escena del item de la cápsula para instanciarla
const CAPSULA_ITEM_ESCENA = preload("res://Capsula_Item/capsula_item.tscn")

func _ready() -> void:
	# Conectar el botón de volver
	boton_volver.pressed.connect(_on_volver_pressed)
	
	# 1. Cargar datos del perfil de usuario
	if LsgAuth.logged_in:
		label_usuario.text = LsgAuth.player_name
	else:
		label_usuario.text = CapsulaManager.nombre_usuario
	label_puntos.text = str(CapsulaManager.puntos_totales)
	
	# Las completadas serán el nivel máximo desbloqueado menos 1
	var completadas = clampi(CapsulaManager.progreso_general - 1, 0, CapsulaManager.lista_capsulas.size())
	label_progreso.text = str(completadas)
	label_total_capsulas.text = "/" + str(CapsulaManager.lista_capsulas.size())
	
	# Actualizar la barra de progreso
	progress_bar.max_value = CapsulaManager.lista_capsulas.size()
	progress_bar.value = completadas
	
	# Limpiar placeholders
	for child in contenedor_capsulas.get_children():
		child.queue_free()
		
	# 2. Rellenar la lista evaluando el estado de cada cápsula
	for datos_capsula in CapsulaManager.lista_capsulas:
		var id_cap = datos_capsula["id"]
		
		# Si su ID es menor al progreso_general, ya fue ganada (Completada)
		if id_cap < CapsulaManager.progreso_general:
			datos_capsula["estado"] = "Completada"
		# Si su ID es igual al progreso_general, es la que le toca jugar (Disponible)
		elif id_cap == CapsulaManager.progreso_general:
			datos_capsula["estado"] = "Disponible"
		# Si es mayor, aún no llega ahí (Bloqueada)
		else:
			datos_capsula["estado"] = "Bloqueado"
			
		var instancia = CAPSULA_ITEM_ESCENA.instantiate()
		contenedor_capsulas.add_child(instancia)
		instancia.configurar(datos_capsula)

func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://menu_principal/menu_principal.tscn")
