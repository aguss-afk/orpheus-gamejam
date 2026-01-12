extends CanvasLayer

@onready var texture_rect = $TextureRect if has_node("TextureRect") else null
@onready var audio_player = $AudioStreamPlayer if has_node("AudioStreamPlayer") else null

# Configuración del movimiento
@export var tipo_movimiento: String = "shake"  # "shake", "zoom", "glitch", "combo"
@export var intensidad: float = 1.0
@export var duracion: float = 2.0  # Duración en segundos

var tiempo: float = 0.0
var posicion_original: Vector2
var tamano_original: Vector2
var tiempo_transcurrido: float = 0.0
var ya_desapareciendo: bool = false  # AÑADIR ESTA LÍNEA

func _ready() -> void:
	print("=== SCREAMER INICIADO ===")
	
	# Guardar valores originales
	if texture_rect:
		posicion_original = texture_rect.position
		tamano_original = texture_rect.size
		print("TextureRect encontrado")
	else:
		print("ERROR: No se encontró TextureRect")
	
	# Reproducir sonido
	if audio_player and audio_player.stream != null:
		audio_player.play()
		print("Audio reproduciendo")
	
	# Iniciar timer automático sin depender del nodo Timer
	print("Screamer durará: ", duracion, " segundos")

func _process(delta: float) -> void:
	# Si ya está desapareciendo, no hacer nada más
	if ya_desapareciendo:
		return
	
	# Contar el tiempo transcurrido
	tiempo_transcurrido += delta
	
	# Verificar si ya pasó el tiempo de duración
	if tiempo_transcurrido >= duracion:
		print("=== SCREAMER TERMINADO ===")
		desaparecer()
		return
	
	# Aplicar efectos visuales
	if not texture_rect:
		return
	
	tiempo += delta
	
	# Aplicar el tipo de movimiento seleccionado
	match tipo_movimiento:
		"shake":
			aplicar_shake()
		"zoom":
			aplicar_zoom()
		"glitch":
			aplicar_glitch()
		"combo":
			aplicar_combo()
		_:
			aplicar_shake()

func aplicar_shake() -> void:
	# Temblor errático cada vez más intenso
	var progreso = tiempo_transcurrido / duracion
	var intensidad_actual = intensidad * (1.0 + progreso * 2.0)
	
	var offset_x = randf_range(-20, 20) * intensidad_actual
	var offset_y = randf_range(-20, 20) * intensidad_actual
	
	texture_rect.position = posicion_original + Vector2(offset_x, offset_y)
	texture_rect.rotation = randf_range(-0.1, 0.1) * intensidad_actual

func aplicar_zoom() -> void:
	var progreso = tiempo_transcurrido / duracion
	var zoom_base = 1.0 + progreso * 0.5
	var pulso = sin(tiempo * 15.0) * 0.1
	var escala_final = zoom_base + pulso
	
	texture_rect.scale = Vector2.ONE * escala_final * intensidad
	var offset = (tamano_original * escala_final - tamano_original) / 2.0
	texture_rect.position = posicion_original - offset

func aplicar_glitch() -> void:
	if randf() < 0.3:
		var offset_x = randf_range(-100, 100) * intensidad
		var offset_y = randf_range(-100, 100) * intensidad
		texture_rect.position = posicion_original + Vector2(offset_x, offset_y)
		
		var escala_x = randf_range(0.8, 1.3) * intensidad
		var escala_y = randf_range(0.8, 1.3) * intensidad
		texture_rect.scale = Vector2(escala_x, escala_y)
		texture_rect.rotation = randf_range(-0.2, 0.2)
	else:
		texture_rect.position = lerp(texture_rect.position, posicion_original, 0.3)
		texture_rect.scale = lerp(texture_rect.scale, Vector2.ONE, 0.3)
		texture_rect.rotation = lerp(texture_rect.rotation, 0.0, 0.3)

func aplicar_combo() -> void:
	var progreso = tiempo_transcurrido / duracion
	var shake_x = randf_range(-15, 15) * intensidad
	var shake_y = randf_range(-15, 15) * intensidad
	var zoom = 1.0 + progreso * 0.3
	
	if randf() < 0.15:
		shake_x *= 3
		shake_y *= 3
		zoom *= randf_range(0.9, 1.2)
	
	texture_rect.position = posicion_original + Vector2(shake_x, shake_y)
	texture_rect.scale = Vector2.ONE * zoom * intensidad
	texture_rect.rotation = sin(tiempo * 10.0) * 0.05 * intensidad

func desaparecer() -> void:
	# Marcar que ya está desapareciendo para evitar múltiples llamadas
	ya_desapareciendo = true
	
	# Detener el _process
	set_process(false)
	
	print("Eliminando screamer AHORA...")
	
	# ELIMINACIÓN INMEDIATA SIN FADE (para debug)
	queue_free()
