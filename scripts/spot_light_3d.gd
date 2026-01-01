extends SpotLight3D

var picked_up : bool = false
var picked_up_first_time : bool = true
func _process(delta: float) -> void:
	if !picked_up:
		visible = false
	else:
		if picked_up_first_time:
			visible = true
			picked_up_first_time = false
		if Input.is_action_just_pressed("flashlight"):
			visible = !visible
