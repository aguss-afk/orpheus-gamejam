extends Node3D
# Fantasma que aparece brevemente después de completar una fase

@export var duracion_aparicion: float = 2.0
@export var sonido_aparicion: AudioStream

@onready var mesh = $MeshInstance3D if has_node("MeshInstance3D") else null
@onready var audio = $AudioStreamPlayer3D if has_node("AudioStreamPlayer3D") else null
@onready var luz = $OmniLight3D if has_node("OmniLight3D") else null
@onready var particulas = $GPUParticles3D if has_node("GPUParticles3D") else null

var player = null

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	
	# Hacer que mire al jugador
	if player:
		look_at(player.global_position, Vector3.UP)
	
	# Configurar luz fantasmal
	if luz:
		luz.light_color = Color(0.6, 0.8, 1.0)  # Azul pálido
		luz.light_energy = 3.0
		luz.omni_range = 8.0
	
	# Activar partículas
	if particulas:
		particulas.emitting = true
	
	# Reproducir sonido
	if audio and sonido_aparicion:
		audio.stream = sonido_aparicion
		audio.play()
	
	# Aparecer con efecto
	aparecer()

func aparecer() -> void:
	# Empezar invisible
	if mesh:
		var material = mesh.get_active_material(0)
		if material:
			material = material.duplicate()
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mesh.set_surface_override_material(0, material)
			material.albedo_color.a = 0.0
			
			# Fade in
			var tween = create_tween()
			tween.tween_property(material, "albedo_color:a", 0.7, 0.5)
			await tween.finished
	
	# Efecto de flotación y parpadeo
	var tiempo_restante = duracion_aparicion - 0.5
	var tiempo_transcurrido = 0.0
	
	while tiempo_transcurrido < tiempo_restante:
		await get_tree().process_frame
		tiempo_transcurrido += get_process_delta_time()
		
		# Flotación
		if mesh:
			var offset_y = sin(tiempo_transcurrido * 3.0) * 0.15
			mesh.position.y = offset_y
		
		# Parpadeo de luz
		if luz:
			luz.light_energy = 3.0 + sin(tiempo_transcurrido * 5.0) * 1.0
	
	# Desaparecer
	desaparecer()

func desaparecer() -> void:
	# Fade out
	if mesh:
		var material = mesh.get_active_material(0)
		if material:
			var tween = create_tween()
			tween.tween_property(material, "albedo_color:a", 0.0, 0.5)
			await tween.finished
	
	queue_free()
