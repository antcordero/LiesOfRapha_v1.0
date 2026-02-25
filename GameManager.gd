extends Node

@export var boss1_defeated_dialogue: DialogueResource = preload("res://Dialogues/franczius_defeated.dialogue")
@export var boss1_defeated_start: String = "start"

var boss1_dialogue_active: bool = false
static var menu_created := false

var current_level: Node = null
var current_ui: Node = null
var current_static_scene: Node = null

# --- SISTEMA DE INICIO Y MENÚ ---

func _ready():
	if menu_created:
		queue_free()
		return
	menu_created = true
	show_menu()

func show_menu():
	_clear_all()
	var menu_scene = load("res://menu.tscn").instantiate()
	add_child(menu_scene)
	current_ui = menu_scene

func _clear_all():
	if current_level: current_level.queue_free()
	if current_ui: current_ui.queue_free()
	if current_static_scene: current_static_scene.queue_free()
	current_level = null
	current_ui = null
	current_static_scene = null

# --- GESTIÓN DE NIVELES ---

func start_level(level_number: int):
	print("CARGANDO NIVEL:", level_number)
	_clear_all()
	get_tree().paused = false 

	var scene_path := ""
	match level_number:
		1: scene_path = "res://Scenes/Level_1_scene/level_1.tscn"
		2: scene_path = "res://Scenes/Level_2_scene/level_2.tscn"
		3: scene_path = "res://Scenes/Level_3_scene/level_3.tscn"
	
	if scene_path != "":
		var level_scene = load(scene_path).instantiate()
		add_child(level_scene)
		current_level = level_scene
		current_level.process_mode = Node.PROCESS_MODE_INHERIT

# --- ESCENAS ESTÁTICAS Y DIÁLOGOS GLOBALES ---

func show_static_scene(static_scene_id: int):
	if current_level:
		current_level.visible = false
		current_level.process_mode = Node.PROCESS_MODE_DISABLED 
	
	if current_ui: current_ui.queue_free()
	if current_static_scene: current_static_scene.queue_free()
	
	var scene_path := ""
	match static_scene_id:
		1: scene_path = "res://Escenas Estaticas/escenas_estaticas.tscn"
		2: scene_path = "res://Escenas Estaticas/staticScene_2.tscn"
		3: scene_path = "res://Escenas Estaticas/staticScene_3.tscn"
	
	if scene_path != "":
		var inst = load(scene_path).instantiate()
		current_static_scene = inst
		add_child(current_static_scene)
		if current_static_scene is CanvasLayer:
			current_static_scene.layer = 10

func show_boss1_defeated_dialogue() -> void:
	if boss1_dialogue_active: return
	boss1_dialogue_active = true
	if not DialogueManager.dialogue_ended.is_connected(_on_global_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_global_dialogue_ended)
	DialogueManager.show_dialogue_balloon(boss1_defeated_dialogue, boss1_defeated_start)

func _on_global_dialogue_ended(_resource: DialogueResource) -> void:
	if boss1_dialogue_active:
		boss1_dialogue_active = false
		start_level(2)

# ************************ SISTEMA DE QUIZ ************************
var quiz_beatrix_activo: bool = false

func iniciar_quiz_beatrix(nivel_actual: Node):
	if quiz_beatrix_activo: return
	
	# Seguridad: si el nivel llega nulo, usamos la referencia guardada
	var target_node = nivel_actual if nivel_actual != null else current_level
	
	if target_node == null:
		print("ERROR: No hay nivel donde instanciar el quiz")
		return

	quiz_beatrix_activo = true
	get_tree().paused = true # Pausa el movimiento de los personajes
	
	target_node.process_mode = Node.PROCESS_MODE_DISABLED # Deshabilita lógica del nivel
	
	var quiz = load("res://quiz/beatrix_quiz.tscn").instantiate()
	target_node.add_child(quiz)
	
	if quiz is CanvasLayer:
		quiz.layer = 10
	
	quiz.quiz_completado.connect(_on_quiz_beatrix_completado)
	print("Quiz Beatrix iniciado correctamente.")

func _on_quiz_beatrix_completado(exito: bool):
	quiz_beatrix_activo = false
	get_tree().paused = false # El tiempo vuelve a correr
	
	if exito:
		print("¡GANASTE! Cargando siguiente nivel.")
		start_level(3)
	else:
		print("¡PERDISTE! Reiniciando nivel actual...")
		reset_quiz_flags()
		# Recarga la escena para resetear NPCs y posición del jugador
		get_tree().reload_current_scene()

func reset_quiz_flags():
	quiz_beatrix_activo = false
