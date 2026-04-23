extends Node2D

@export var carta_escena: PackedScene # Escena de la carta
@export var imagenes: Array[Texture2D] = [] # Arreglo de texturas cargado desde el inspector
@export var label_contexto: Label
@export var typing_sound: AudioStreamPlayer2D

@onready var spawn_point = $SpawnPoint

var tween_texto: Tween = null
var texto_actual: String = ""
var chars_mostrados: int = 0

var cartas = [
	{
		"imagen": 0, # Sugerencia: Icono de un correo con logo del SII falso
		"contexto": "Llega un correo urgente del 'SII' advirtiendo sobre una multa por diferencias en la Declaración de Renta. Pide descargar un PDF adjunto para ver el detalle en 24 horas o habrá embargo.",
		"texto_izquierda": "Borrar correo",
		"texto_derecha": "Descargar PDF",
		"correcto": -1.0, # Izquierda
		"explicacion": "El SII nunca envía archivos PDF adjuntos ni links de descarga directa para multas. Es un clásico ataque de Phishing para instalar malware."
	},
	{
		"imagen": 1, # Sugerencia: Icono de WhatsApp o un personaje de un contador
		"contexto": "Recibes un WhatsApp de un número desconocido, pero tiene la foto de tu contador. Dice: 'Hola, cambié de número. Tuve un problema con el banco, ¿me puedes transferir urgente los honorarios a esta nueva Cuenta RUT?'",
		"texto_izquierda": "Transferir rápido",
		"texto_derecha": "Llamar al número antiguo",
		"correcto": 1.0, # Derecha
		"explicacion": "Es el 'Cuento del Tío' digital (Suplantación de identidad). Siempre debes verificar por otro canal de comunicación antes de transferir dinero a cuentas nuevas."
	},
	{
		"imagen": 0, # Sugerencia: Icono de un Pendrive USB
		"contexto": "El encargado de bodega encuentra un pendrive plateado tirado en el estacionamiento de la empresa. Te lo trae a tu escritorio para que lo revises y veas si tiene el nombre del dueño adentro.",
		"texto_izquierda": "Entregar a TI / Botar",
		"texto_derecha": "Conectarlo al PC",
		"correcto": -1.0, # Izquierda
		"explicacion": "Ataque de 'Baiting' (Cebo). Conectar un USB desconocido puede ejecutar un código malicioso instantáneamente en la red de la empresa sin que te des cuenta."
	},
	{
		"imagen": 1, # Sugerencia: Icono de un Servidor o una alerta de Windows
		"contexto": "Aparece un mensaje en el servidor principal de ventas: 'Actualización crítica de sistema pendiente'. Requiere reiniciar el equipo y tomará unos 45 minutos. Estamos en pleno horario de atención a clientes.",
		"texto_izquierda": "Posponer 1 semana",
		"texto_derecha": "Actualizar ahora",
		"correcto": 1.0, # Derecha
		"explicacion": "Los ciberdelincuentes aprovechan las vulnerabilidades no parcheadas. Aunque cueste ventas momentáneas, posponer parches de seguridad abre la puerta a ataques de Ransomware."
	},
	{
		"imagen": 0, # Sugerencia: Icono de dos personas o un candado abierto
		"contexto": "Entró un practicante nuevo. Como aún no le crean su correo, tu socio sugiere que use la cuenta compartida 'ventas@mipyme.cl' y le demos la clave 'Ventas2026' por mientras.",
		"texto_izquierda": "Prestarle la cuenta",
		"texto_derecha": "Exigir cuenta propia",
		"correcto": 1.0, # Derecha
		"explicacion": "Compartir credenciales rompe el principio de 'No repudio'. Si ocurre una filtración o un error grave desde esa cuenta, será imposible auditar quién fue el responsable."
	}
]


func _ready():
	randomize()
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
	if imagenes.is_empty() or cartas.is_empty(): #No hay imagenes o cartas para cargar
		return
	
	var nueva_carta = carta_escena.instantiate()
	add_child(nueva_carta)
	
	# Posición controlada por el spawn
	nueva_carta.set_posicion_inicial(spawn_point.global_position)
	
	var indice = obtener_indice_carta()
	var data = cartas[indice]
	
	var textura = imagenes[data["imagen"]] #Guarda la textura seleccionada en el data
	
	nueva_carta.configurar(data, textura) # Configuración completa de la carta
	nueva_carta.carta_procesada.connect(_on_carta_procesada.bind(data)) # Conectar señal
	
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
	if direccion == data["correcto"]:
		print("Respuesta correcta")
	else:
		print("Respuesta incorrecta")
	
	# Aquí luego puedes conectar con lógica de juego:
	# seguridad += 1, riesgo -= 1, etc.
	
	generar_carta()
