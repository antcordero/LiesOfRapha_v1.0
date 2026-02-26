extends Node

# Boss battles instances
@export var boss1_defeated_dialogue: DialogueResource = preload("res://Dialogues/franczius_defeated.dialogue")
@export var boss1_defeated_start: String = "start"

@export var boss2_defeated_dialogue: DialogueResource = preload("res://Dialogues/jhonaidel_defeated.dialogue")
@export var boss2_defeated_start: String = "start"

@export var boss3_defeated_dialogue: DialogueResource = preload("res://Dialogues/franczius_defeated.dialogue")
@export var boss3_defeated_start: String = "start"

# menu
static var menu_created := false

# Boss battles variables
var boss1_dialogue_active: bool = false
var boss2_dialogue_active: bool = false
var boss3_dialogue_active: bool = false

# levels variables
var current_level: Node = null
var current_level_number: int = 1
var current_ui: Node = null
var current_static_scene: Node = null

# --- NUEVO: PERSISTENCIA DE INVENTARIO ---
var player_bag: Bag = null
const DB: ItemDatabase = preload("res://items/items_db.tres") 
# ^ Asegúrate de que esa ruta (it_db.tres) sea la correcta en tu carpeta items

# ************************ QUIZ ************************
var quiz_beatrix_activo: bool = false


# ===================== CICLO DE VIDA =====================

func _ready() -> void:
	if menu_created:
		queue_free()
		return
	menu_created = true
	
	_setup_global_inventory()
	
	show_menu()

# ===================== UTILIDADES =====================

func _clear_all() -> void:
	if current_level:
		current_level.queue_free()
	if current_ui:
		current_ui.queue_free()
	if current_static_scene:
		current_static_scene.queue_free()

	current_level = null
	current_ui = null
	current_static_scene = null


# ===================== MENÚ / INICIO =====================

func show_menu() -> void:
	_clear_all()
	var menu_scene = load("res://menu.tscn").instantiate()
	add_child(menu_scene)
	current_ui = menu_scene

func start_dialogue() -> void:
	if current_ui:
		current_ui.visible = false

	var game_scene = load("res://game.tscn").instantiate()
	add_child(game_scene)
	current_ui = game_scene


# ===================== GESTIÓN DE NIVELES =====================
var last_level_change_time: float = 0.0

func start_level(level_number: int) -> void:
	# --- 1. FRENO DE SEGURIDAD (ANTI-SALTOS POR COLISIÓN) ---
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_level_change_time < 0.5: # 0.5 segundos de margen
		print("⚠️ Intento de cambio de nivel demasiado rápido. Ignorado.")
		return
	last_level_change_time = current_time

	print("🚀 CARGANDO NIVEL:", level_number)
	current_level_number = level_number
	
	# --- 2. LIMPIEZA DE ESTADOS ANTERIORES ---
	quiz_beatrix_activo = false
	boss1_dialogue_active = false
	boss2_dialogue_active = false
	boss3_dialogue_active = false
	
	get_tree().paused = false

	if current_static_scene:
		current_static_scene.queue_free()
		current_static_scene = null
	if current_ui:
		current_ui.queue_free()
		current_ui = null
	if current_level:
		current_level.queue_free()
		current_level = null

	# --- 3. SELECCIÓN DE ESCENA ---
	var scene_path := ""
	match level_number:
		1: scene_path = "res://Scenes/Level_1_scene/level_1.tscn"
		2: scene_path = "res://Scenes/Level_2_scene/level_2.tscn"
		3: scene_path = "res://Scenes/Level_3_scene/level_3.tscn"
		_:
			print("❌ ERROR: Nivel no encontrado:", level_number)
			return

	# --- 4. INSTANCIACIÓN ---
	var level_scene = load(scene_path).instantiate()
	add_child(level_scene)
	current_level = level_scene
	current_level.process_mode = Node.PROCESS_MODE_INHERIT
	
	get_tree().paused = false

func restart_current_level() -> void:
	print("Reiniciando nivel:", current_level_number)
	start_level(current_level_number)

func return_to_level() -> void:
	if current_static_scene:
		current_static_scene.queue_free()
		current_static_scene = null

	if current_level:
		current_level.visible = true
		current_level.process_mode = Node.PROCESS_MODE_INHERIT


# ===================== ESCENAS ESTÁTICAS =====================

func show_static_scene(static_scene_id: int) -> void:
	if current_level:
		current_level.visible = false
		current_level.process_mode = Node.PROCESS_MODE_DISABLED

	if current_ui:
		current_ui.queue_free()
		current_ui = null

	if current_static_scene:
		current_static_scene.queue_free()
		current_static_scene = null

	var scene_path := ""
	match static_scene_id:
		1: scene_path = "res://Escenas Estaticas/escenas_estaticas.tscn"
		2: scene_path = "res://Escenas Estaticas/staticScene_2.tscn"
		3: scene_path = "res://Escenas Estaticas/staticScene_3.tscn"
		_:
			print("ERROR: ID de escena estática no encontrado:", static_scene_id)
			return

	var inst = load(scene_path).instantiate()
	current_static_scene = inst
	add_child(current_static_scene)

	if current_static_scene is CanvasLayer:
		current_static_scene.layer = 10


# ===================== DIÁLOGO GLOBAL BOSS 1/2/3 =====================

func show_boss1_defeated_dialogue() -> void:
	if boss1_dialogue_active:
		return

	if boss1_defeated_dialogue == null:
		print("ERROR: boss1_defeated_dialogue es null -> salto a Nivel 2")
		start_level(2)
		return

	boss1_dialogue_active = true

	if not DialogueManager.dialogue_ended.is_connected(_on_global_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_global_dialogue_ended)

	DialogueManager.show_dialogue_balloon(boss1_defeated_dialogue, boss1_defeated_start)


func show_boss2_defeated_dialogue() -> void:
	if boss2_dialogue_active:
		return

	if boss2_defeated_dialogue == null:
		print("ERROR: boss2_defeated_dialogue es null -> salto a Nivel 3")
		start_level(3)
		return

	boss2_dialogue_active = true

	if not DialogueManager.dialogue_ended.is_connected(_on_global_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_global_dialogue_ended)

	DialogueManager.show_dialogue_balloon(boss2_defeated_dialogue, boss2_defeated_start)


func show_boss3_defeated_dialogue() -> void:
	if boss3_dialogue_active:
		return

	if boss3_defeated_dialogue == null:
		print("ERROR: boss3_defeated_dialogue es null -> vuelvo al menú")
		show_menu()
		return

	boss3_dialogue_active = true

	if not DialogueManager.dialogue_ended.is_connected(_on_global_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_global_dialogue_ended)

	DialogueManager.show_dialogue_balloon(boss3_defeated_dialogue, boss3_defeated_start)


func _on_global_dialogue_ended(_resource: DialogueResource) -> void:
	print("DEBUG: Diálogo terminado. Banderas: B1:", boss1_dialogue_active, " B2:", boss2_dialogue_active)
	
	# ==============================
	# BOSS 1: Franczius (Pasa al Nivel 2)
	# ==============================
	if boss1_dialogue_active:
		boss1_dialogue_active = false
		print("DEBUG: Boss 1 derrotado. Pasando al Nivel 2")
		start_level(2)
		return
	
	# ==============================
	# BOSS 2: Jhonaidel (Se queda en el sitio)
	# ==============================
	if boss2_dialogue_active:
		boss2_dialogue_active = false
		print("DEBUG: Jhonaidel derrotado. El jugador se queda en el nivel 2.")
		
		# Reactivamos el mapa actual
		if current_level:
			current_level.process_mode = Node.PROCESS_MODE_INHERIT
		get_tree().paused = false
		
		return # <--- Este return DEBE estar dentro del if (indentado)

	# ==============================
	# BOSS 3: Final
	# ==============================
	if boss3_dialogue_active:
		boss3_dialogue_active = false
		show_menu()
		return


# ===================== QUIZ BEATRIX =====================

func iniciar_quiz_beatrix(nivel_actual: Node) -> void:
	if quiz_beatrix_activo:
		return

	var target_node: Node = nivel_actual if nivel_actual != null else current_level
	if target_node == null:
		print("ERROR: No hay nivel donde instanciar el quiz")
		return

	quiz_beatrix_activo = true

	get_tree().paused = true
	target_node.process_mode = Node.PROCESS_MODE_DISABLED

	var quiz = load("res://quiz/beatrix_quiz.tscn").instantiate()
	target_node.add_child(quiz)

	if quiz is CanvasLayer:
		quiz.layer = 10
	else:
		quiz.z_index = 100
		quiz.top_level = true
		if quiz is Node2D:
			quiz.position = Vector2.ZERO

	quiz.quiz_completado.connect(_on_quiz_beatrix_completado)
	print("Quiz Beatrix iniciado correctamente en:", target_node.name)

func _on_quiz_beatrix_completado(exito: bool) -> void:
	quiz_beatrix_activo = false
	get_tree().paused = false

	if exito:
		print("¡GANASTE! El jugador continúa en el nivel actual.")
		if current_level:
			current_level.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		print("¡PERDISTE! Reiniciando nivel por fallo en quiz...")
		reset_quiz_flags()
		restart_current_level() 

func reset_quiz_flags() -> void:
	quiz_beatrix_activo = false


# ===================== QUIZ GENÉRICO (FUTURO) =====================

func iniciar_quiz_generic(quiz_path: String, siguiente_nivel: int) -> void:
	if quiz_beatrix_activo:
		return

	if current_level == null:
		print("ERROR: No hay current_level para quiz genérico")
		return

	quiz_beatrix_activo = true
	get_tree().paused = true
	current_level.process_mode = Node.PROCESS_MODE_DISABLED

	var quiz = load(quiz_path).instantiate()
	current_level.add_child(quiz)

	quiz.quiz_completado.connect(func(exito: bool) -> void:
		_on_quiz_generic_completado(exito, siguiente_nivel)
	)

func _on_quiz_generic_completado(exito: bool, siguiente_nivel: int) -> void:
	quiz_beatrix_activo = false
	get_tree().paused = false

	if exito:
		start_level(siguiente_nivel)
	else:
		reset_quiz_flags()
		get_tree().reload_current_scene()

# ===================== INVENTORY =====================

func _setup_global_inventory() -> void:
	var loaded := Bag.load_from_disk()
	if loaded != null:
		player_bag = loaded
		print("Inventario global cargado.")
	else:
		player_bag = Bag.new()
		print("Nuevo inventario global creado.")
	
	player_bag.db = DB
