@tool
extends Node3D

func remove_wall_front():
	if has_node("wall_front"):
		var wall = $wall_front
		if Engine.is_editor_hint():
			wall.free()
		else:
			wall.queue_free()

func remove_wall_back():
	if has_node("wall_back"):
		var wall = $wall_back
		if Engine.is_editor_hint():
			wall.free()
		else:
			wall.queue_free()

func remove_wall_right():
	if has_node("wall_right"):
		var wall = $wall_right
		if Engine.is_editor_hint():
			wall.free()
		else:
			wall.queue_free()

func remove_wall_left():
	if has_node("wall_left"):
		var wall = $wall_left
		if Engine.is_editor_hint():
			wall.free()
		else:
			wall.queue_free()
