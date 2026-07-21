extends Area2D

# Definimos una señal que avisará al administrador
signal carta_procesada(direccion)
signal intencion_decision(estado) # -1 izquierda, 0 centro, 1 derecha

var intencion_actual: int = 0 # Para no enviar la señal 60 veces por segundo


@onready var sprite = $Sprite2D
@onready var overlay = $SombraSuperpuesta
@onready var label = $SombraSuperpuesta/TextoDecision

# Estado de arrastre
var arrastrando: bool = false
# Posición original de la carta (centro)
var posicion_inicial: Vector2
# Diferencia entre mouse y posición de la carta al iniciar drag
var offset: Vector2
# Tween activo para animaciones
var tween_actual: Tween = null

#Para guardiar los futuros textos
var texto_izquierda: String
var texto_derecha: String
var respuesta_correcta: float

# Configuración de la mecánica
@export var umbral_decision: float = 200.0      # Distancia para validar decisión
@export var rotacion_maxima: float = 15.0       # Inclinación máxima
@export var velocidad_retorno: float = 0.3      # Tiempo de retorno al centro

func _ready():
	# Conecta el evento de input sobre el área
	input_event.connect(_on_input_event)
	
	overlay.visible = false
	overlay.modulate.a = 0
	
func configurar(data, textura: Texture2D):
	sprite.texture = textura
	texto_izquierda = data["texto_izquierda"]
	texto_derecha = data["texto_derecha"]
	respuesta_correcta = data["correcto"]

func _on_input_event(_viewport, event, _shape_idx):
	# Detecta inicio de click o toque sobre la carta
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.pressed:
			iniciar_arrastre()

func iniciar_arrastre():
	arrastrando = true
	
	# Calcula offset en coordenadas globales para evitar salto
	offset = get_global_mouse_position() - global_position
	
	# Detiene animaciones activas
	if tween_actual:
		tween_actual.kill()
		
	overlay.visible = true

func _process(_delta):
	# Mientras se arrastra, actualiza posición y efectos
	if arrastrando:
		mover_carta()
		actualizar_efecto_visual()

func mover_carta():
	# Sigue el mouse manteniendo el offset
	var nueva_pos = get_global_mouse_position() - offset
	
	# Bloquea movimiento vertical (solo swipe horizontal)
	nueva_pos.y = posicion_inicial.y
	
	global_position = nueva_pos
	

func actualizar_efecto_visual():
	# Calcula desplazamiento horizontal respecto al centro
	var delta_x = global_position.x - posicion_inicial.x
	
	# Normaliza valor para rotación
	var porcentaje = clamp(delta_x / (umbral_decision * 1.5), -1.0, 1.0)
	
	# Aplica rotación proporcional
	rotation_degrees = porcentaje * rotacion_maxima
	
	actualizar_overlay(porcentaje)
	
func actualizar_overlay(porcentaje: float):
	var nueva_intencion = 0
	
	if abs(porcentaje) < 0.05:
		overlay.modulate.a = 0
		nueva_intencion = 0
	else:
		var intensidad = clamp(abs(porcentaje) * 3.0, 0.0, 0.8)
		overlay.modulate.a = intensidad
		
		if porcentaje > 0:
			label.text = texto_derecha
			nueva_intencion = 1
		else:
			label.text = texto_izquierda
			nueva_intencion = -1
			
	# Si cambiamos de dirección, avisamos al Manager
	if nueva_intencion != intencion_actual:
		intencion_actual = nueva_intencion
		intencion_decision.emit(intencion_actual)


func _input(event):
	# Detecta cuando se suelta el click o toque
	if (event is InputEventMouseButton or event is InputEventScreenTouch):
		if not event.pressed and arrastrando:
			finalizar_arrastre()

func finalizar_arrastre():
	arrastrando = false
	
	# Calcula cuánto se desplazó la carta
	var delta_x = global_position.x - posicion_inicial.x
	
	# Si supera el umbral, ejecuta decisión
	if abs(delta_x) > umbral_decision:
		var direccion = 1.0 if delta_x > 0 else -1.0
		ejecutar_salida(direccion)
	else:
		# Si no, vuelve al centro
		regresar_al_centro()
		
#Funcion para actualizar la posicion inicial desde el CardManager
func set_posicion_inicial(pos: Vector2): 
	posicion_inicial = pos
	global_position = pos

func regresar_al_centro():
	# Animación de retorno a la posición inicial
	tween_actual = get_tree().create_tween()
	tween_actual.set_parallel(true)
	tween_actual.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	tween_actual.tween_property(self, "global_position", posicion_inicial, velocidad_retorno)
	tween_actual.tween_property(self, "rotation_degrees", 0.0, velocidad_retorno)
	
	overlay.visible = false
	overlay.modulate.a = 0	
	
	intencion_actual = 0
	intencion_decision.emit(0)


func ejecutar_salida(direccion: float):
	# Mueve la carta fuera de la pantalla según decisión
	var destino = posicion_inicial + Vector2(1000 * direccion, 0)
	
	tween_actual = get_tree().create_tween()
	tween_actual.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	tween_actual.tween_property(self, "global_position", destino, 0.4)
	
	tween_actual.finished.connect(func():
		_on_carta_fuera(direccion)
	)

func _on_carta_fuera(direccion):
	# Emitimos la señal avisando que ya terminamos
	carta_procesada.emit(direccion)
	#if direccion > 0: #Cuando es 1.0 signfica derecha
		#print("Derecha")
	#else:			  #Cuando es -1.0 signfica izquierda
		#print("izquierda")
	overlay.visible = false
	queue_free() # Elimina la carta
