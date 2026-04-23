extends Area2D

# Variables de control de movimiento
var posicion_inicial: Vector2
var arrastrando: bool = false
var offset_del_toque: Vector2

# Ajustes de la mecánica (puedes tunear estos valores en el Inspector)
@export var umbral_decision: float = 200.0  # Píxeles necesarios para elegir
@export var rotacion_maxima: float = 15.0  # Qué tanto se inclina la carta
@export var velocidad_retorno: float = 0.3 # Segundos que tarda en volver al centro

func _ready():
	# Guardamos la posición donde pusiste la carta en el editor como el "centro"
	posicion_inicial = global_position
	
	# Importante: Para que el Area2D detecte el mouse/dedo, 
	# debe tener activada la opción 'Pickable' en el Inspector (viene activada por defecto).
	# Conectamos la señal de entrada para detectar el primer toque
	input_event.connect(_on_input_event)

func _input(event):
	# Detectamos cuando el jugador suelta el dedo en cualquier parte de la pantalla
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if not event.pressed and arrastrando:
			finalizar_arrastre()

	# Si estamos arrastrando, seguimos la posición del dedo
	if (event is InputEventScreenDrag or event is InputEventMouseMotion) and arrastrando:
		global_position = get_global_mouse_position() - offset_del_toque
		actualizar_efecto_visual()

func _on_input_event(_viewport, event, _shape_idx):
	# Esta función se activa solo cuando el toque ocurre dentro del CollisionShape2D
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			arrastrando = true
			# Calculamos el offset para que la carta no "salte" al centro del dedo
			offset_del_toque = get_global_mouse_position() - global_position			# Detenemos cualquier animación de retorno activa
			var tween = get_tree().create_tween()
			tween.kill()

func actualizar_efecto_visual():
	# Calculamos la distancia horizontal desde el centro
	var delta_x = global_position.x - posicion_inicial.x
	
	# Normalizamos el valor para la rotación (-1 a 1)
	var porcentaje = clamp(delta_x / (umbral_decision * 1.5), -1.0, 1.0)
	rotation_degrees = porcentaje * rotacion_maxima
	
	# Opcional: Aquí podrías añadir lógica para mostrar texto de 
	# "SÍ" o "NO" dependiendo de si delta_x es positivo o negativo.

func finalizar_arrastre():
	arrastrando = false
	var delta_x = global_position.x - posicion_inicial.x
	
	if abs(delta_x) > umbral_decision:
		# El jugador tomó una decisión
		var direccion = 1.0 if delta_x > 0 else -1.0
		ejecutar_salida(direccion)
	else:
		# No fue suficiente, regresa al centro
		regresar_al_centro()

func regresar_al_centro():
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	# Animamos posición y rotación de vuelta al origen
	tween.tween_property(self, "global_position", posicion_inicial, velocidad_retorno)
	tween.tween_property(self, "rotation_degrees", 0.0, velocidad_retorno)

func ejecutar_salida(direccion: float):
	var destino = posicion_inicial + Vector2(1000 * direccion, 0)
	var tween = get_tree().create_tween()
	
	tween.tween_property(self, "global_position", destino, 0.4)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	# Al terminar la animación, avisamos al sistema para procesar la respuesta de ciberseguridad
	tween.finished.connect(_on_carta_fuera)

func _on_carta_fuera():
	# Aquí podrías emitir una señal que el controlador principal escuche
	# para restar presupuesto, subir seguridad, etc.
	print("Carta procesada. Generando siguiente situación...")
	queue_free()
