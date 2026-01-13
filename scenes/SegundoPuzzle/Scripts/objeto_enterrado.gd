extends StaticBody3D
# Script base para objetos enterrados (diario, zapatos, cinta, espejo)

enum Objeto { DIARIO, ZAPATOS, CINTA, ESPEJO }

@export var tipo_objeto: Objeto = Objeto.DIARIO
@export var nombre_objeto: String = "Objeto"
@export var distancia_brillo_max: float = 10.0  # Distancia para brillo máximo

@onready var luz = $OmniLight3D
@onready var mesh = $MeshInstance3D
@onready var particulas = $GPUParticles3D if has_node("GPUParticles3D") else null

var manager = null
var player = null
var desenterrado: bool = false
var posicion_original: Vector3
var tiempo: float = 0.0

func _ready() -> void:
	add_to_group("objetos_enterrados")
	posicion_original = position
	player = get_tree().get_first_node_in_group("Player")
	
	# Configurar luz inicial
	if luz:
		luz.light_color = Color(1.0, 0.9, 0.3)  # Amarillo
		luz.light_energy = 1.0
		luz.omni_range = 5.0
	
	# El objeto empieza semi-enterrado
	if mesh:
		mesh.position.y = -0.3

func _process(delta: float) -> void:
	tiempo += delta
	
	if not desenterrado:
		# Efecto de flotación leve mientras está enterrado
		if mesh:
			mesh.position.y = -0.3 + sin(tiempo * 2.0) * 0.05
		
		# Ajustar brillo según distancia al jugador
		if player and luz:
			var distancia = global_position.distance_to(player.global_position)
			var intensidad = calcular_intensidad_luz(distancia)
			luz.light_energy = intensidad
			
			# Parpadeo cuando está muy cerca
			if distancia < 2.0:
				luz.light_energy *= (sin(tiempo * 10.0) * 0.3 + 1.0)
	else:
		# Rotación cuando está desenterrado
		if mesh:
			mesh.rotate_y(delta * 2.0)
			# Flotación más pronunciada
			mesh.position.y = sin(tiempo * 3.0) * 0.2

func calcular_intensidad_luz(distancia: float) -> float:
	# Mientras más cerca, más brilla
	if distancia > distancia_brillo_max:
		return 1.0  # Brillo base
	
	var factor = 1.0 - (distancia / distancia_brillo_max)
	return 1.0 + factor * 4.0  # De 1.0 a 5.0

func interact() -> void:
	if not desenterrado:
		# Primera interacción: Desenterrar
		desenterrar()
	else:
		# Segunda interacción: Recoger
		recoger()

func desenterrar() -> void:
	desenterrado = true
	print("Desenterrando ", nombre_objeto, "...")
	
	# Animación de desenterrar
	var tween = create_tween()
	tween.set_parallel(true)
	
	if mesh:
		tween.tween_property(mesh, "position:y", 0.5, 0.8)
	
	if luz:
		tween.tween_property(luz, "light_energy", 6.0, 0.8)
	
	# Activar partículas si las hay
	if particulas:
		particulas.emitting = true
	
	await tween.finished
	
	print("¡Es un(a) ", nombre_objeto, "! ¿Recogerlo? (E)")

func recoger() -> void:
	if not manager:
		print("ERROR: No hay manager asignado")
		return
	
	print("Recogiendo ", nombre_objeto)
	
	# Notificar al manager
	manager.objeto_recolectado(tipo_objeto)
	
	# Animación de recolección
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3.ZERO, 0.5)
	tween.tween_property(self, "position:y", position.y + 3.0, 0.5)
	
	await tween.finished
	queue_free()
