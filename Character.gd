extends Node2D
class_name Character

@export var max_hp: int = 100
@export var hp: int = 100 : set = set_hp
@export var atk: int = 10
@export var character_name: String = "Personaje"
@export var is_enemy: bool = false

@onready var sprite: Sprite2D = $sprite
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var hp_bar: ProgressBar = $ProgressBar
@onready var hp_text: Label = $ProgressBar/HPText
@onready var name_label: Label = $NameLabel

signal turn_ended
signal damaged(amount: int)

var _target: Character = null
var _pending_damage: int = 0


func _ready() -> void:
	if anim and anim.has_animation("aur aur"):
		anim.play("aur aur")
	hp = clamp(hp, 0, max_hp)

	if name_label:
		name_label.text = character_name

	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = hp
		hp_bar.show_percentage = false

	update_hp_text()
	update_visuals()

	if is_enemy and sprite:
		sprite.flip_h = true

	# Para detectar fin de animación
	if anim and not anim.animation_finished.is_connected(_on_anim_finished):
		anim.animation_finished.connect(_on_anim_finished)


func set_hp(value: int) -> void:
	hp = clamp(value, 0, max_hp)
	if hp_bar:
		hp_bar.value = hp
	update_hp_text()
	update_visuals()


func update_hp_text() -> void:
	if hp_text:
		hp_text.text = "%d / %d" % [hp, max_hp]


func update_visuals() -> void:
	if sprite:
		sprite.modulate = Color.DIM_GRAY if hp <= 0 else Color.WHITE


func attack(target: Character) -> void:
	if hp <= 0:
		return

	_target = target
	_pending_damage = max(1, atk + randi_range(-3, 3))

	# Si existe animación "attack", la usamos.
	# Si no existe, hacemos el daño instantáneo (fallback).
	if anim and anim.has_animation("attack"):
		anim.play("attack")
	else:
		do_damage() # daño instantáneo
		end_turn()  # fin turno instantáneo


# ⚔️ Esto lo llamas desde el AnimationPlayer con "Call Method Track"
# (o se llama solo en el fallback)
func do_damage() -> void:
	if _target == null:
		return
	_target.take_damage(_pending_damage)


func take_damage(amount: int) -> void:
	hp -= amount
	damaged.emit(amount)

	if sprite:
		var tween := create_tween()
		sprite.modulate = Color.RED
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)

	print(character_name, " recibe ", amount, " daño → HP:", hp)


func _on_anim_finished(anim_name: StringName) -> void:
	if anim_name == "attack":
		# opcional: volver a idle si existe
		if anim and anim.has_animation("aur aur"):
			anim.play("aur aur")
		end_turn()


func end_turn() -> void:
	turn_ended.emit()
