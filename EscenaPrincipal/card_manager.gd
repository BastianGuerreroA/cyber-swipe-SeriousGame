extends Node2D

signal metricas_actualizadas(p, c, i, d)

@export var carta_escena: PackedScene # Escena de la carta
@export var imagenes: Array[Texture2D] = [] # Arreglo de texturas cargado desde el inspector
@export var label_contexto: Label
@export var typing_sound: AudioStreamPlayer2D

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
	
	# Reiniciar el puntaje de la ronda actual a 0 al comenzar la partida
	CapsulaManager.puntaje_ronda_actual = 0
	
	# Cartas Dinamicas (Se deja obsoleto las cartas anteriores, mas tarde las borro :D)
	var cartas_dinamicas = CapsulaManager.obtener_cartas_de_capsula_activa()
	if not cartas_dinamicas.is_empty():
		# Duplicamos con .duplicate() para no vaciar el JSON original en memoria
		cartas = cartas_dinamicas.duplicate()
	
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

func _on_carta_procesada(direccion: float, data):
	
	# 1. Determinar qué efecto usar según hacia dónde deslizó (-1.0 es Izquierda)
	var efecto = data["efecto_izquierda"] if direccion == -1.0 else data["efecto_derecha"]
	
	# 2. Aplicar las sumas/restas y evitar que baje de 0 o pase de 100 con 'clamp'
	presupuesto_actual = clamp(presupuesto_actual + efecto["presupuesto"], 0, 100)
	confidencialidad_actual = clamp(confidencialidad_actual + efecto["confidencialidad"], 0, 100)
	integridad_actual = clamp(integridad_actual + efecto["integridad"], 0, 100)
	disponibilidad_actual = clamp(disponibilidad_actual + efecto["disponibilidad"], 0, 100)
	
	# 3. Avisar a los iconos para que cambien las imágenes
	metricas_actualizadas.emit(presupuesto_actual, confidencialidad_actual, integridad_actual, disponibilidad_actual)

	# 4. Lógica original del Puntaje de Score
	if direccion == data["correcto"]:
		print("Respuesta correcta")
		var contador = get_node_or_null("../CanvasLayer/MarginContainer/ContadorScore")
		if contador and contador.has_method("sumar_punto"):
			contador.sumar_punto(1)
			# Guardamos el puntaje actual en el manager
			CapsulaManager.puntaje_ronda_actual = contador.puntaje_actual
	else:
		print("Respuesta incorrecta")
	
	var nodo_iconos = get_node_or_null("../FondoCarta/TextureRect/Iconos")
	if nodo_iconos and nodo_iconos.has_method("mostrar_indicadores"):
		nodo_iconos.mostrar_indicadores(null)

	# COMPROBACIÓN DE DERROTA
	# Si alguna métrica llega a 0, termina el juego en derrota
	if presupuesto_actual <= 0 or confidencialidad_actual <= 0 or integridad_actual <= 0 or disponibilidad_actual <= 0:
		perder_juego()
		return
	# Si sobrevive, genera la siguiente carta
	generar_carta()
	
func _on_intencion_decision(estado: int, data):
	var efecto = null
	
	if estado == -1: # Deslizando a la Izquierda
		efecto = data["efecto_izquierda"]
	elif estado == 1: # Deslizando a la Derecha
		efecto = data["efecto_derecha"]
	# Si estado es 0, efecto queda en null (apagará los círculos)
	
	var nodo_iconos = get_node_or_null("../FondoCarta/TextureRect/Iconos")
	if nodo_iconos and nodo_iconos.has_method("mostrar_indicadores"):
		nodo_iconos.mostrar_indicadores(efecto)

func ganar_juego() -> void:
	CapsulaManager.registrar_fin_de_juego()
	
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
	CapsulaManager.registrar_fin_de_juego()
	
	var canvas = get_node_or_null("../CanvasLayer")
	if canvas:
		var boton_pausa = canvas.get_node_or_null("MarginContainer/BotonPausa")
		if boton_pausa:
			boton_pausa.visible = false
			
		# Instanciamos el overlay de derrota
		var lose_overlay = GAME_OVER_SCENE.instantiate()
		canvas.add_child(lose_overlay)
		
	get_tree().paused = true
