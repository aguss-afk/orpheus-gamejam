@tool
extends Node3D

@export var grid_map_path : NodePath
@export var dun_gen_path : NodePath 
@onready var grid_map : GridMap = get_node(grid_map_path)
@onready var dun_gen : Node3D = get_node(dun_gen_path)
var cube_scene : PackedScene = preload("res://scenes/objects/cube.tscn")

func _ready():
	if not Engine.is_editor_hint():
		await get_tree().process_frame
		create_cubes()
	
func create_cubes() -> void:
	if not "room_positions" in dun_gen:
		push_error("The assigned DunGen node does not have a 'room_positions' variable.")
		return

	print("Generating cubes...")
	
	# Clear existing cubes
	for c in get_children():
		c.queue_free()
	
	# Generate new ones
	for cell in dun_gen.room_positions:
		var cube: Node3D = cube_scene.instantiate()
		
		# GridMap calculation
		var offset = Vector3(0.5, 2, 0.5) * grid_map.cell_size
		var world_pos = grid_map.map_to_local(cell) # map_to_local is safer/easier
		
		# If map_to_local centers it, you might not need the extra math, 
		# but here is your original logic adapted:
		cube.position = (Vector3(cell) * grid_map.cell_size) + offset
		
		add_child(cube)
	
