extends Node

@export var boss1_defeated_dialogue: DialogueResource = preload("res://Dialogues/franczius_defeated.dialogue")
@export var boss1_defeated_start: String = "start"

var boss1_dialogue_active: bool = false

static var menu_created := false

var current_level: Node = null
var current_level_number: int = 1
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
	
	if current_level:
		current_level.visible = false
		current_level.process_mode = Node.PROCESS_MODE_DISABLED 
	
	if current_ui:
		current_ui.queue_free()
		current_ui = null
	
	if current_static_scene:
		current_static_scene.queue_free()
	
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
	
	if scene_path != "":
		var inst = load(scene_path).instantiate()
		current_static_scene = inst
		add_child(current_static_scene)
		
		if current_static_scene is CanvasLayer:
			current_static_scene.layer = 10

func start_level(level_number: int):
	print("start_level RECIBIDO:", level_number)
	current_level_number = level_number   # 👈 ESTO ES LO QUE FALTABA
	get_tree().paused = false  # doble seguridad

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
		
		current_level.process_mode = Node.PROCESS_MODE_INHERIT
		get_tree().paused = false


func return_to_level():
	if current_static_scene:
		current_static_scene.queue_free()
		current_static_scene = null
	
	if current_level:
		current_level.visible = true
		current_level.process_mode = Node.PROCESS_MODE_INHERIT

func restart_current_level():
	print("Reiniciando nivel:", current_level_number)
	start_level(current_level_number)

### BOSS 1
func show_boss1_defeated_dialogue() -> void:
	if boss1_dialogue_active:
		return

	if boss1_defeated_dialogue == null:
		print("ERROR: boss1_defeated_dialogue es null")
		start_level(2)
		return

	boss1_dialogue_active = true

	if not DialogueManager.dialogue_ended.is_connected(_on_global_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_global_dialogue_ended)

	DialogueManager.show_dialogue_balloon(boss1_defeated_dialogue, boss1_defeated_start)

func _on_global_dialogue_ended(_resource: DialogueResource) -> void:
	if boss1_dialogue_active:
		boss1_dialogue_active = false
		start_level(2)

#************************ QUIZ ************************
var quiz_beatrix_activo: bool = false

func iniciar_quiz_beatrix(nivel_actual: Node):
	# NPC llama esto al terminar el diálogo
	if quiz_beatrix_activo:
		return
	
	quiz_beatrix_activo = true
	
	# Pausamos lógica del juego
	get_tree().paused = true
	if nivel_actual:
		nivel_actual.process_mode = Node.PROCESS_MODE_DISABLED
	
	# Instanciamos el quiz
	var quiz = load("res://quiz/beatrix_quiz.tscn").instantiate()
	
	# Lo añadimos al nivel actual
	nivel_actual.add_child(quiz)
	
	# Aseguramos que salga por encima y centrado
	if quiz is CanvasLayer:
		quiz.layer = 10
	else:
		quiz.z_index = 100
		quiz.top_level = true
		quiz.position = Vector2.ZERO
	
	# Conectamos señal de resultado
	quiz.quiz_completado.connect(_on_quiz_beatrix_completado)
	
	print("Quiz Beatrix CARGADO en nivel: ", nivel_actual.name)

func _on_quiz_beatrix_completado(exito: bool):
	quiz_beatrix_activo = false
	
	# 1. Despausamos el árbol principal ANTES de cualquier cambio
	get_tree().paused = false
	
	print("DEBUG QUIZ END: Pausa desactivada. Éxito: ", exito)
	
	if exito:
		print("QUIZ Beatrix OK → Cargando Nivel 3")
		start_level(3)
		
		# Seguridad: Forzamos que el nivel recién creado procese
		if current_level:
			current_level.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		print("QUIZ Beatrix FALLIDO → Reiniciando Nivel Actual")
		# Si falla, reseteamos flags y recargamos para que pueda volver a hablar con el NPC
		reset_quiz_flags()
		get_tree().reload_current_scene()

# Para otros bosses/quizzes en futuro
func iniciar_quiz_generic(quiz_path: String, siguiente_nivel: int):
	quiz_beatrix_activo = true
	get_tree().paused = true
	var quiz = load(quiz_path).instantiate()
	current_level.add_child(quiz)
	quiz.quiz_completado.connect(func(exito): _on_quiz_generic_completado(exito, siguiente_nivel))

func _on_quiz_generic_completado(exito: bool, siguiente_nivel: int):
	quiz_beatrix_activo = false
	get_tree().paused = false
	if exito:
		start_level(siguiente_nivel)

# Reset flags al fallar y recargar nivel
func reset_quiz_flags():
	quiz_beatrix_activo = false
