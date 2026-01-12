extends RayCast3D

var int_text
var linterna: SpotLight3D
var huella_actual: Node3D = null

func _ready() -> void:
	int_text = get_node("/root/" + get_tree().current_scene.name + "/UI/Interact")
	
	# Buscar la linterna de manera más robusta
	linterna = buscar_linterna_en_escena()
	
	if linterna:
		print("✓ Linterna encontrada: ", linterna.name)
	else:
		print("✗ ERROR: No se encontró la linterna")

func buscar_linterna_en_escena() -> SpotLight3D:
	# Primero intentar buscar desde el Head
	var camera = get_parent()
	if camera:
		var head = camera.get_parent()
		if head:
			var resultado = buscar_spotlight_recursivo(head)
			if resultado:
				return resultado
	
	# Si no funciona, buscar en toda la escena
	print("Buscando linterna en toda la escena...")
	return buscar_spotlight_recursivo(get_tree().root)

func buscar_spotlight_recursivo(nodo: Node) -> SpotLight3D:
	if nodo is SpotLight3D:
		return nodo
	
	for hijo in nodo.get_children():
		var resultado = buscar_spotlight_recursivo(hijo)
		if resultado:
			return resultado
	
	return null

func _process(delta: float) -> void:
	# Sistema original de interacción con E
	if is_colliding():
		var hit = get_collider()
		if hit.has_method("interact"):
			int_text.visible = true
			
			if Input.is_action_just_pressed("interact"):
				hit.interact()
		else:
			int_text.visible = false
	else:
		int_text.visible = false
	
	# Sistema de detección de linterna
	if linterna and linterna.visible:
		# Usar el MISMO raycast que ya detecta objetos
		var huella_iluminada: Node3D = null
		
		if is_colliding():
			var hit = get_collider()
			# Si el raycast ya está apuntando a una huella
			if hit.is_in_group("huellas"):
				huella_iluminada = hit
		
		# Actualizar estado de iluminación
		if huella_iluminada != huella_actual:
			# Desactivar la anterior
			if huella_actual and huella_actual.has_method("notificar_iluminacion"):
				huella_actual.notificar_iluminacion(false)
			
			# Activar la nueva
			if huella_iluminada and huella_iluminada.has_method("notificar_iluminacion"):
				huella_iluminada.notificar_iluminacion(true)
			
			huella_actual = huella_iluminada
		elif huella_actual and huella_actual.has_method("notificar_iluminacion"):
			# Mantener activa la actual
			huella_actual.notificar_iluminacion(true)
	else:
		# Linterna apagada
		if huella_actual and huella_actual.has_method("notificar_iluminacion"):
			huella_actual.notificar_iluminacion(false)
			huella_actual = null
