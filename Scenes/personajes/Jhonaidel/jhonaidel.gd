extends CharacterBody2D

@export var battle_scene: PackedScene = preload("res://Combat/sdc2.tscn")
@export var dialogue_resource: DialogueResource = preload("res://Dialogues/jhonaidel.dialogue")
@export var dialogue_start: String = "start"

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var player_in_range: bool = false
var dialogue_active: bool = false
var battle_started: bool = false
var current_balloon: Node = null

func _ready() -> void:
	if animated_sprite:
		animated_sprite.play("idle_front_jhonaidel")
		
	# Nota: Si ya conectaste las señales desde el editor (panel "Nodos"), 
	# no necesitas las líneas de "area.body_entered.connect" aquí.
	
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_finished):
		DialogueManager.dialogue_ended.connect(_on_dialogue_finished)

func _process(_delta: float) -> void:
	if player_in_range and not dialogue_active and not battle_started:
		if Input.is_action_just_pressed("do_something"):
			mostrar_dialogo()

func mostrar_dialogo() -> void:
	if dialogue_resource == null: return
	dialogue_active = true
	if animated_sprite:
		animated_sprite.play("idle_front_jhonaidel")
		
	current_balloon = DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_start)

func _on_dialogue_finished(resource: DialogueResource) -> void:
	# IMPORTANTE: Solo disparamos la batalla si el recurso que terminó es el de Jhonaidel
	if resource == dialogue_resource and dialogue_active:
		dialogue_active = false
		start_battle()

func start_battle() -> void:
	if battle_scene == null or battle_started: return
	
	battle_started = true
	var inst = battle_scene.instantiate()
	get_tree().root.add_child(inst)
	
	get_tree().paused = true
	inst.process_mode = Node.PROCESS_MODE_ALWAYS
	

func _on_speak_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Jugador detectado por Jhonaidel")
		player_in_range = true

func _on_speak_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		# Si quieres que el diálogo se cierre al alejarse, descomenta la siguiente línea:
		# cerrar_dialogo_forzado()
