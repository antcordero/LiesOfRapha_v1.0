extends CharacterBody2D

@export var battle_scene: PackedScene = preload("res://Combat/sdc3.tscn")
@export var pre_dialogue_resource: DialogueResource = preload("res://Dialogues/rapha_previous_to_battle.dialogue")
@export var dialogue_start: String = "start"

# ID de la escena estática que quieres mostrar antes de la batalla (1, 2 o 3)
@export var static_scene_pre_battle_id: int = 4

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var _battle_started: bool = false
var current_balloon: Node = null

func _ready() -> void:
	if animated_sprite:
		animated_sprite.play("front_idle_rapha")
	
	# Eliminada la conexión manual del área. Godot ya lo hace gracias a 
	# que lo conectaste desde el panel de Nodos del editor.
	
	# CRÍTICO: Permitimos que este script se ejecute aunque el GameManager
	# pause/desactive el nivel al mostrar la escena estática.
	process_mode = Node.PROCESS_MODE_ALWAYS

# --- AHORA SÍ, LA SEÑAL CORRECTA DEL EDITOR ---
func _on_speak_area_body_entered(body: Node2D) -> void:
	# Salta automáticamente al entrar, sin pulsar teclas
	if body.is_in_group("player") and not _battle_started:
		_battle_started = true
		iniciar_secuencia_pre_batalla()


func iniciar_secuencia_pre_batalla() -> void:
	if pre_dialogue_resource == null:
		push_error("Rapha: No hay recurso de diálogo previo")
		return
		
	# 1. Le decimos al GameManager que muestre la escena estática (fondo cinemático)
	GameManager.show_static_scene(static_scene_pre_battle_id)
	
	# 2. Conectamos la señal para saber cuándo el jugador termina de leer
	if not DialogueManager.dialogue_ended.is_connected(_on_pre_dialogue_finished):
		DialogueManager.dialogue_ended.connect(_on_pre_dialogue_finished)
		
	# 3. Dibujamos el globo de diálogo encima de la escena estática
	current_balloon = DialogueManager.show_dialogue_balloon(pre_dialogue_resource, dialogue_start)


func _on_pre_dialogue_finished(resource: DialogueResource) -> void:
	# Aseguramos que sea el diálogo de pre-batalla el que terminó
	if resource == pre_dialogue_resource:
		DialogueManager.dialogue_ended.disconnect(_on_pre_dialogue_finished)
		
		# 4. Quitamos la escena estática y restauramos el mapa
		GameManager.return_to_level()
		
		# 5. ¡Lanzamos el combate final!
		start_battle()


func start_battle() -> void:
	if battle_scene == null: 
		return
	
	var inst = battle_scene.instantiate()
	get_tree().root.add_child(inst)
	get_tree().paused = true
	inst.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Opcional: Hacemos que Rapha desaparezca del mapa para que no esté 
	# cuando termine el combate (ya que lo gestionará la escena final).
	# queue_free()
