extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interact_area: Area2D = $InteractArea

var dialogue_resource: DialogueResource = preload("res://Dialogues/shop_goblin.dialogue")
var dialogue_start: String = "start"

var player_in_range := false
var dialogue_active := false

func _ready() -> void:
	animated_sprite.play("idle")
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func _process(_delta: float) -> void:
	if dialogue_active:
		return

	if player_in_range and Input.is_action_just_pressed("do_something"):
		dialogue_active = true
		DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_start)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = false

func _on_dialogue_ended(_res: DialogueResource) -> void:
	dialogue_active = false
