extends CharacterBody2D

@export var speed: float = 195.0
const STOP_DISTANCE: float = 30.0    # Distancia mínima al jugador

var player_chase: bool = false
var player: Node2D = null
var last_dir: Vector2 = Vector2.DOWN   # Dirección por defecto (mirando hacia abajo)

func _physics_process(delta: float) -> void:
	if player_chase and player != null:
		var to_player: Vector2 = player.global_position - global_position
 
		if to_player.length() > STOP_DISTANCE:
			# Se mueve hacia el jugador
			var dir: Vector2 = to_player.normalized()
			velocity = dir * speed
			last_dir = dir

			# Animaciones de caminar según dirección
			if abs(dir.x) > abs(dir.y):
				$AnimatedSprite2D.play("walk_side")
				$AnimatedSprite2D.flip_h = dir.x < 0
			elif dir.y > 0:
				$AnimatedSprite2D.play("walk_down")
			else:
				$AnimatedSprite2D.play("walk_up")
		else:
			# Está lo bastante cerca: se para en idle
			velocity = Vector2.ZERO
			_play_idle_animation()
	else:
		# No está persiguiendo a nadie
		velocity = Vector2.ZERO
		_play_idle_animation()

	move_and_slide()


func _play_idle_animation() -> void:
	# Usa la última dirección para elegir el idle
	if abs(last_dir.x) > abs(last_dir.y):
		$AnimatedSprite2D.play("idle_side")
		$AnimatedSprite2D.flip_h = last_dir.x < 0
	elif last_dir.y > 0:
		$AnimatedSprite2D.play("idle_down")
	else:
		$AnimatedSprite2D.play("idle_up")


# Zona para que siga al personaje principal
func _on_detection_area_body_entered(body: Node2D) -> void:
	player = body
	player_chase = true


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		player_chase = false
