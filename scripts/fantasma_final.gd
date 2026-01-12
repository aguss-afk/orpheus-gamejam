extends Node3D
# Este script va en la escena del fantasma que aparece al final

@export var dialogo_fantasma: String = "Gracias por encontrar mi juguete... Ahora puedo descansar en paz."
@export var tiempo_antes_finalizar: float = 5.0

var player_ref = null

func _ready() -> void:
	# Buscar al jugador
	player_ref = get_tree().get_first_node_in_group("Player")
	
	# Hacer que el fantasma mire al jugador
	if player_ref:
		look_at(player_ref.global_position)
	
	# Mostrar diálogo (puedes implementar un sistema de diálogo más elaborado)
	print("========================================")
	print("FANTASMA: ", dialogo_fantasma)
	print("========================================")
	
	# Opcional: Reproducir sonido
	if has_node("AudioStreamPlayer3D"):
		$AudioStreamPlayer3D.play()
	
	# Iniciar cuenta regresiva para finalizar nivel
	await get_tree().create_timer(tiempo_antes_finalizar).timeout
	finalizar_nivel()

func interact() -> void:
	# Si el jugador interactúa antes de tiempo
	print("FANTASMA: Gracias por liberarme...")
	finalizar_nivel()

func finalizar_nivel() -> void:
	print("=== NIVEL COMPLETADO ===")
	
	# Aquí puedes:
	# 1. Mostrar pantalla de victoria
	# 2. Ir al siguiente nivel
	# 3. Volver al menú principal
	
	# Por ahora, esperamos 2 segundos y reiniciamos
	await get_tree().create_timer(2.0).timeout
	
	# OPCIÓN 1: Si tienes menú principal (ajusta la ruta)
	# get_tree().change_scene_to_file("res://scenes/menu_principal.tscn")
	
	# OPCIÓN 2: Si no tienes menú, reiniciar el nivel
	get_tree().reload_current_scene()
