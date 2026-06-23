extends Node2D

signal metricas_actualizadas(p, c, i, d)

@export var carta_escena: PackedScene # Escena de la carta
@export var imagenes: Array[Texture2D] = [] # Arreglo de texturas cargado desde el inspector
@export var label_contexto: Label
@export var typing_sound: AudioStreamPlayer2D
@export var feedback_menu: Control = null

# Precargamos los overlays
const GAME_OVER_SCENE = preload("res://Game_over/Game_over.tscn")
const GAME_WINNER_SCENE = preload("res://game_winner/game_winner.tscn")


@onready var spawn_point = $SpawnPoint

var tween_texto: Tween = null
var texto_actual: String = ""
var chars_mostrados: int = 0

# Valores internos del 0 al 100
var presupuesto_actual: int = 50
var confidencialidad_actual: int = 50
var integridad_actual: int = 50
var disponibilidad_actual: int = 50

var cartas = [
	{
		"imagen": 0, 
		"contexto": "Llega un correo urgente del 'SII' advirtiendo sobre una multa por diferencias en la Declaración de Renta. Pide descargar un PDF adjunto para ver el detalle en 24 horas o habrá embargo.",
		"texto_izquierda": "Borrar correo",
		"texto_derecha": "Descargar PDF",
		"correcto": -1.0, 
		"explicacion": "El SII nunca envía archivos PDF adjuntos ni links de descarga directa para multas. Es un clásico ataque de Phishing para instalar malware.",
		"efecto_izquierda": { "presupuesto": 0, "confidencialidad": +10, "integridad": +10, "disponibilidad": 0 },
		"efecto_derecha": { "presupuesto": -20, "confidencialidad": -30, "integridad": -30, "disponibilidad": -10 }
	},
	{
		"imagen": 1, 
		"contexto": "Recibes un WhatsApp de un número desconocido, pero tiene la foto de tu contador. Dice: 'Hola, cambié de número. Tuve un problema con el banco, ¿me puedes transferir urgente los honorarios a esta nueva Cuenta RUT?'",
		"texto_izquierda": "Transferir rápido",
		"texto_derecha": "Llamar al número antiguo",
		"correcto": 1.0, 
		"explicacion": "Es el 'Cuento del Tío' digital (Suplantación de identidad). Siempre debes verificar por otro canal de comunicación antes de transferir dinero a cuentas nuevas.",
		"efecto_izquierda": { "presupuesto": -40, "confidencialidad": -10, "integridad": 0, "disponibilidad": 0 },
		"efecto_derecha": { "presupuesto": +10, "confidencialidad": +10, "integridad": 0, "disponibilidad": 0 }
	},
	{
		"imagen": 0, 
		"contexto": "El encargado de bodega encuentra un pendrive plateado tirado en el estacionamiento de la empresa. Te lo trae a tu escritorio para que lo revises y veas si tiene el nombre del dueño adentro.",
		"texto_izquierda": "Entregar a TI / Botar",
		"texto_derecha": "Conectarlo al PC",
		"correcto": -1.0, 
		"explicacion": "Ataque de 'Baiting' (Cebo). Conectar un USB desconocido puede ejecutar un código malicioso instantáneamente en la red de la empresa sin que te des cuenta.",
		"efecto_izquierda": { "presupuesto": 0, "confidencialidad": 0, "integridad": +15, "disponibilidad": +10 },
		"efecto_derecha": { "presupuesto": -15, "confidencialidad": -20, "integridad": -35, "disponibilidad": -25 }
	},
	{
		"imagen": 1, 
		"contexto": "Aparece un mensaje en el servidor principal de ventas: 'Actualización crítica de sistema pendiente'. Requiere reiniciar el equipo y tomará unos 45 minutos. Estamos en pleno horario de atención a clientes.",
		"texto_izquierda": "Posponer 1 semana",
		"texto_derecha": "Actualizar ahora",
		"correcto": 1.0, 
		"explicacion": "Los ciberdelincuentes aprovechan las vulnerabilidades no parcheadas. Aunque cueste ventas momentáneas, posponer parches de seguridad abre la puerta a ataques de Ransomware.",
		"efecto_izquierda": { "presupuesto": +15, "confidencialidad": -20, "integridad": -30, "disponibilidad": +15 },
		"efecto_derecha": { "presupuesto": -15, "confidencialidad": +20, "integridad": +30, "disponibilidad": -20 }
	},
	{
		"imagen": 0, 
		"contexto": "Entró un practicante nuevo. Como aún no le crean su correo, tu socio sugiere que use la cuenta compartida 'ventas@mipyme.cl' y le demos la clave 'Ventas2026' por mientras.",
		"texto_izquierda": "Prestarle la cuenta",
		"texto_derecha": "Exigir cuenta propia",
		"correcto": 1.0, 
		"explicacion": "Compartir credenciales rompe el principio de 'No repudio'. Si ocurre una filtración o un error grave desde esa cuenta, será imposible auditar quién fue el responsable.",
		"efecto_izquierda": { "presupuesto": 0, "confidencialidad": -25, "integridad": -15, "disponibilidad": 0 },
		"efecto_derecha": { "presupuesto": -10, "confidencialidad": +25, "integridad": +10, "disponibilidad": 0 }
	}
]

func _ready():
	randomize()
	
	# Configurar el CardManager para procesarse siempre (incluso en pausa)
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Reiniciar el puntaje de la ronda actual a 0 al comenzar la partida
	CapsulaManager.puntaje_ronda_actual = 0
	
	# Cartas Dinamicas (Se deja obsoleto las cartas anteriores, mas tarde las borro :D)
	var cartas_dinamicas = CapsulaManager.obtener_cartas_de_capsula_activa()
	if not cartas_dinamicas.is_empty():
		# Duplicamos con .duplicate() para no vaciar el JSON original en memoria
		cartas = cartas_dinamicas.duplicate()
	
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

	
	
func _process(_delta):
	if not label_contexto:
		return
	
	var actuales = label_contexto.visible_characters
	
	if actuales > chars_mostrados:
		chars_mostrados = actuales
		
		# Evita sonido en espacios
		if chars_mostrados <= texto_actual.length():
			var char = texto_actual[chars_mostrados - 1]
			if char != " ":
				typing_sound.play()

func generar_carta():
	# Si ya no quedan cartas en la baraja local, el jugador ha ganado
	if cartas.is_empty():
		ganar_juego()
		return
		
	if imagenes.is_empty():
		return
	
	var nueva_carta = carta_escena.instantiate()
	# Forzar que la carta sea pausada cuando get_tree().paused es true
	nueva_carta.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(nueva_carta)
	
	# Posición controlada por el spawn
	nueva_carta.set_posicion_inicial(spawn_point.global_position)
	
	var indice = obtener_indice_carta()
	var data = cartas[indice]
	
	# Removemos la carta seleccionada para vaciar la lista
	cartas.remove_at(indice)
	
	var textura = imagenes[data["imagen"]] #Guarda la textura seleccionada en el data
	
	nueva_carta.configurar(data, textura) # Configuración completa de la carta
	nueva_carta.carta_procesada.connect(_on_carta_procesada.bind(data)) # Conectar señal
	nueva_carta.intencion_decision.connect(_on_intencion_decision.bind(data))
	# Mostrar contexto con animación
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
	
	var duracion = texto.length() * 0.05
	
	tween_texto.tween_property(
		label_contexto,
		"visible_characters",
		texto.length(),
		duracion
	)

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
			rich_explicacion.text = data.get("explicacion", "No hay explicación disponible.")
		
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
	CapsulaManager.registrar_fin_de_juego(true)
	
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
