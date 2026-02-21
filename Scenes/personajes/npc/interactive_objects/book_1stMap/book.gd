extends CharacterBody2D

# Configuración del Diálogo
@export var dialogue_resource: DialogueResource = preload("res://Dialogues/book.dialogue")
@export var dialogue_start: String = "start"

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var dialogue_active: bool = false
var current_balloon: Node = null
var dialogue_done: bool = false   # si quieres que solo salga una vez

func _ready() -> void:
	animated_sprite.play("book")
	
	var area: Area2D = get_node_or_null("speakArea")
	if area:
		area.body_entered.connect(_on_speak_area_body_entered)
		area.body_exited.connect(_on_speak_area_body_exited)

	# Nos conectamos una sola vez a la señal global
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_finished):
		DialogueManager.dialogue_ended.connect(_on_dialogue_finished)

func _process(_delta: float) -> void:
	# Aquí ya no miramos teclas para abrir el diálogo,
	# solo permitimos cerrarlo manualmente si quieres.
	if dialogue_active and Input.is_action_just_pressed("cancel"):
		cerrar_dialogo_forzado()

func _on_speak_area_body_entered(body: Node2D) -> void:
	print("Book speakArea entered: ", body.name)
	if body.is_in_group("player") and not dialogue_active and not dialogue_done:
		print("Mostrando diálogo del libro automáticamente")
		mostrar_dialogo()

func _on_speak_area_body_exited(body: Node2D) -> void:
	print("Book speakArea exited: ", body.name)
	if body.is_in_group("player"):
		if dialogue_active:
			cerrar_dialogo_forzado()

func mostrar_dialogo() -> void:
	if dialogue_resource == null:
		print("Error: No hay recurso de diálogo en ", name)
		return

	if dialogue_active:
		return
		
	dialogue_active = true
	current_balloon = DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_start)
	print("Balloon creado para book: ", current_balloon)

func cerrar_dialogo_forzado() -> void:
	if current_balloon and is_instance_valid(current_balloon):
		current_balloon.queue_free()
		current_balloon = null
	dialogue_active = false

func _on_dialogue_finished(_resource: DialogueResource) -> void:
	# Esta señal se dispara para cualquier diálogo;
	# solo reaccionamos si el globo de este objeto ya no existe.
	if current_balloon and not is_instance_valid(current_balloon):
		current_balloon = null
		dialogue_active = false
		dialogue_done = true   # ya no volverá a activarse automáticamente
