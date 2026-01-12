extends Node3D

# Configuración del nivel
@export var pistas_necesarias: int = 6  # Cambiado a 6
var pistas_encontradas: int = 0

# Referencia al juguete que aparecerá al ganar
@export var objeto_final: Node3D

func _ready() -> void:
	# Al empezar, aseguramos que el juguete esté invisible/escondido
	if objeto_final:
		objeto_final.visible = false
		objeto_final.process_mode = Node.PROCESS_MODE_DISABLED
		print("Nivel iniciado: Busca ", pistas_necesarias, " huellas reales.")
	else:
		print("ADVERTENCIA: No se asignó el objeto final en el Inspector")

func registrar_pista_encontrada():
	pistas_encontradas += 1
	print("¡Progreso! Pistas: ", pistas_encontradas, "/", pistas_necesarias)
	
	if pistas_encontradas >= pistas_necesarias:
		evento_victoria()

func evento_victoria():
	print("¡HAS ENCONTRADO TODAS LAS PISTAS!")
	
	# Hacemos aparecer el juguete
	if objeto_final:
		objeto_final.visible = true
		objeto_final.process_mode = Node.PROCESS_MODE_INHERIT
		
		print("El juguete ha aparecido en el mapa. ¡Encuéntralo!")
		
		# Opcional: Reproducir sonido de logro
		# if has_node("SonidoVictoria"):
		#     $SonidoVictoria.play()
	else:
		print("ERROR: No hay objeto final asignado")
