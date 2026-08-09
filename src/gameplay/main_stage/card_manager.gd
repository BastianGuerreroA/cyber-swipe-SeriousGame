extends Node2D

signal metricas_actualizadas(p, c, i, d)

@export var carta_escena: PackedScene # Escena de la carta
@export var imagenes: Array[Texture2D] = [] # Arreglo de texturas cargado desde el inspector
@export var label_contexto: Label
@export var typing_sound: AudioStreamPlayer2D
@export var feedback_menu: Control = null

# Precargamos los overlays
const GAME_OVER_SCENE = preload("res://src/ui/game_over/Game_over.tscn")
const GAME_WINNER_SCENE = preload("res://src/ui/game_winner/game_winner.tscn")


@onready var spawn_point = $SpawnPoint

var tween_texto: Tween = null
var texto_actual: String = ""
var chars_mostrados: int = 0

# Valores internos del 0 al 100
var presupuesto_actual: int = 50
var confidencialidad_actual: int = 50
var integridad_actual: int = 50
var disponibilidad_actual: int = 50

var cartas = []
var nodo_carta = null

func _ready():
	randomize()
	
	# Configurar el CardManager para procesarse siempre (incluso en pausa)
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Reiniciar el puntaje de la ronda actual a 0 al comenzar la partida
	CapsulaManager.puntaje_ronda_actual = 0
	
	# Cartas Dinamicas (Se aleatoriza la dirección de las opciones con probabilidad del 50%)
	var cartas_dinamicas = CapsulaManager.obtener_cartas_de_capsula_activa()
	if not cartas_dinamicas.is_empty():
		cartas = _aleatorizar_direcciones_cartas(cartas_dinamicas)
	
	# Fallback dinámico si no está enlazado en el inspector
	if not feedback_menu:
		feedback_menu = get_node_or_null("../CanvasLayer/MarginContainer/FeedbackMenu")
	
	# Conectar el botón de continuar del menú de retroalimentación
	if feedback_menu:
		var boton_continuar = feedback_menu.get_node_or_null("PanelContainer/MarginContainer/VBoxContainer/Continuar")
		if boton_continuar:
			# Desconectar si ya estaba conectado (evita conexiones duplicadas)
			if boton_continuar.pressed.is_connected(_on_feedback_continuar_pressed):
				boton_continuar.pressed.disconnect(_on_feedback_continuar_pressed)
			boton_continuar.pressed.connect(_on_feedback_continuar_pressed)
	
	if LsgCore.active_mechanics.get("consultoria", false):
		presupuesto_actual = 60
		confidencialidad_actual = 60
		integridad_actual = 60
		disponibilidad_actual = 60
		print("LSG-Core: Aplicada Consultoria Preventiva. Recursos iniciales en 60.")
		
	# Emitir los valores iniciales para sincronizar la UI
	metricas_actualizadas.emit(presupuesto_actual, confidencialidad_actual, integridad_actual, disponibilidad_actual)
	
	generar_carta()

	
	
func _actualizar_caracteres_visibles(actuales: int) -> void:
	if label_contexto:
		label_contexto.visible_characters = actuales
	if actuales > chars_mostrados:
		chars_mostrados = actuales
		if chars_mostrados <= texto_actual.length():
			var char_actual = texto_actual[chars_mostrados - 1]
			if char_actual != " " and typing_sound:
				typing_sound.play()

func generar_carta():
	# Si ya no quedan cartas en la baraja local, el jugador ha ganado
	if cartas.is_empty():
		if nodo_carta and is_instance_valid(nodo_carta):
			nodo_carta.visible = false
		ganar_juego()
		return
		
	if imagenes.is_empty():
		return
	
	if not nodo_carta or not is_instance_valid(nodo_carta):
		nodo_carta = carta_escena.instantiate()
		nodo_carta.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(nodo_carta)
	
	nodo_carta.visible = true
	nodo_carta.rotation_degrees = 0.0
	nodo_carta.set_posicion_inicial(spawn_point.global_position)
	
	var indice = obtener_indice_carta()
	var data = cartas[indice]
	
	# Removemos la carta seleccionada para vaciar la lista
	cartas.remove_at(indice)
	
	var textura = imagenes[data["imagen"]]
	
	nodo_carta.configurar(data, textura)
	
	if nodo_carta.carta_procesada.is_connected(_on_carta_procesada):
		nodo_carta.carta_procesada.disconnect(_on_carta_procesada)
	if nodo_carta.intencion_decision.is_connected(_on_intencion_decision):
		nodo_carta.intencion_decision.disconnect(_on_intencion_decision)
		
	nodo_carta.carta_procesada.connect(_on_carta_procesada.bind(data))
	nodo_carta.intencion_decision.connect(_on_intencion_decision.bind(data))
	
	mostrar_contexto(data["contexto"])

func obtener_indice_carta() -> int:
	return randi() % cartas.size()
	
func mostrar_contexto(texto: String):
	if tween_texto:
		tween_texto.kill()
	
	texto_actual = texto
	label_contexto.text = texto
	label_contexto.visible_characters = 0
	chars_mostrados = 0
	
	tween_texto = get_tree().create_tween()
	var duracion = texto.length() * 0.04
	tween_texto.tween_method(_actualizar_caracteres_visibles, 0, texto.length(), duracion)

func obtener_efectos_modificados(efecto: Dictionary, es_correcta: bool) -> Dictionary:
	var modificado = efecto.duplicate()
	
	# Subsidio de Seguridad (ID 47, Dimensión Social 1):
	# Reduce en un 20% las pérdidas en Presupuesto en decisiones correctas.
	if LsgCore.active_mechanics.get("subsidio", false) and es_correcta:
		if modificado.get("presupuesto", 0) < 0:
			modificado["presupuesto"] = int(round(modificado["presupuesto"] * 0.8))
			
	# Ciberseguro Activo (ID 48, Dimensión Físico 2):
	# Mitiga a la mitad (50%) todos los daños a la Integridad y Disponibilidad.
	if LsgCore.active_mechanics.get("ciberseguro", false):
		if modificado.get("integridad", 0) < 0:
			modificado["integridad"] = int(round(modificado["integridad"] * 0.5))
		if modificado.get("disponibilidad", 0) < 0:
			modificado["disponibilidad"] = int(round(modificado["disponibilidad"] * 0.5))
			
	return modificado

func _on_carta_procesada(direccion: float, data):
	
	# 1. Determinar qué efecto usar según hacia dónde deslizó (-1.0 es Izquierda)
	var efecto_base = data["efecto_izquierda"] if direccion == -1.0 else data["efecto_derecha"]
	var es_correcta = (direccion == data["correcto"])
	
	# 2. Aplicar modificadores de mecánicas LSG
	var efecto = obtener_efectos_modificados(efecto_base, es_correcta)
	
	# 3. Aplicar las sumas/restas y evitar que baje de 0 o pase de 100 con 'clamp'
	presupuesto_actual = clamp(presupuesto_actual + efecto["presupuesto"], 0, 100)
	confidencialidad_actual = clamp(confidencialidad_actual + efecto["confidencialidad"], 0, 100)
	integridad_actual = clamp(integridad_actual + efecto["integridad"], 0, 100)
	disponibilidad_actual = clamp(disponibilidad_actual + efecto["disponibilidad"], 0, 100)
	
	# 4. Avisar a los iconos para que cambien las imágenes
	metricas_actualizadas.emit(presupuesto_actual, confidencialidad_actual, integridad_actual, disponibilidad_actual)

	var correcta = true
	# 5. Lógica original del Puntaje de Score
	if direccion == data["correcto"]:
		print("Respuesta correcta")
		var contador = get_node_or_null("../CanvasLayer/MarginContainer/ContadorScore")
		if contador and contador.has_method("sumar_punto"):
			contador.sumar_punto(1)
			# Guardamos el puntaje actual en el manager
			CapsulaManager.puntaje_ronda_actual = contador.puntaje_actual
	else:
		print("Respuesta incorrecta")
		correcta = false
	
	var nodo_iconos = get_node_or_null("../FondoCarta/TextureRect/Iconos")
	if nodo_iconos and nodo_iconos.has_method("mostrar_indicadores"):
		nodo_iconos.mostrar_indicadores(null)

	# Fallback dinámico si no está enlazado
	if not feedback_menu:
		feedback_menu = get_node_or_null("../CanvasLayer/MarginContainer/FeedbackMenu")
		if feedback_menu:
			var boton_continuar = feedback_menu.get_node_or_null("PanelContainer/MarginContainer/VBoxContainer/Continuar")
			if boton_continuar and not boton_continuar.pressed.is_connected(_on_feedback_continuar_pressed):
				boton_continuar.pressed.connect(_on_feedback_continuar_pressed)

	# Si es incorrecta y tenemos el menú de retroalimentación, pausamos el juego
	if not correcta and feedback_menu:
		var rich_explicacion = feedback_menu.get_node_or_null("PanelContainer/MarginContainer/VBoxContainer/Explicacion")
		if rich_explicacion:
			var txt = "[b]¿Qué falló en tu decisión?[/b]\n"
			txt += data.get("explicacion", "No hay explicación disponible.") + "\n\n"
			
			# Detectar métricas afectadas negativamente
			var metricas_afectadas = []
			for m in ["presupuesto", "confidencialidad", "integridad", "disponibilidad"]:
				if efecto.get(m, 0) < 0:
					metricas_afectadas.append(m)
			
			if not metricas_afectadas.is_empty():
				txt += "[b][color=#ff5555]Recursos Afectados Negativamente:[/color][/b]\n"
				var metricas_nombres_es = {
					"presupuesto": "Presupuesto",
					"confidencialidad": "Confidencialidad",
					"integridad": "Integridad",
					"disponibilidad": "Disponibilidad"
				}
				for m in metricas_afectadas:
					txt += "• " + metricas_nombres_es[m] + "\n"
			
			rich_explicacion.text = txt
		
		# Ocultar botones HUD de fondo mientras se muestra la pausa
		var boton_pausa = get_node_or_null("../CanvasLayer/MarginContainer/BotonPausa")
		if boton_pausa:
			boton_pausa.visible = false
			
		feedback_menu.visible = true
		get_tree().paused = true
	else:
		# COMPROBACIÓN DE DERROTA DIRECTA
		if chequear_derrota():
			return
		# Si sobrevive, genera la siguiente carta
		generar_carta()

func _on_feedback_continuar_pressed() -> void:
	if feedback_menu:
		feedback_menu.visible = false
		
	# Restaurar visibilidad del botón de pausa
	var boton_pausa = get_node_or_null("../CanvasLayer/MarginContainer/BotonPausa")
	if boton_pausa:
		boton_pausa.visible = true
		
	get_tree().paused = false
	
	# COMPROBACIÓN DE DERROTA (tras cerrar la retroalimentación)
	if chequear_derrota():
		return
		
	generar_carta()
	
func _on_intencion_decision(estado: int, data):
	var efecto = null
	
	if estado != 0:
		var efecto_base = data["efecto_izquierda"] if estado == -1 else data["efecto_derecha"]
		var es_correcta = (estado == int(data["correcto"]))
		efecto = obtener_efectos_modificados(efecto_base, es_correcta)
	
	var nodo_iconos = get_node_or_null("../FondoCarta/TextureRect/Iconos")
	if nodo_iconos and nodo_iconos.has_method("mostrar_indicadores"):
		nodo_iconos.mostrar_indicadores(efecto)


func ganar_juego() -> void:
	# 1. Verificar si la cápsula ya fue completada anteriormente (antes de registrar el nuevo progreso)
	var ya_completada = CapsulaManager.capsula_activa_id < CapsulaManager.progreso_general
	
	CapsulaManager.registrar_fin_de_juego(true)
	
	if LsgAuth.logged_in:
		LsgLogger.log_game_result(CapsulaManager.capsula_activa_id, "win", CapsulaManager.puntaje_ronda_actual)
		
		# Acreditación de puntos reales en LSG (Dimensión Mental, attribute_id = 4)
		# Solo si la cápsula NO fue completada anteriormente
		if not ya_completada:
			# Fórmula de incentivo: 15 puntos base por completar + 2 puntos por cada respuesta correcta.
			var puntos_a_cargar = 15 + (CapsulaManager.puntaje_ronda_actual * 2)
			print("LSG-Core: Intentando acreditar ", puntos_a_cargar, " puntos en Mental por completar capsula.")
			LsgCore.adjust_points(4, "CREDIT", puntos_a_cargar, "capsule_completed")
		else:
			print("LSG-Core: Capsula ya completada anteriormente. No se acreditan puntos de recompensa.")
	
	# Buscamos el CanvasLayer del HUD
	var canvas = get_node_or_null("../CanvasLayer")
	if canvas:
		# Ocultamos el botón de pausa y el menú de pausa si estuviera abierto
		var boton_pausa = canvas.get_node_or_null("MarginContainer/BotonPausa")
		if boton_pausa:
			boton_pausa.visible = false
			
		# Instanciamos el overlay de victoria
		var win_overlay = GAME_WINNER_SCENE.instantiate()
		canvas.add_child(win_overlay)
		
	# Congelamos los procesos del juego de fondo
	get_tree().paused = true
	

func perder_juego() -> void:
	CapsulaManager.registrar_fin_de_juego(false)
	if LsgAuth.logged_in:
		LsgLogger.log_game_result(CapsulaManager.capsula_activa_id, "lose", CapsulaManager.puntaje_ronda_actual)
	
	var canvas = get_node_or_null("../CanvasLayer")
	if canvas:
		var boton_pausa = canvas.get_node_or_null("MarginContainer/BotonPausa")
		if boton_pausa:
			boton_pausa.visible = false
			
		# Instanciamos el overlay de derrota
		var lose_overlay = GAME_OVER_SCENE.instantiate()
		canvas.add_child(lose_overlay)
		
	get_tree().paused = true

func chequear_derrota() -> bool:
	if presupuesto_actual <= 0:
		CapsulaManager.metrica_fallida = "presupuesto"
		perder_juego()
		return true
	elif confidencialidad_actual <= 0:
		CapsulaManager.metrica_fallida = "confidencialidad"
		perder_juego()
		return true
	elif integridad_actual <= 0:
		CapsulaManager.metrica_fallida = "integridad"
		perder_juego()
		return true
	elif disponibilidad_actual <= 0:
		CapsulaManager.metrica_fallida = "disponibilidad"
		perder_juego()
		return true
	return false

# Restaura la métrica fallida a 50, limpia el estado de fallo y reanuda el flujo del juego
func revivir_jugador() -> void:
	var fallida = CapsulaManager.metrica_fallida
	print("LSG-Core: Reviviendo jugador. Restaurando metrica fallida '", fallida, "' a 50.")
	match fallida:
		"presupuesto":
			presupuesto_actual = 50
		"confidencialidad":
			confidencialidad_actual = 50
		"integridad":
			integridad_actual = 50
		"disponibilidad":
			disponibilidad_actual = 50
			
	CapsulaManager.metrica_fallida = ""
	
	# Actualizar UI de métricas e iconos
	metricas_actualizadas.emit(presupuesto_actual, confidencialidad_actual, integridad_actual, disponibilidad_actual)
	
	# Continuar partida
	generar_carta()

# Aleatoriza la dirección (izquierda/derecha) de las respuestas con 50% de probabilidad
func _aleatorizar_direcciones_cartas(lista_original: Array) -> Array:
	var lista_resultado: Array = []
	
	for carta_dict in lista_original:
		var c = carta_dict.duplicate(true)
		
		# 50% de probabilidad de invertir los lados
		if randf() < 0.5:
			var temp_texto = c.get("texto_izquierda", "")
			c["texto_izquierda"] = c.get("texto_derecha", "")
			c["texto_derecha"] = temp_texto
			
			var temp_efecto = c.get("efecto_izquierda", {}).duplicate()
			c["efecto_izquierda"] = c.get("efecto_derecha", {}).duplicate()
			c["efecto_derecha"] = temp_efecto
			
			if c.has("correcto"):
				c["correcto"] = -float(c["correcto"])
				
		lista_resultado.append(c)
		
	return lista_resultado
