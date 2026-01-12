extends SpotLight3D

@export var picked_up : bool = false
var picked_up_first_time : bool = true
var ins_text
var timer := 0.0
var timer_running : bool = false
var timer_duration : float = 2.0

func start_timer() -> void:
	timer = 0.0
	timer_running = true
	ins_text.visible = true
func on_timer_finished() -> void:
	ins_text.visible = false
	
func _ready() -> void:
	ins_text = get_node("/root/" + get_tree().current_scene.name + "/UI/Flashlight")
	ins_text.visible = false
func _process(delta: float) -> void:
	if timer_running:
		timer += delta
		if timer >= timer_duration:
			timer_running = false
			on_timer_finished()
	if !picked_up:
		visible = false
	else:
		if picked_up_first_time:
			start_timer()
			visible = true
			picked_up_first_time = false
		if Input.is_action_just_pressed("flashlight"):
			visible = !visible
