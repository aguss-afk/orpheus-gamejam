extends StaticBody3D

@export var es_falsa: bool = false
@export var mensaje_pista: String = "El barro está deformado... parece real."

# Referencias
@onready var mesh_instance = $MeshInstance3D
var material: StandardMaterial3D
var player_ref = null

# Estados
var siendo_iluminada: bool = false
var tiempo_iluminada: float = 0.0
var efecto_activado: bool = false
var ya_interactuada: bool = false

# Parámetros de efectos
const TIEMPO_ACTIVACION = 1.5  # Segundos para que aparezca el efecto
var posicion_original: Vector3
var tiempo_vibracion: float = 0.0

# Intensidades de vibración según vidas del jugador
var intensidad_vibracion: float = 0.0

func _ready() -> void:
	# Añadir este nodo al grupo para que la linterna lo detecte
	add_to_group("huellas")
	
	# Guardar posición original
	posicion_original = position
	
	# Configurar material con emisión
	if mesh_instance:
		# Crear un material nuevo siempre para evitar conflictos
		material = StandardMaterial3D.new()
		
		# Copiar textura del material anterior si existe
		var material_anterior = mesh_instance.get_surface_override_material(0)
		if material_anterior and material_anterior is StandardMaterial3D:
			material.albedo_texture = material_anterior.albedo_texture
			material.albedo_color = material_anterior.albedo_color
		
		# Configurar propiedades del material
		material.emission_enabled = true
		material.emission = Color(0, 0, 0)  # Negro inicial
		material.emission_energy_multiplier = 0.0
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
		# Aplicar el material
		mesh_instance.set_surface_override_material(0, material)
		
		print("Material configurado en huella: ", name)
	else:
		print("ERROR: No se encontró MeshInstance3D en huella: ", name)
	
	# Buscar al jugador
	player_ref = get_tree().get_first_node_in_group("Player")

func _process(delta: float) -> void:
	if ya_interactuada:
		return
	
	# Si está siendo iluminada, incrementar el tiempo
	if siendo_iluminada:
		tiempo_iluminada += delta
		
		# Después del tiempo de activación, mostrar el efecto
		if tiempo_iluminada >= TIEMPO_ACTIVACION and not efecto_activado:
			activar_efecto()
	else:
		# Si deja de ser iluminada, resetear progreso gradualmente
		tiempo_iluminada = max(0.0, tiempo_iluminada - delta * 2.0)
		if efecto_activado and tiempo_iluminada <= 0.0:
			desactivar_efecto()
	
	# Aplicar efectos visuales si están activos
	if efecto_activado:
		actualizar_efectos(delta)

func activar_efecto() -> void:
	efecto_activado = true
	
	# Calcular intensidad de vibración según vidas del jugador
	if player_ref:
		var vida_actual = player_ref.vida_actual
		if vida_actual <= 1:
			intensidad_vibracion = 0.15  # Muy intensa
		elif vida_actual <= 2:
			intensidad_vibracion = 0.08
		else:
			intensidad_vibracion = 0.04
	else:
		intensidad_vibracion = 0.04

func desactivar_efecto() -> void:
	efecto_activado = false
	tiempo_vibracion = 0.0
	
	# Resetear emisión
	if material:
		material.emission_energy_multiplier = 0.0
	
	# Volver a posición original
	position = posicion_original

func actualizar_efectos(delta: float) -> void:
	tiempo_vibracion += delta
	
	if es_falsa:
		# Huella FALSA: Vibración errática + emisión roja parpadeante
		var vibracion_intensa = intensidad_vibracion * 2.0
		
		# Vibración caótica (usa múltiples frecuencias)
		var offset_x = sin(tiempo_vibracion * 15.0) * vibracion_intensa
		var offset_y = cos(tiempo_vibracion * 20.0) * vibracion_intensa * 0.5
		var offset_z = sin(tiempo_vibracion * 18.0) * vibracion_intensa
		
		position = posicion_original + Vector3(offset_x, offset_y, offset_z)
		
		# Emisión roja parpadeante agresiva
		if material:
			var parpadeo = abs(sin(tiempo_vibracion * 8.0))
			material.emission = Color(1.0, 0.1, 0.1)  # Rojo
			material.emission_energy_multiplier = 2.0 + parpadeo * 3.0
	else:
		# Huella REAL: Brillo suave + vibración leve
		
		# Vibración suave y constante
		var offset_y = sin(tiempo_vibracion * 3.0) * intensidad_vibracion * 0.3
		position = posicion_original + Vector3(0, offset_y, 0)
		
		# Emisión verde/azul suave y constante
		if material:
			var pulso = (sin(tiempo_vibracion * 2.0) + 1.0) / 2.0  # 0 a 1
			material.emission = Color(0.2, 0.8, 1.0)  # Azul cyan
			material.emission_energy_multiplier = 1.5 + pulso * 1.0

func notificar_iluminacion(iluminada: bool) -> void:
	siendo_iluminada = iluminada
	
	# Debug para verificar que funciona
	if iluminada:
		print("Huella ", name, " siendo iluminada. Es falsa: ", es_falsa)
	else:
		print("Huella ", name, " dejó de ser iluminada")

func interact() -> void:
	if ya_interactuada:
		return
	
	ya_interactuada = true
	
	if es_falsa:
		print("¡TRAMPA! El jugador recibe daño.")
		
		if player_ref:
			player_ref.recibir_dano()
			queue_free()
		else:
			print("Error: No encuentro al Player. ¿Le pusiste el Grupo 'Player'?")
	else:
		print("Pista correcta: " + mensaje_pista)
		
		var nivel = get_tree().current_scene
		
		if nivel.has_method("registrar_pista_encontrada"):
			nivel.registrar_pista_encontrada()
		else:
			print("Error: No encuentro el script 'nivel_manager' en la raíz de la escena.")
		
		# Desactivar colisión
		$CollisionShape3D.disabled = true
		
		# Cambiar a verde brillante como confirmación
		if material:
			material.emission = Color(0.0, 1.0, 0.0)
			material.emission_energy_multiplier = 3.0
		
		# Opcional: Borrar después de 2 segundos
		await get_tree().create_timer(2.0).timeout
		queue_free()
