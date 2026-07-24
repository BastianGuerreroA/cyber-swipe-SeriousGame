extends Node2D
@export var MusicaFondo: AudioStreamPlayer2D

func _ready() -> void:
	MusicaFondo.play()
	
	# Escuchar cambios de sesión en tiempo real para actualizar la interfaz
	LsgAuth.login_success.connect(func(_name): _configurar_interfaz_lsg())
	LsgAuth.logged_out.connect(func(): _configurar_interfaz_lsg())
	
	_configurar_interfaz_lsg()

func _configurar_interfaz_lsg() -> void:
	var margin_container = get_node_or_null("CanvasLayer/MarginContainer")
	if not margin_container:
		return
		
	# Limpiamos cualquier instancia previa de LoginPanel o PerfilLSG
	var login_previo = margin_container.get_node_or_null("LoginPanel")
	if login_previo:
		login_previo.queue_free()
		
	var perfil_previo = margin_container.get_node_or_null("PerfilLSG")
	if perfil_previo:
		perfil_previo.queue_free()
		
	# Instanciamos el HUD de perfil sólo si el usuario está autenticado
	if LsgAuth.logged_in:
		var perfil_escena = load("res://src/ui/multidimensional_profile/escena_perfil_multidimensional.tscn")
		var perfil_instancia = perfil_escena.instantiate()
		perfil_instancia.name = "PerfilLSG"
		
		# Alinear en la esquina superior izquierda
		perfil_instancia.layout_mode = 2
		perfil_instancia.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		perfil_instancia.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		
		margin_container.add_child(perfil_instancia)
		print("LSG-Core: Cargada escena de Perfil Multidimensional en partida.")

func _on_boton_pausa_pressed() -> void:
	# 1. Ocultamos el botón de pausa para que desaparezca
	$CanvasLayer/MarginContainer/BotonPausa.visible = false
	
	# 2. Hacemos visible el menú de pausa
	$CanvasLayer/MarginContainer/PauseMenu.visible = true
	
	# 3. Congelamos el juego
	get_tree().paused = true
