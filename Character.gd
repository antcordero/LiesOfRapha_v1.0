extends Node2D
class_name Character

@export var max_hp: int = 100
@export var hp: int = 100 : set = set_hp
@export var atk: int = 10
@export var character_name: String = "Personaje"
@export var is_enemy: bool = false

@onready var sprite: Sprite2D = get_node_or_null("sprite") # opcional
@onready var anim: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") # opcional
@onready var hp_bar: ProgressBar = get_node_or_null("ProgressBar")
@onready var hp_text: Label = get_node_or_null("ProgressBar/HPText")
@onready var name_label: Label = get_node_or_null("NameLabel")

signal turn_ended
signal damaged(amount: int)

var _target: Character = null
var _pending_damage: int = 0
var _is_dead: bool = false


func _ready() -> void:
	hp = clamp(hp, 0, max_hp)

	if name_label:
		name_label.text = character_name

	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = hp
		hp_bar.show_percentage = false

	update_hp_text()
	update_visuals()

	if is_enemy:
		if sprite:
			sprite.flip_h = true
		if anim:
			anim.flip_h = true

	if anim:
		if not anim.animation_finished.is_connected(_on_anim_finished):
			anim.animation_finished.connect(_on_anim_finished)

		_play_idle_if_possible()


func set_hp(value: int) -> void:
	hp = clamp(value, 0, max_hp)

	if hp_bar:
		hp_bar.value = hp

	update_hp_text()
	update_visuals()

	# Si llega a 0 y aún no estaba muerto -> morir
	if hp <= 0 and not _is_dead:
		die()


func update_hp_text() -> void:
	if hp_text:
		hp_text.text = "%d / %d" % [hp, max_hp]


func update_visuals() -> void:
	if sprite:
		sprite.modulate = Color.DIM_GRAY if hp <= 0 else Color.WHITE
	if anim:
		anim.modulate = Color.DIM_GRAY if hp <= 0 else Color.WHITE


func attack(target: Character) -> void:
	# Si está muerto, no hace nada
	if hp <= 0 or _is_dead:
		return

	_target = target
	_pending_damage = max(1, atk + randi_range(-3, 3))

	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("attack"):
		anim.play("attack")
	else:
		do_damage()
		end_turn()


func do_damage() -> void:
	if _target == null:
		return
	_target.take_damage(_pending_damage)


func take_damage(amount: int) -> void:
	# Si ya está muerto, ignora daño
	if _is_dead:
		return

	set_hp(hp - amount)
	damaged.emit(amount)

	# Efecto rojo rápido si existe sprite/anim (solo si sigue vivo)
	if hp > 0:
		if sprite:
			var tween := create_tween()
			sprite.modulate = Color.RED
			tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)

		if anim:
			var tween2 := create_tween()
			anim.modulate = Color.RED
			tween2.tween_property(anim, "modulate", Color.WHITE, 0.2)

	print(character_name, " recibe ", amount, " daño → HP:", hp)


func die() -> void:
	_is_dead = true

	# Si hay animación death, la ponemos
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("death"):
		anim.play("death")
	else:
		# Fallback si no hay death: deja gris y termina
		# (puedes queue_free aquí si quieres)
		pass


func _on_anim_finished() -> void:
	if not anim:
		return

	# Si termina attack -> aplica daño y fin turno
	if anim.animation == "attack":
		do_damage()
		_play_idle_if_possible()
		end_turn()
		return

	# Si termina death -> opcional: desaparecer
	if anim.animation == "death":
		# Opciones:
		# 1) ocultarlo:
		# visible = false
		# 2) eliminar nodo:
		# queue_free()

		# Yo recomiendo ocultarlo (más seguro para tu combate)
		visible = false


func _play_idle_if_possible() -> void:
	if not anim or not anim.sprite_frames:
		return

	# Si está muerto, no vuelvas a idle
	if _is_dead:
		return

	if anim.sprite_frames.has_animation("idle"):
		anim.play("idle")
	elif anim.sprite_frames.has_animation("default"):
		anim.play("default")


func end_turn() -> void:
	turn_ended.emit()
