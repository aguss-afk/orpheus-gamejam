@tool
extends Node3D

@export var grid_map_path : NodePath = NodePath("../GridMap")
@onready var grid_map : GridMap = get_node(grid_map_path) if (grid_map_path != null and has_node(grid_map_path)) else null


var dun_cell_scene : PackedScene = preload("res://scenes/dun_cell.tscn")
const DIRS := [
	{ "name": "front", "vec": Vector3i.FORWARD },
	{ "name": "back",  "vec": Vector3i.BACK },
	{ "name": "left",  "vec": Vector3i.LEFT },
	{ "name": "right", "vec": Vector3i.RIGHT }
]

func _ready():
	if Engine.is_editor_hint():
		return
	
	if grid_map and grid_map.get_used_cells().size() > 0:
		create_dungeon()

func handle_none(cell : Node3D, dir : String) -> void:
	pass

func handle_wall(cell: Node3D, dir: String, a:int, b:int) -> void:
	if a == 0 and b == 0:
		if cell.has_method("remove_wall_" + dir):
			cell.call("remove_wall_" + dir)
	elif a == 1 and b == 1:
		if cell.has_method("remove_wall_" + dir):
			cell.call("remove_wall_" + dir)
	elif a == 2 or b == 2:
		if cell.has_method("remove_wall_" + dir):
			cell.call("remove_wall_" + dir)

func create_dungeon() -> void:
	for c in get_children():
		c.queue_free()
	await get_tree().process_frame  

	if grid_map == null:
		if grid_map_path != null and has_node(grid_map_path):
			grid_map = get_node(grid_map_path)
		else:
			push_error("dun_mesh.gd: grid_map not found; set grid_map_path in the inspector.")
			return

	var t : int = 0
	for cell in grid_map.get_used_cells():
		var cell_index : int = grid_map.get_cell_item(cell)
		if cell_index < 0 or cell_index >= 3:
			continue
			
		var dun_cell : Node3D = dun_cell_scene.instantiate()
		dun_cell.position = (Vector3(cell) + Vector3(0.5, 1, 0.5)) * grid_map.cell_size
		add_child(dun_cell)
		
		t += 1

		for d in DIRS:
			var cell_n : Vector3i = cell + d.vec
			var cell_n_index : int = grid_map.get_cell_item(cell_n)

			if cell_n_index == -1 or cell_n_index == 3:
				handle_none(dun_cell, d.name)
			else:
				handle_wall(dun_cell, d.name, cell_index, cell_n_index)
		
		if Engine.is_editor_hint():
			var root = get_tree().edited_scene_root
			pass

		if t % 10 == 9:
			await get_tree().create_timer(0).timeout
