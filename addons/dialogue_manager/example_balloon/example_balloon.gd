class_name DialogueManagerExampleBalloon
extends CanvasLayer
## Dialogue Balloon with Animal Crossing style gibberish


# ===============================
#            EXPORTS
# ===============================

@export var dialogue_resource: DialogueResource
@export var start_from_title: String = ""
@export var auto_start: bool = false
@export var next_action: StringName = &"ui_accept"
@export var skip_action: StringName = &"ui_cancel"

## Animalese samples (3–8 sonidos cortos recomendados)
@export var animalese_sounds: Array[AudioStream] = []
@export var gibberish_every_n_chars: int = 2


# ===============================
#            NODES
# ===============================

@onready var gibberish_player: AudioStreamPlayer = %GibberishPlayer
@onready var balloon: Control = %Balloon
@onready var character_label: RichTextLabel = %CharacterLabel
@onready var dialogue_label: DialogueLabel = %DialogueLabel
@onready var responses_menu: DialogueResponsesMenu = %ResponsesMenu
@onready var progress: Polygon2D = %Progress


# ===============================
#            STATE
# ===============================

var temporary_game_states: Array = []
var is_waiting_for_input: bool = false
var will_hide_balloon: bool = false
var locals: Dictionary = {}
var _locale: String = TranslationServer.get_locale()
var _last_visible_chars: int = 0

var mutation_cooldown: Timer = Timer.new()


# ===============================
#        DIALOGUE LINE
# ===============================

var dialogue_line: DialogueLine:
	set(value):
		if value:
			dialogue_line = value
			apply_dialogue_line()
		else:
			if owner == null:
				queue_free()
			else:
				hide()
	get:
		return dialogue_line


# ===============================
#            READY
# ===============================

func _ready() -> void:
	balloon.hide()

	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)

	if responses_menu.next_action.is_empty():
		responses_menu.next_action = next_action

	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)

	if auto_start:
		if not is_instance_valid(dialogue_resource):
			assert(false)
		start()


# ===============================
#            PROCESS
# ===============================

func _process(_delta: float) -> void:
	if is_instance_valid(dialogue_line):
		progress.visible = not dialogue_label.is_typing and dialogue_line.responses.size() == 0

	# Animalese while typing
	if not is_instance_valid(dialogue_label):
		return

	if dialogue_label.is_typing:
		var current := dialogue_label.visible_characters
		if current > _last_visible_chars:
			for i in range(_last_visible_chars, current):
				if (i % gibberish_every_n_chars) != 0:
					continue
				if i >= dialogue_label.text.length():
					continue
				_play_gibberish(dialogue_label.text[i])
		_last_visible_chars = current


# ===============================
#        START DIALOGUE
# ===============================

func start(with_dialogue_resource: DialogueResource = null, title: String = "", extra_game_states: Array = []) -> void:
	temporary_game_states = [self] + extra_game_states
	is_waiting_for_input = false

	if is_instance_valid(with_dialogue_resource):
		dialogue_resource = with_dialogue_resource

	if not title.is_empty():
		start_from_title = title

	dialogue_line = await dialogue_resource.get_next_dialogue_line(start_from_title, temporary_game_states)
	show()


# ===============================
#       APPLY LINE
# ===============================

func apply_dialogue_line() -> void:
	mutation_cooldown.stop()

	progress.hide()
	is_waiting_for_input = false

	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()

	character_label.visible = not dialogue_line.character.is_empty()
	character_label.text = tr(dialogue_line.character, "dialogue")

	dialogue_label.hide()
	dialogue_label.dialogue_line = dialogue_line

	responses_menu.hide()
	responses_menu.responses = dialogue_line.responses

	balloon.show()
	will_hide_balloon = false

	dialogue_label.show()

	if not dialogue_line.text.is_empty():
		_last_visible_chars = 0
		dialogue_label.type_out()
		await dialogue_label.finished_typing

	if dialogue_line.responses.size() > 0:
		balloon.focus_mode = Control.FOCUS_NONE
		responses_menu.show()

	elif dialogue_line.time != "":
		var time = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		await get_tree().create_timer(time).timeout
		next(dialogue_line.next_id)

	else:
		is_waiting_for_input = true
		balloon.focus_mode = Control.FOCUS_ALL
		balloon.grab_focus()


# ===============================
#         NEXT LINE
# ===============================

func next(next_id: String) -> void:
	dialogue_line = await dialogue_resource.get_next_dialogue_line(next_id, temporary_game_states)


# ===============================
#       ANIMALESE SYSTEM
# ===============================

func _play_gibberish(char: String) -> void:
	if char == " ":
		return
	if char in [".", ",", "!", "?", ":", ";"]:
		return
	if animalese_sounds.is_empty():
		return

	# Con 2 sonidos (A,B) o con 27, SIEMPRE funciona
	var idx := int(char.unicode_at(0)) % animalese_sounds.size()
	gibberish_player.stream = animalese_sounds[idx]

	# Micro variación natural
	gibberish_player.pitch_scale = 0.95 + randf_range(-0.06, 0.22)
	gibberish_player.volume_db = -10 + randf_range(0.0, 2.0)

	gibberish_player.play()
	if char == " ":
		return
	if char in [".", ",", "!", "?", ":", ";"]:
		return

	var upper := char.to_upper()

	# Solo letras A-Z
	if upper < "A" or upper > "Z":
		return

	var index := upper.unicode_at(0) - "A".unicode_at(0)

	if index < 0 or index >= animalese_sounds.size():
		return

	gibberish_player.stream = animalese_sounds[index]

	# Micro variación natural
	gibberish_player.pitch_scale = 1.0 + randf_range(-0.05, 0.05)
	gibberish_player.volume_db = -10 + randf_range(0.0, 2.0)

	gibberish_player.play()

# ===============================
#            SIGNALS
# ===============================

func _on_mutation_cooldown_timeout() -> void:
	if will_hide_balloon:
		will_hide_balloon = false
		balloon.hide()


func _on_mutated(_mutation: Dictionary) -> void:
	if not _mutation.is_inline:
		is_waiting_for_input = false
		will_hide_balloon = true
		mutation_cooldown.start(0.1)


func _on_balloon_gui_input(event: InputEvent) -> void:
	if dialogue_label.is_typing:
		var mouse_was_clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
		var skip_button_was_pressed: bool = event.is_action_pressed(skip_action)

		if mouse_was_clicked or skip_button_was_pressed:
			get_viewport().set_input_as_handled()
			dialogue_label.skip_typing()
			return

	if not is_waiting_for_input: return
	if dialogue_line.responses.size() > 0: return

	get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		next(dialogue_line.next_id)
	elif event.is_action_pressed(next_action) and get_viewport().gui_get_focus_owner() == balloon:
		next(dialogue_line.next_id)


func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	next(response.next_id)
