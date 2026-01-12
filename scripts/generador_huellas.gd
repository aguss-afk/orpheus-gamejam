extends Node3D
# Coloca este script en un nodo nuevo en tu escena (ej: "GeneradorHuellas")

@export var huella_scene: PackedScene  # Arrastra aquí tu escena de huella
@export var cantidad_huellas_reales: int = 6  # Cambiado a 6
@export var cantidad_huellas_falsas: int = 10
@export var area_generacion: Vector3 = Vector3(20, 0, 20)  # Tamaño del área
@export var altura_suelo: float = 0.5  # Altura donde aparecen (justo sobre el piso)
@export var distancia_minima: float = 2.0  # Distancia mínima entre huellas
@export var distancia_minima_a_arboles: float = 2.5  # Distancia a árboles

var huellas_generadas: Array = []
var posiciones_arboles: Array = []

func _ready() -> void:
	# Esperar a que todo esté listo (especialmente si hay generador de árboles)
	await get_tree().create_timer(0.5).timeout
	
	# Recopilar posiciones de árboles
	recopilar_arboles()
	
	generar_huellas()

func recopilar_arboles() -> void:
	posiciones_arboles.clear()
	
	# Buscar todos los nodos marcados como árboles
	var arboles = get_tree().get_nodes_in_group("arboles")
	for arbol in arboles:
		if arbol is Node3D:
			posiciones_arboles.append(arbol.global_position)
	
	print("Árboles detectados: ", posiciones_arboles.size())

func generar_huellas() -> void:
	if not huella_scene:
		print("ERROR: No se asignó la escena de huella en el GeneradorHuellas")
		return
	
	# Generar huellas reales
	for i in range(cantidad_huellas_reales):
		crear_huella(false)
	
	# Generar huellas falsas
	for i in range(cantidad_huellas_falsas):
		crear_huella(true)
	
	print("Generadas ", cantidad_huellas_reales + cantidad_huellas_falsas, " huellas en el nivel")

func crear_huella(es_falsa: bool) -> void:
	var intentos = 0
	var posicion_valida = false
	var nueva_posicion = Vector3.ZERO
	
	# Intentar encontrar una posición válida
	while not posicion_valida and intentos < 100:  # Más intentos
		intentos += 1
		
		# Posición aleatoria dentro del área
		nueva_posicion = Vector3(
			randf_range(-area_generacion.x / 2, area_generacion.x / 2),
			altura_suelo,
			randf_range(-area_generacion.z / 2, area_generacion.z / 2)
		)
		
		posicion_valida = true
		
		# Verificar distancia con otras huellas
		for huella_pos in huellas_generadas:
			if nueva_posicion.distance_to(huella_pos) < distancia_minima:
				posicion_valida = false
				break
		
		# Verificar distancia con árboles
		if posicion_valida:
			for arbol_pos in posiciones_arboles:
				if nueva_posicion.distance_to(arbol_pos) < distancia_minima_a_arboles:
					posicion_valida = false
					break
	
	if posicion_valida:
		# Instanciar la huella
		var huella = huella_scene.instantiate()
		huella.position = global_position + nueva_posicion
		
		# Rotación aleatoria para variedad
		huella.rotation.y = randf_range(0, TAU)
		
		# Configurar si es falsa o real
		huella.es_falsa = es_falsa
		
		if not es_falsa:
			# Mensajes aleatorios para huellas reales
			var mensajes = [
				"Las marcas son profundas y claras...",
				"Esta huella parece reciente.",
				"El patrón coincide con pasos reales.",
				"Se nota el peso de algo sólido.",
				"Las grietas en el barro son naturales."
			]
			huella.mensaje_pista = mensajes[randi() % mensajes.size()]
		
		# Añadir al nivel
		get_tree().current_scene.add_child(huella)
		huellas_generadas.append(nueva_posicion)
	else:
		print("ADVERTENCIA: No se pudo colocar una huella después de ", intentos, " intentos")

func limpiar_huellas() -> void:
	# Útil si quieres regenerar el nivel
	for huella in get_tree().get_nodes_in_group("huellas"):
		huella.queue_free()
	huellas_generadas.clear()
