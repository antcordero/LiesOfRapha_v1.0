extends CharacterBody2D

@export var battle_scene: PackedScene = preload("res://Combat/sdc3.tscn")
@export var pre_dialogue_resource: DialogueResource = preload("res://Dialogues/rapha_previous_to_battle.dialogue")
@export var dialogue_start: String = "start"

# ID de la escena estática que quieres mostrar antes de la batalla (Ej: 4 para la torre)
@export var static_scene_pre_battle_id: int = 4

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var _battle_started: bool = false
var current_balloon: Node = null
var puede_detectar: bool = false # Escudo anti-cargas rápidas

func _ready() -> void:
	if animated_sprite:
		animated_sprite.play("front_idle_rapha")
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Escudo de 0.5 segundos para evitar que dispare colisiones al cargar el mapa
	await get_tree().create_timer(0.5).timeout
	puede_detectar = true


func _on_speak_area_body_entered(body: Node2D) -> void:
	# Si el nivel acaba de cargar, ignoramos la colisión
	if not puede_detectar:
		return
		
	# Salta automáticamente al entrar por su propio pie
	if body.is_in_group("player") and not _battle_started:
		_battle_started = true
		iniciar_secuencia_pre_batalla()


func iniciar_secuencia_pre_batalla() -> void:
	if pre_dialogue_resource == null:
		push_error("Rapha: No hay recurso de diálogo previo")
		return
		
	# 1. Le decimos al GameManager que muestre la escena estática (Ej. Torre Rapha)
	GameManager.show_static_scene(static_scene_pre_battle_id)
	
	# 2. Conectamos la señal para saber cuándo termina de leer
	if not DialogueManager.dialogue_ended.is_connected(_on_pre_dialogue_finished):
		DialogueManager.dialogue_ended.connect(_on_pre_dialogue_finished)
		
	# 3. Dibujamos el globo de diálogo encima de la escena estática
	current_balloon = DialogueManager.show_dialogue_balloon(pre_dialogue_resource, dialogue_start)


func _on_pre_dialogue_finished(resource: DialogueResource) -> void:
	if resource == pre_dialogue_resource:
		DialogueManager.dialogue_ended.disconnect(_on_pre_dialogue_finished)
		
		# 4. Quitamos la escena estática y restauramos el mapa
		GameManager.return_to_level()
		
		# 5. Lanzamos el combate final
		start_battle()


func start_battle() -> void:
	if battle_scene == null: 
		return
	
	var inst = battle_scene.instantiate()
	get_tree().root.add_child(inst)
	get_tree().paused = true
	inst.process_mode = Node.PROCESS_MODE_ALWAYS
