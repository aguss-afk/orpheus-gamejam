extends Node3D
# Manager principal del puzzle de la Adolescente

# Escenas de objetos
@export var diario_scene: PackedScene
@export var zapatos_scene: PackedScene
@export var cinta_scene: PackedScene
@export var espejo_scene: PackedScene

# Escenas de UI y efectos
@export var ui_secuencia_scene: PackedScene  # Para mostrar el orden
@export var fantasma_aparicion_scene: PackedScene  # Fantasma que aparece brevemente
@export var screamer_scene: PackedScene  # Screamer propio de este nivel

# Configuración del mapa
@export var area_generacion: Vector3 = Vector3(40, 0, 40)
@export var altura_objetos: float = -0.5  # Enterrados
@export var distancia_minima_objetos: float = 3.0

# Referencias
var player: CharacterBody3D
var arbol_central: Node3D
var posiciones_arboles: Array = []

# Sistema de fases
enum Objeto { DIARIO, ZAPATOS, CINTA, ESPEJO }
var secuencia_actual: Array[Objeto] = []
var objetos_recolectados: Array[Objeto] = []
var fase_actual: int = 1
var objetos_instanciados: Array = []

# Estados
var esperando_recoleccion: bool = false
var mostrando_fantasma: bool = false

# Constantes
const MAX_FASES = 4
const TIEMPO_ESPERA_INICIAL = 5.0
const TIEMPO_FANTASMA = 2.0
const TIEMPO_ESPERA_SIGUIENTE_FASE = 4.0

func _ready() -> void:
	print("=== PUZZLE DE LA ADOLESCENTE INICIADO ===")
	
	# Buscar referencias
	player = get_tree().get_first_node_in_group("Player")
	arbol_central = get_node_or_null("ArbolCentral")
	
	# Recopilar posiciones de árboles
	await get_tree().create_timer(0.5).timeout
	recopilar_arboles()
	
	# Esperar tiempo inicial y comenzar
	await get_tree().create_timer(TIEMPO_ESPERA_INICIAL).timeout
	iniciar_fase_1()

func recopilar_arboles() -> void:
	posiciones_arboles.clear()
	var arboles = get_tree().get_nodes_in_group("arboles")
	for arbol in arboles:
		if arbol is Node3D:
			posiciones_arboles.append(arbol.global_position)
	print("Árboles detectados: ", posiciones_arboles.size())

func iniciar_fase_1() -> void:
	fase_actual = 1
	secuencia_actual = [Objeto.DIARIO]
	print("\n=== FASE 1: Encuentra el DIARIO ===")
	mostrar_secuencia_ui()
	await get_tree().create_timer(4.0).timeout  # Esperar a que desaparezca el UI
	generar_objetos()

func generar_objetos() -> void:
	# Limpiar objetos anteriores
	limpiar_objetos()
	
	esperando_recoleccion = true
	
	# Generar cada objeto de la secuencia actual
	for objeto_tipo in secuencia_actual:
		var posicion = obtener_posicion_valida()
		instanciar_objeto(objeto_tipo, posicion)
	
	print("Objetos generados: ", secuencia_actual.size())

func obtener_posicion_valida() -> Vector3:
	var intentos = 0
	var posicion_valida = false
	var nueva_posicion = Vector3.ZERO
	
	while not posicion_valida and intentos < 100:
		intentos += 1
		
		# Posición aleatoria
		nueva_posicion = Vector3(
			randf_range(-area_generacion.x / 2, area_generacion.x / 2),
			altura_objetos,
			randf_range(-area_generacion.z / 2, area_generacion.z / 2)
		)
		
		posicion_valida = true
		
		# Verificar distancia con árboles
		for arbol_pos in posiciones_arboles:
			if nueva_posicion.distance_to(arbol_pos) < 2.5:
				posicion_valida = false
				break
		
		# Verificar distancia con otros objetos ya generados
		if posicion_valida:
			for obj in objetos_instanciados:
				if obj and is_instance_valid(obj):
					if nueva_posicion.distance_to(obj.global_position) < distancia_minima_objetos:
						posicion_valida = false
						break
	
	return nueva_posicion

func instanciar_objeto(tipo: Objeto, posicion: Vector3) -> void:
	var escena = obtener_escena_objeto(tipo)
	if not escena:
		print("ERROR: No se encontró escena para objeto tipo ", tipo)
		return
	
	var objeto = escena.instantiate()
	objeto.global_position = global_position + posicion
	objeto.tipo_objeto = tipo
	objeto.manager = self
	
	add_child(objeto)
	objetos_instanciados.append(objeto)

func obtener_escena_objeto(tipo: Objeto) -> PackedScene:
	match tipo:
		Objeto.DIARIO: return diario_scene
		Objeto.ZAPATOS: return zapatos_scene
		Objeto.CINTA: return cinta_scene
		Objeto.ESPEJO: return espejo_scene
	return null

func objeto_recolectado(tipo: Objeto) -> void:
	if not esperando_recoleccion:
		return
	
	print("Objeto recolectado: ", Objeto.keys()[tipo])
	
	# Verificar si es el correcto según el orden
	var indice_esperado = objetos_recolectados.size()
	
	if indice_esperado >= secuencia_actual.size():
		print("ERROR: Ya se recolectaron todos los objetos de esta fase")
		return
	
	var objeto_esperado = secuencia_actual[indice_esperado]
	
	if tipo == objeto_esperado:
		# ¡CORRECTO!
		objetos_recolectados.append(tipo)
		print("✓ Correcto! Progreso: ", objetos_recolectados.size(), "/", secuencia_actual.size())
		
		# Verificar si completó la fase
		if objetos_recolectados.size() >= secuencia_actual.size():
			fase_completada()
	else:
		# ¡ERROR!
		print("✗ Incorrecto! Esperaba ", Objeto.keys()[objeto_esperado], " pero recogiste ", Objeto.keys()[tipo])
		objeto_incorrecto()

func fase_completada() -> void:
	esperando_recoleccion = false
	print("\n¡FASE ", fase_actual, " COMPLETADA!")
	
	# Limpiar objetos
	limpiar_objetos()
	
	# Mostrar fantasma
	mostrar_fantasma_breve()
	await get_tree().create_timer(TIEMPO_FANTASMA + TIEMPO_ESPERA_SIGUIENTE_FASE).timeout
	
	# Avanzar a siguiente fase
	if fase_actual < MAX_FASES:
		avanzar_fase()
	else:
		puzzle_completado()

func avanzar_fase() -> void:
	fase_actual += 1
	objetos_recolectados.clear()
	
	# Construir nueva secuencia
	match fase_actual:
		2:
			secuencia_actual = [Objeto.DIARIO, Objeto.ZAPATOS]
		3:
			secuencia_actual = [Objeto.DIARIO, Objeto.CINTA, Objeto.ZAPATOS]
		4:
			secuencia_actual = [Objeto.DIARIO, Objeto.ZAPATOS, Objeto.CINTA, Objeto.ESPEJO]
	
	print("\n=== FASE ", fase_actual, " ===")
	print("Secuencia: ", obtener_nombres_secuencia())
	
	mostrar_secuencia_ui()
	await get_tree().create_timer(4.0).timeout  # Esperar a que desaparezca el UI
	generar_objetos()

func obtener_nombres_secuencia() -> Array:
	var nombres = []
	for obj in secuencia_actual:
		nombres.append(Objeto.keys()[obj])
	return nombres

func objeto_incorrecto() -> void:
	esperando_recoleccion = false
	
	# Mostrar screamer
	if screamer_scene:
		var screamer = screamer_scene.instantiate()
		get_tree().root.add_child(screamer)
	else:
		print("ERROR: No se asignó escena de screamer")
	
	# Reducir vida del jugador
	if player and player.has_method("recibir_dano_sin_screamer"):
		# Si el player tiene este método, úsalo para no duplicar el screamer
		player.recibir_dano_sin_screamer()
	elif player and player.has_method("recibir_dano"):
		# Si no, usa el método normal pero el screamer ya se mostró arriba
		player.vida_actual -= 1
		if player.vida_actual >= 0 and player.vida_actual < player.ui_corazones.get_child_count():
			var corazon_a_borrar = player.ui_corazones.get_child(player.vida_actual)
			corazon_a_borrar.visible = false
		if player.vida_actual <= 0:
			player.morir()
	
	# Esperar a que termine el screamer
	await get_tree().create_timer(2.0).timeout
	
	# Reiniciar fase
	objetos_recolectados.clear()
	print("\nReiniciando fase ", fase_actual, "...")
	mostrar_secuencia_ui()
	await get_tree().create_timer(4.0).timeout  # Esperar a que desaparezca el UI
	generar_objetos()

func mostrar_secuencia_ui() -> void:
	if not ui_secuencia_scene:
		print("Mostrando secuencia en consola: ", obtener_nombres_secuencia())
		return
	
	# INSTANCIAR Y CONFIGURAR INMEDIATAMENTE (sin awaits)
	var ui = ui_secuencia_scene.instantiate()
	get_tree().root.add_child(ui)
	ui.configurar_secuencia(secuencia_actual)
	# El UI se eliminará solo después de 3 segundos

func mostrar_fantasma_breve() -> void:
	if not fantasma_aparicion_scene:
		print("Fantasma aparece brevemente...")
		return
	
	mostrando_fantasma = true
	var fantasma = fantasma_aparicion_scene.instantiate()
	
	# Posicionar frente al jugador
	if player:
		var pos_frente = player.global_position + player.global_transform.basis.z * -3.0
		pos_frente.y = player.global_position.y
		fantasma.global_position = pos_frente
	
	get_tree().current_scene.add_child(fantasma)
	mostrando_fantasma = false

func puzzle_completado() -> void:
	print("\n=== ¡PUZZLE COMPLETADO! ===")
	esperando_recoleccion = false
	
	# Liberar al fantasma (animación en el árbol)
	if arbol_central:
		liberar_fantasma()

func liberar_fantasma() -> void:
	print("El espíritu de la adolescente ha sido liberado...")
	# Aquí puedes añadir efectos visuales, animaciones, etc.
	await get_tree().create_timer(3.0).timeout
	
	# Cambiar de nivel o mostrar victoria
	get_tree().reload_current_scene()

func limpiar_objetos() -> void:
	for obj in objetos_instanciados:
		if obj and is_instance_valid(obj):
			obj.queue_free()
	objetos_instanciados.clear()
