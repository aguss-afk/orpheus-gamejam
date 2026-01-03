extends StaticBody3D
@export var dungeon_generator : Node3D
var flashlight

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if dungeon_generator:
		if dungeon_generator.has_signal("spawn_point_ready"):
			if not dungeon_generator.spawn_point_ready.is_connected(_on_spawn_point_ready):
				dungeon_generator.spawn_point_ready.connect(_on_spawn_point_ready)
	flashlight = get_node("/root/" + get_tree().current_scene.name + "/Player/Head/Camera3D/Node3D/SpotLight3D")
func _on_spawn_point_ready(spawn_pos: Vector3) -> void:
	position = Vector3(spawn_pos.x, spawn_pos.y - 0.17, spawn_pos.z - 1)
	
func interact():
	flashlight.picked_up = true
	queue_free()
