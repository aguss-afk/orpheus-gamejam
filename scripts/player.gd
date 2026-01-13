extends CharacterBody3D

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var ui_corazones = get_node("/root/" + get_tree().current_scene.name + "/UI/ContenedorCorazones")

@export var dungeon_generator: Node

var SPEED = 3.5
const SENSITIVITY = 0.002
var running = false
var BOB_FREQ = 2.0
var BOB_AMP = 0.1
var t_bob = 0.0

var vida_maxima: int = 5
var vida_actual: int = 5
var screamer_scene = preload("res://scenes/screamer.tscn")


func _ready() -> void:
	add_to_group("Player")
	# Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if Engine.is_editor_hint():
		return
	
	if dungeon_generator:
		
		if dungeon_generator.has_signal("spawn_point_ready"):
			if not dungeon_generator.spawn_point_ready.is_connected(_on_spawn_point_ready):
				dungeon_generator.spawn_point_ready.connect(_on_spawn_point_ready)

func _on_spawn_point_ready(spawn_pos: Vector3) -> void:
	position = spawn_pos

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
			velocity += get_gravity() * delta
	

	var input_dir := Input.get_vector("walk_left", "walk_right", "walk_forward", "walk_backward")
	var direction := (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if Input.is_action_just_pressed("run"):
		running = !running
	if running:
		SPEED = 6
		BOB_AMP = 0.1
		BOB_FREQ = 2
	else:
		SPEED = 3.5
		BOB_FREQ = 1.5
		BOB_AMP = 0.1
	if is_on_floor():
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = lerp(velocity.x, direction.x * SPEED, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * SPEED, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * SPEED, delta * 2.0)
		velocity.z = lerp(velocity.z, direction.z * SPEED, delta * 2.0)
		
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	move_and_slide()

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	return pos
	
func recibir_dano():
	# 1. Restar vida
	vida_actual -= 1
	print("¡Auch! Vida restante: ", vida_actual)
	
	# 2. Actualizar UI (Ocultar un corazón)
	# Buscamos el último corazón visible y lo ocultamos
	if vida_actual >= 0 and vida_actual < ui_corazones.get_child_count():
		var corazon_a_borrar = ui_corazones.get_child(vida_actual)
		corazon_a_borrar.visible = false
	
	# 3. Lanzar el Screamer (Susto visual)
	var susto = screamer_scene.instantiate()
	if vida_actual <= 1:
		susto.intensidad = 2.0  # MUY INTENSO
		susto.tipo_movimiento = "combo"
	elif vida_actual <= 2:
		susto.intensidad = 1.5  # Intenso
		susto.tipo_movimiento = "shake"
	else:
		susto.intensidad = 1.0  # Normal
		susto.tipo_movimiento = "shake"
	get_tree().root.add_child(susto)
	
	# 4. Verificar Muerte
	if vida_actual <= 0:
		morir()

func morir():
	print("Game Over")
	# Aquí sí reiniciamos el nivel porque se acabaron los corazones
	get_tree().reload_current_scene()
func curar_completamente():
	# Restaurar todas las vidas
	vida_actual = vida_maxima
	print("¡Vida restaurada! Corazones: ", vida_actual, "/", vida_maxima)
	
	# Mostrar todos los corazones de nuevo
	for i in range(ui_corazones.get_child_count()):
		var corazon = ui_corazones.get_child(i)
		corazon.visible = true
