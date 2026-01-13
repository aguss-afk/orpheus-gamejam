extends CanvasLayer
# UI para mostrar la secuencia de objetos a encontrar

enum Objeto { DIARIO, ZAPATOS, CINTA, ESPEJO }

# Referencias a las texturas
@export var textura_diario: Texture2D
@export var textura_zapatos: Texture2D
@export var textura_cinta: Texture2D
@export var textura_espejo: Texture2D

@onready var contenedor = $Control/HBoxContainer

var secuencia: Array = []
var tiempo_visible: float = 3.0  # Cuánto tiempo se muestran TODOS los objetos

func _ready() -> void:
	# Centrar en pantalla
	if has_node("Control"):
		$Control.set_anchors_preset(Control.PRESET_CENTER)

func configurar_secuencia(seq: Array) -> void:
	secuencia = seq
	print("=== Configurando secuencia con %d objetos ===" % secuencia.size())
	mostrar_secuencia()

func mostrar_secuencia() -> void:
	print("Mostrando secuencia de objetos...")
	
	if not contenedor:
		print("ERROR: No se encontró HBoxContainer")
		return
	
	# MOSTRAR TODOS LOS OBJETOS A LA VEZ
	for i in range(secuencia.size()):
		var icono = crear_icono_objeto(secuencia[i])
		contenedor.add_child(icono)
		
		# Aparecer gradualmente (TODOS al mismo tiempo)
		icono.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(icono, "modulate:a", 1.0, 0.5)
	
	print("Objetos generados: %d" % contenedor.get_child_count())
	
	# Esperar tiempo visible
	await get_tree().create_timer(tiempo_visible).timeout
	
	# ELIMINACIÓN DIRECTA SIN FADE
	print("UI desapareciendo...")
	print("Eliminando UI AHORA")
	queue_free()
	print("queue_free() ejecutado")

func crear_icono_objeto(tipo: Objeto) -> Control:
	var texture_rect = TextureRect.new()
	texture_rect.custom_minimum_size = Vector2(100,100)
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Cargar la textura correspondiente
	var textura: Texture2D = null
	match tipo:
		Objeto.DIARIO:
			textura = textura_diario
		Objeto.ZAPATOS:
			textura = textura_zapatos
		Objeto.CINTA:
			textura = textura_cinta
		Objeto.ESPEJO:
			textura = textura_espejo
	
	if textura:
		texture_rect.texture = textura
	else:
		# Fallback: Rectángulo de color si no hay textura
		var color_rect = ColorRect.new()
		color_rect.custom_minimum_size = Vector2(128, 128)
		match tipo:
			Objeto.DIARIO:
				color_rect.color = Color(0.6, 0.4, 0.2)
			Objeto.ZAPATOS:
				color_rect.color = Color(0.2, 0.2, 0.2)
			Objeto.CINTA:
				color_rect.color = Color(1.0, 0.2, 0.2)
			Objeto.ESPEJO:
				color_rect.color = Color(0.8, 0.8, 0.9)
		texture_rect.add_child(color_rect)
	
	# SIN ETIQUETAS - Solo la imagen
	var container = MarginContainer.new()
	container.add_theme_constant_override("margin_left", 15)
	container.add_theme_constant_override("margin_right", 15)
	container.add_child(texture_rect)
	
	return container
