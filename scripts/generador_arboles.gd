extends Node3D
# Coloca este script en un nodo Node3D llamado "GeneradorArboles"

# AHORA PUEDES AÑADIR MÚLTIPLES TIPOS DE ÁRBOLES
@export var arboles_scenes: Array[PackedScene] = []  # Arrastra aquí TODOS tus árboles
@export var cantidad_arboles: int = 20
@export var area_generacion: Vector3 = Vector3(40, 0, 40)  # Área más grande para árboles
@export var altura_suelo: float = 0.0
@export var distancia_minima_entre_arboles: float = 5.0
@export var radio_colision_arbol: float = 2.0  # Radio para verificar colisiones

# Opciones de variedad
@export var escala_minima: float = 0.8
@export var escala_maxima: float = 1.3
@export var rotacion_aleatoria: bool = true

var arboles_generados: Array = []
var posiciones_ocupadas: Array = []  # Incluirá árboles Y huellas

func _ready() -> void:
	# Esperar a que todo esté listo
	await get_tree().create_timer(0.3).timeout
	
	# Recopilar posiciones de objetos existentes (huellas, etc)
	recopilar_posiciones_existentes()
	
	# Generar árboles
	generar_arboles()

func recopilar_posiciones_existentes() -> void:
	posiciones_ocupadas.clear()
	
	# Agregar posiciones de huellas
	var huellas = get_tree().get_nodes_in_group("huellas")
	for huella in huellas:
		if huella is Node3D:
			posiciones_ocupadas.append({
				"posicion": huella.global_position,
				"radio": 1.5  # Radio de seguridad alrededor de huellas
			})
	
	# Agregar posición del jugador
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		posiciones_ocupadas.append({
			"posicion": player.global_position,
			"radio": 3.0  # No spawear árboles cerca del jugador
		})
	
	print("Posiciones ocupadas detectadas: ", posiciones_ocupadas.size())

func generar_arboles() -> void:
	if arboles_scenes.size() == 0:
		print("ERROR: No se asignaron escenas de árboles en el GeneradorArboles")
		print("Arrastra tus 3 modelos de árboles al array 'Arboles Scenes' en el Inspector")
		return
	
	print("Tipos de árboles disponibles: ", arboles_scenes.size())
	
	var arboles_creados = 0
	var intentos_totales = 0
	var max_intentos = cantidad_arboles * 100  # Evitar loops infinitos
	
	while arboles_creados < cantidad_arboles and intentos_totales < max_intentos:
		intentos_totales += 1
		
		var nueva_posicion = generar_posicion_aleatoria()
		
		if es_posicion_valida(nueva_posicion):
			crear_arbol(nueva_posicion)
			arboles_creados += 1
	
	print("Generados ", arboles_creados, " árboles en ", intentos_totales, " intentos")

func generar_posicion_aleatoria() -> Vector3:
	return Vector3(
		randf_range(-area_generacion.x / 2, area_generacion.x / 2),
		altura_suelo,
		randf_range(-area_generacion.z / 2, area_generacion.z / 2)
	)

func es_posicion_valida(pos: Vector3) -> bool:
	var pos_global = global_position + pos
	
	# Verificar distancia con otros árboles ya generados
	for arbol_pos in arboles_generados:
		if pos_global.distance_to(arbol_pos) < distancia_minima_entre_arboles:
			return false
	
	# Verificar distancia con objetos existentes (huellas, jugador, etc)
	for ocupado in posiciones_ocupadas:
		var distancia = pos_global.distance_to(ocupado.posicion)
		var radio_minimo = radio_colision_arbol + ocupado.radio
		
		if distancia < radio_minimo:
			return false
	
	return true

func crear_arbol(pos_local: Vector3) -> void:
	# Elegir un tipo de árbol aleatorio
	var arbol_scene = arboles_scenes[randi() % arboles_scenes.size()]
	var arbol = arbol_scene.instantiate()
	
	arbol.position = global_position + pos_local
	
	# Rotación aleatoria para variedad
	if rotacion_aleatoria:
		arbol.rotation.y = randf_range(0, TAU)
	
	# Escala aleatoria para más variedad visual
	var escala = randf_range(escala_minima, escala_maxima)
	arbol.scale = Vector3(escala, escala, escala)
	
	# Añadir al grupo de árboles (importante para detección)
	arbol.add_to_group("arboles")
	
	# Añadir al nivel
	get_tree().current_scene.add_child(arbol)
	
	# Registrar posición
	arboles_generados.append(arbol.global_position)
	posiciones_ocupadas.append({
		"posicion": arbol.global_position,
		"radio": radio_colision_arbol * escala  # El radio escala con el tamaño
	})

func limpiar_arboles() -> void:
	# Útil para regenerar
	for arbol in get_tree().get_nodes_in_group("arboles"):
		arbol.queue_free()
	arboles_generados.clear()
	posiciones_ocupadas.clear()

# Función útil para regenerar árboles en runtime (opcional)
func regenerar() -> void:
	limpiar_arboles()
	await get_tree().create_timer(0.1).timeout
	recopilar_posiciones_existentes()
	generar_arboles()
