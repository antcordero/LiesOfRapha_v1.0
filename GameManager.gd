extends Node

static var menu_created := false

var current_level: Node = null
var current_ui: Node = null
var current_static_scene: Node = null

func _ready():
	if menu_created:
		queue_free()
		return

	menu_created = true
	show_menu()

func show_menu():
	if current_level:
		current_level.queue_free()
	if current_ui:
		current_ui.queue_free()
	if current_static_scene:
		current_static_scene.queue_free()

	var menu_scene = load("res://menu.tscn").instantiate()
	add_child(menu_scene)
	current_ui = menu_scene

func start_dialogue():
	if current_ui:
		current_ui.visible = false

	var game_scene = load("res://game.tscn").instantiate()
	add_child(game_scene)
	current_ui = game_scene

func show_static_scene(static_scene_id: int):
	print("Mostrando escena estática ID:", static_scene_id)
	
	# 1. PERSISTENCIA: No borramos el nivel, solo lo ocultamos y pausamos
	if current_level:
		current_level.visible = false
		# Usamos DISABLED para que los enemigos y el jugador no se muevan de fondo
		current_level.process_mode = Node.PROCESS_MODE_DISABLED 
	
	# 2. LIMPIEZA: Quitamos interfaces o escenas estáticas previas
	if current_ui:
		current_ui.queue_free()
		current_ui = null
	
	if current_static_scene:
		current_static_scene.queue_free()
	
	# 3. SELECCIÓN DE RUTA
	var scene_path := ""
	match static_scene_id:
		1:
			scene_path = "res://Escenas Estaticas/escenas_estaticas.tscn"
		2:
			scene_path = "res://Escenas Estaticas/staticScene_2.tscn"
		3:
			scene_path = "res://Escenas Estaticas/staticScene_3.tscn"
		_:
			print("ERROR: ID de escena estática no encontrado:", static_scene_id)
			return
	
	print("Cargando escena estática:", scene_path)
	
	# 4. INSTANCIACIÓN
	if scene_path != "":
		var inst = load(scene_path).instantiate()
		current_static_scene = inst
		add_child(current_static_scene)
		
		# Aseguramos que si es CanvasLayer, tenga una capa alta para no quedar oculta
		if current_static_scene is CanvasLayer:
			current_static_scene.layer = 10

func start_level(level_number: int):
	print("start_level RECIBIDO:", level_number)
	if current_static_scene:
		current_static_scene.queue_free()
		current_static_scene = null
	if current_ui:
		current_ui.queue_free()
		current_ui = null
	if current_level:
		current_level.queue_free()

	var scene_path := ""
	match level_number:
		1:
			scene_path = "res://Scenes/Level_1_scene/level_1.tscn"
		2:
			scene_path = "res://Scenes/Level_2_scene/level_2.tscn"
		3:
			scene_path = "res://Scenes/Level_3_scene/level_3.tscn"
	
	print("CARGANDO NIVEL:", level_number, " path:", scene_path)

	if scene_path != "":
		var level_scene = load(scene_path).instantiate()
		add_child(level_scene)
		current_level = level_scene

func return_to_level():
	if current_static_scene:
		current_static_scene.queue_free()
		current_static_scene = null
	
	if current_level:
		current_level.visible = true
		current_level.process_mode = Node.PROCESS_MODE_INHERIT # Reactiva el nivel
