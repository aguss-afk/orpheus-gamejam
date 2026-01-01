extends StaticBody3D

@export var dungeon_generator: Node
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if dungeon_generator:
		if dungeon_generator.has_signal("spawn_point_ready"):
			if not dungeon_generator.spawn_point_ready.is_connected(_on_spawn_point_ready):
				dungeon_generator.spawn_point_ready.connect(_on_spawn_point_ready)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _on_spawn_point_ready(spawn_pos: Vector3) -> void:
	position = Vector3(spawn_pos.x, spawn_pos.y - 1, spawn_pos.z - 1)
