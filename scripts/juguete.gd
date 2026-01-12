extends StaticBody3D
# Este script va en el juguete (FantasmaFinal o como lo renombres)

@export var fantasma_scene: PackedScene  # Arrastra aquí la escena del fantasma
@export var posicion_aparicion_fantasma: Vector3 = Vector3(0, 2, -5)  # Donde aparecerá el fantasma
@export var rotacion_constante: bool = true  # Si el juguete gira flotando
@export var velocidad_rotacion: float = 1.0
@export var velocidad_flotacion: float = 1.0
@export var amplitud_flotacion: float = 0.3

var tiempo: float = 0.0
var posicion_inicial: Vector3
var ya_interactuado: bool = false

func _ready() -> void:
	posicion_inicial = position
	print("Juguete configurado. Esperando interacción...")

func _process(delta: float) -> void:
	if ya_interactuado:
		return
	
	tiempo += delta
	
	# Efecto de flotación
	var nueva_y = posicion_inicial.y + sin(tiempo * velocidad_flotacion) * amplitud_flotacion
	position = Vector3(posicion_inicial.x, nueva_y, posicion_inicial.z)
	
	# Rotación constante
	if rotacion_constante:
		rotate_y(velocidad_rotacion * delta)

func interact() -> void:
	if ya_interactuado:
		return
	
	ya_interactuado = true
	print("¡El jugador encontró el juguete!")
	
	# 1. Curar al jugador (restaurar vidas)
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_method("curar_completamente"):
		player.curar_completamente()
	
	# 2. Invocar al fantasma
	if fantasma_scene:
		invocar_fantasma()
	else:
		print("ERROR: No se asignó la escena del fantasma en el Inspector")
	
	# 3. Desaparecer el juguete con efecto
	desaparecer_con_efecto()

func invocar_fantasma() -> void:
	var fantasma = fantasma_scene.instantiate()
	
	# Posicionar el fantasma
	fantasma.global_position = global_position + posicion_aparicion_fantasma
	
	# Añadir a la escena
	get_tree().current_scene.add_child(fantasma)
	
	print("¡El fantasma ha aparecido!")

func desaparecer_con_efecto() -> void:
	# Animación de desaparición
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Hacer que el juguete se eleve y se haga transparente
	tween.tween_property(self, "position:y", position.y + 3.0, 1.5)
	tween.tween_property(self, "scale", Vector3.ZERO, 1.5)
	
	# Después de la animación, borrar
	await tween.finished
	queue_free()
