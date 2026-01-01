extends CharacterBody3D

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

@export var dungeon_generator: Node

const SPEED = 3.5
const SENSITIVITY = 0.002

const BOB_FREQ = 2.0
const BOB_AMP = 0.1
var t_bob = 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
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
