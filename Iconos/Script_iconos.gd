extends Control

@export var presupuesto: Array[Texture2D] = []
@export var integridad: Array[Texture2D] = []
@export var disponibilidad: Array[Texture2D] = []
@export var confidencialidad: Array[Texture2D] = []

# Guardamos referencias directas a los TextureRect (para presupuesto usamos la barra)
@onready var barra_presupuesto = get_parent().get_node_or_null("BarraPresupuesto")

@onready var icon_integridad = $HBoxContainer/VBoxContainer_I/Intregridad
@onready var icon_disponibilidad = $HBoxContainer/VBoxContainer_D/Disponibilidad
@onready var icon_confidencialidad = $HBoxContainer/VBoxContainer_C/Confidencialidad

#Referencias de cada circulo
@onready var circulo_integridad = $HBoxContainer/VBoxContainer_I/HBox_I/Circulo_Integridad
@onready var circulo_disponibilidad = $HBoxContainer/VBoxContainer_D/HBox_D/Circulo_Disponibilidad
@onready var circulo_confidencialidad = $HBoxContainer/VBoxContainer_C/HBox_C/Circulo_Confidencialidad

# Referencias de los labels para números predictivos (Mecánica Análisis de Impacto)
@onready var label_presupuesto = get_parent().get_node_or_null("BarraPresupuesto/HBox/Margin2/LabelCambio")
@onready var label_integridad = $HBoxContainer/VBoxContainer_I/HBox_I/Label_I
@onready var label_disponibilidad = $HBoxContainer/VBoxContainer_D/HBox_D/Label_D
@onready var label_confidencialidad = $HBoxContainer/VBoxContainer_C/HBox_C/Label_C

# Nodos dinámicos para los tooltips
var panel_info: PanelContainer = null
var label_info: Label = null
var activo_icono: TextureRect = null


func _ready() -> void:
	# Habilitar el mouse filter para que capturen eventos
	icon_integridad.mouse_filter = Control.MOUSE_FILTER_STOP
	icon_disponibilidad.mouse_filter = Control.MOUSE_FILTER_STOP
	icon_confidencialidad.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Conectar las señales gui_input para clics / toques
	icon_integridad.gui_input.connect(_on_icon_gui_input.bind("Integridad", icon_integridad))
	icon_disponibilidad.gui_input.connect(_on_icon_gui_input.bind("Disponibilidad", icon_disponibilidad))
	icon_confidencialidad.gui_input.connect(_on_icon_gui_input.bind("Confidencialidad", icon_confidencialidad))
	
	# Crear el panel de información emergente
	_crear_panel_info()


func _crear_panel_info() -> void:
	panel_info = PanelContainer.new()
	panel_info.visible = false
	add_child(panel_info)
	
	# Estilo medieval oscuro con bordes dorados
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.12, 0.95) # Gris carbón semi-transparente
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.75, 0.60, 0.42, 1.0) # Dorado
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	
	# Márgenes de padding
	style.content_margin_left = 12
	style.content_margin_top = 8
	style.content_margin_right = 12
	style.content_margin_bottom = 8
	
	panel_info.add_theme_stylebox_override("panel", style)
	
	label_info = Label.new()
	label_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var fuentefile = load("res://assests/Fuente/acknowtt.ttf")
	if fuentefile:
		label_info.add_theme_font_override("font", fuentefile)
	label_info.add_theme_font_size_override("font_size", 16)
	label_info.add_theme_color_override("font_color", Color(0.95, 0.95, 0.90, 1.0)) # Blanco hueso
	
	panel_info.add_child(label_info)


func _on_icon_gui_input(event: InputEvent, nombre: String, icon_node: TextureRect) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if panel_info.visible and activo_icono == icon_node:
			ocultar_panel_info()
		else:
			mostrar_panel_info(nombre, icon_node)


func mostrar_panel_info(nombre: String, icon_node: TextureRect) -> void:
	activo_icono = icon_node
	
	# Textos pedagógicos breves
	var textos = {
		"Integridad": "Integridad\nDatos confiables y sin alterar",
		"Disponibilidad": "Disponibilidad\nSistemas activos y accesibles",
		"Confidencialidad": "Confidencialidad\nAccesos restringidos y privados"
	}
	
	label_info.text = textos.get(nombre, nombre)
	panel_info.visible = true
	
	# Esperar a que se calcule el tamaño real en el ciclo de Godot
	await get_tree().process_frame
	if not is_inside_tree() or not panel_info.visible or activo_icono != icon_node:
		return
		
	# Cálculo posicional adaptado a la escala
	var icon_global_pos = icon_node.global_position
	var self_scale = get_global_transform().get_scale()
	var icon_scale = icon_node.get_global_transform().get_scale()
	
	# Posición del icono relativa a IconosMetricas
	var local_pos = (icon_global_pos - global_position) / self_scale
	
	# Centrar horizontalmente respecto al icono
	var local_icon_width = icon_node.size.x * (icon_scale.x / self_scale.x)
	local_pos.x += (local_icon_width - panel_info.size.x) / 2
	local_pos.y -= (panel_info.size.y + 10) # 10px locales por encima del icono
	
	# --- CLAMP DENTRO DE LOS BORDES DEL CONTENEDOR (TextureRect) ---
	var parent_node = get_parent()
	if parent_node:
		var parent_width = parent_node.size.x
		# Ancho del contenedor en la escala local de este nodo (IconosMetricas)
		var local_parent_width = parent_width / scale.x
		
		# Los límites izquierdo y derecho en coordenadas locales de este nodo
		# Dado que IconosMetricas está centrado horizontalmente en TextureRect (offset_left es casi 0)
		var limit_left = - (local_parent_width / 2) + 10 # 10px de margen
		var limit_right = (local_parent_width / 2) - 10 # 10px de margen
		
		# Clamp de la posición X
		local_pos.x = clamp(local_pos.x, limit_left, limit_right - panel_info.size.x)
		
	panel_info.position = local_pos


func ocultar_panel_info() -> void:
	panel_info.visible = false
	activo_icono = null


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if panel_info and panel_info.visible:
			# Detectar si el clic ocurrió en alguno de los iconos
			var clicked_any_icon = false
			for icon_node in [icon_integridad, icon_disponibilidad, icon_confidencialidad]:
				var icon_scale = icon_node.get_global_transform().get_scale()
				var icon_rect = Rect2(icon_node.global_position, icon_node.size * icon_scale)
				if icon_rect.has_point(event.global_position):
					clicked_any_icon = true
					break
			
			# Si el clic no fue en ningún icono ni dentro del panel informativo, lo cerramos
			if not clicked_any_icon:
				var self_scale = get_global_transform().get_scale()
				var panel_rect = Rect2(panel_info.global_position, panel_info.size * self_scale)
				if not panel_rect.has_point(event.global_position):
					ocultar_panel_info()


# Función matemática que transforma de 0-100 a un índice 0-4
func obtener_indice(valor: int) -> int:
	if valor <= 20: return 0
	elif valor <= 40: return 1
	elif valor <= 60: return 2
	elif valor <= 80: return 3
	else: return 4

func _on_card_manager_metricas_actualizadas(p: Variant, c: Variant, i: Variant, d: Variant) -> void:
	# Actualizar la barra de presupuesto
	if barra_presupuesto:
		barra_presupuesto.value = int(p)

	if confidencialidad.size() > 0: icon_confidencialidad.texture = confidencialidad[obtener_indice(c)]
	if integridad.size() > 0: icon_integridad.texture = integridad[obtener_indice(i)]
	if disponibilidad.size() > 0: icon_disponibilidad.texture = disponibilidad[obtener_indice(d)]


# Recibe el efecto de la decisión. Si es null, apaga todo.
func mostrar_indicadores(efecto) -> void:
	if efecto == null:
		circulo_integridad.visible = false
		circulo_disponibilidad.visible = false
		circulo_confidencialidad.visible = false
		
		label_presupuesto.visible = false
		label_integridad.visible = false
		label_disponibilidad.visible = false
		label_confidencialidad.visible = false
	else:
		# Se hacen visibles SOLO si el efecto matemático no es 0
		circulo_integridad.visible = (efecto["integridad"] != 0)
		circulo_disponibilidad.visible = (efecto["disponibilidad"] != 0)
		circulo_confidencialidad.visible = (efecto["confidencialidad"] != 0)
		
		# Mostrar los números predictivos de Análisis de Impacto (dimensión Lingüística 5)
		_actualizar_label_efecto(label_presupuesto, efecto["presupuesto"])
		_actualizar_label_efecto(label_confidencialidad, efecto["confidencialidad"])
		_actualizar_label_efecto(label_integridad, efecto["integridad"])
		_actualizar_label_efecto(label_disponibilidad, efecto["disponibilidad"])

# Helper para actualizar el texto y color del label de impacto predictivo
func _actualizar_label_efecto(label: Label, valor: int) -> void:
	if not LsgCore.active_mechanics.get("analisis", false) or valor == 0:
		label.visible = false
		return
		
	label.visible = true
	if valor > 0:
		label.text = "+" + str(valor)
		label.add_theme_color_override("font_color", Color(0.12, 0.85, 0.44, 1.0)) # Verde estético
	else:
		label.text = str(valor)
		label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25, 1.0)) # Rojo estético
