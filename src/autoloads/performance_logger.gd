extends Node

## PerformanceLogger Singleton (Autoload)
## Módulo de telemetría interna para CyberSwipe.
## Registra el rendimiento del dispositivo cada segundo y exporta los resultados en CSV al cerrar la aplicación.

# Rutas de exportación en el almacenamiento de usuario
const LOG_FILE_PATH: String = "user://performance_log.csv"
const SUMMARY_FILE_PATH: String = "user://performance_summary.csv"

# Intervalo de muestreo (1 segundo)
const SAMPLE_INTERVAL: float = 1.0

# Variables de tiempo y estado
var _start_timestamp_msec: int = 0
var _start_datetime_str: String = ""
var _timer_accumulator: float = 0.0
var _sample_count: int = 0

var _initial_load_time: float = -1.0
var _is_initial_load_done: bool = false
var _total_gameplay_time: float = 0.0

# Almacenamiento en memoria para métricas consolidadas
var _log_entries: Array[Dictionary] = []

# Referencia a archivo de log para escritura incremental continua
var _file_log: FileAccess = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_start_timestamp_msec = Time.get_ticks_msec()
	_start_datetime_str = Time.get_datetime_string_from_system(false, true)
	
	_abrir_archivo_log()
	
	print("[PerformanceLogger] Módulo de telemetría iniciado.")
	print("[PerformanceLogger] Directorio de datos del usuario: ", OS.get_user_data_dir())

func _abrir_archivo_log() -> void:
	_file_log = FileAccess.open(LOG_FILE_PATH, FileAccess.WRITE)
	if _file_log:
		# Encabezado CSV estándar
		var header := "Tiempo,FPS,FrameTime(ms),Memoria(MB),MemoriaMax(MB),DrawCalls,Objetos,Nodos,NodosHuerfanos,VRAM(MB),EscenaActual\n"
		_file_log.store_string(header)
		_file_log.flush()
	else:
		push_error("[PerformanceLogger] No se pudo crear el archivo log en: " + LOG_FILE_PATH)

func _process(delta: float) -> void:
	_timer_accumulator += delta
	if _timer_accumulator >= SAMPLE_INTERVAL:
		_timer_accumulator -= SAMPLE_INTERVAL
		_registrar_muestra()

## Marca el momento en que se completa la carga inicial (ej. Menú Principal listo)
func mark_initial_load_complete() -> void:
	if not _is_initial_load_done:
		_is_initial_load_done = true
		_initial_load_time = (Time.get_ticks_msec() - _start_timestamp_msec) / 1000.0
		print("[PerformanceLogger] Tiempo de carga inicial registrado: %.2fs" % _initial_load_time)

func _registrar_muestra() -> void:
	var tiempo_seg: int = _sample_count
	_sample_count += 1
	
	# Si la carga inicial aún no ha sido marcada explícitamente, la registramos con la primera escena activa
	if not _is_initial_load_done:
		var curr_scene = get_tree().current_scene
		if curr_scene != null:
			mark_initial_load_complete()

	# Captura de métricas nativas de Godot mediante Performance y RenderingServer
	var fps: float = Performance.get_monitor(Performance.TIME_FPS)
	var process_time_ms: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var static_mem_mb: float = Performance.get_monitor(Performance.MEMORY_STATIC) / (1024.0 * 1024.0)
	var static_mem_max_mb: float = Performance.get_monitor(Performance.MEMORY_STATIC_MAX) / (1024.0 * 1024.0)
	var draw_calls: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var object_count: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var node_count: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var orphan_nodes: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var vram_mb: float = float(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED)) / (1024.0 * 1024.0)
	
	var scene_name: String = "Desconocida"
	var current_scene = get_tree().current_scene
	if current_scene:
		scene_name = current_scene.name
		var scene_path: String = current_scene.scene_file_path.to_lower() if current_scene.scene_file_path else ""
		if "gameplay" in scene_path or "escena_principal" in scene_path or "escena_estudio" in scene_path:
			_total_gameplay_time += SAMPLE_INTERVAL

	var record := {
		"tiempo": tiempo_seg,
		"fps": fps,
		"frame_time": process_time_ms,
		"memoria": static_mem_mb,
		"memoria_max": static_mem_max_mb,
		"draw_calls": draw_calls,
		"objetos": object_count,
		"nodos": node_count,
		"nodos_huerfanos": orphan_nodes,
		"vram": vram_mb,
		"escena": scene_name
	}
	
	_log_entries.append(record)
	
	# Escritura incremental continua al CSV
	if _file_log:
		var line := "%d,%.1f,%.2f,%.2f,%.2f,%d,%d,%d,%d,%.2f,%s\n" % [
			tiempo_seg, fps, process_time_ms, static_mem_mb, static_mem_max_mb,
			draw_calls, object_count, node_count, orphan_nodes, vram_mb, scene_name
		]
		_file_log.store_string(line)
		_file_log.flush()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE or what == NOTIFICATION_APPLICATION_PAUSED:
		guardar_resumen()

## Guarda el resumen consolidado final en performance_summary.csv
func guardar_resumen() -> void:
	if _file_log:
		_file_log.close()
		_file_log = null
		
	var summary_file := FileAccess.open(SUMMARY_FILE_PATH, FileAccess.WRITE)
	if not summary_file:
		push_error("[PerformanceLogger] No se pudo crear el archivo de resumen en: " + SUMMARY_FILE_PATH)
		return

	var end_datetime_str: String = Time.get_datetime_string_from_system(false, true)
	var total_session_time: float = (Time.get_ticks_msec() - _start_timestamp_msec) / 1000.0

	var total_fps: float = 0.0
	var min_fps: float = 9999.0
	var max_fps: float = 0.0
	
	var total_frame_time: float = 0.0
	var total_mem: float = 0.0
	var max_mem: float = 0.0
	var total_draw_calls: float = 0.0
	var max_draw_calls: int = 0
	var total_objects: float = 0.0

	if _log_entries.size() > 0:
		for entry in _log_entries:
			var fps_val: float = entry["fps"]
			total_fps += fps_val
			if fps_val < min_fps:
				min_fps = fps_val
			if fps_val > max_fps:
				max_fps = fps_val

			total_frame_time += entry["frame_time"]

			var mem_val: float = entry["memoria"]
			total_mem += mem_val
			if entry["memoria_max"] > max_mem:
				max_mem = entry["memoria_max"]
			if mem_val > max_mem:
				max_mem = entry["memoria_max"]

			var dc_val: int = entry["draw_calls"]
			total_draw_calls += dc_val
			if dc_val > max_draw_calls:
				max_draw_calls = dc_val

			total_objects += entry["objetos"]
	else:
		min_fps = 0.0

	var count: int = max(1, _log_entries.size())
	var avg_fps: float = total_fps / count
	var avg_frame_time: float = total_frame_time / count
	var avg_mem: float = total_mem / count
	var avg_draw_calls: float = total_draw_calls / count
	var avg_objects: float = total_objects / count

	var initial_load_val: String = "%.2f" % _initial_load_time if _initial_load_time >= 0 else "N/A"

	summary_file.store_string("Métrica,Valor\n")
	summary_file.store_string("FPS promedio,%.1f\n" % avg_fps)
	summary_file.store_string("FPS mínimo,%.1f\n" % min_fps)
	summary_file.store_string("FPS máximo,%.1f\n" % max_fps)
	summary_file.store_string("FrameTime promedio (ms),%.2f\n" % avg_frame_time)
	summary_file.store_string("Memoria promedio (MB),%.2f\n" % avg_mem)
	summary_file.store_string("Memoria máxima (MB),%.2f\n" % max_mem)
	summary_file.store_string("DrawCalls promedio,%.1f\n" % avg_draw_calls)
	summary_file.store_string("DrawCalls máximo,%d\n" % max_draw_calls)
	summary_file.store_string("Objetos promedio,%.1f\n" % avg_objects)
	summary_file.store_string("Tiempo carga inicial (s),%s\n" % initial_load_val)
	summary_file.store_string("Tiempo partida (s),%.1f\n" % _total_gameplay_time)
	summary_file.store_string("Tiempo total sesion (s),%.1f\n" % total_session_time)
	summary_file.store_string("Total registros,%d\n" % _log_entries.size())
	summary_file.store_string("Sistema Operativo,%s\n" % OS.get_name())
	summary_file.store_string("Modelo Dispositivo,%s\n" % OS.get_model_name())
	
	var vp_size = get_viewport().get_visible_rect().size if get_viewport() else Vector2.ZERO
	summary_file.store_string("Resolucion Viewport,%dx%d\n" % [int(vp_size.x), int(vp_size.y)])
	
	var render_method: String = String(ProjectSettings.get_setting("rendering/renderer/rendering_method", "Desconocido"))
	summary_file.store_string("Renderizador,%s\n" % render_method)
	summary_file.store_string("Fecha y Hora Inicio,%s\n" % _start_datetime_str)
	summary_file.store_string("Fecha y Hora Fin,%s\n" % end_datetime_str)

	summary_file.flush()
	summary_file.close()
	print("[PerformanceLogger] Resumen de rendimiento guardado en: ", SUMMARY_FILE_PATH)
