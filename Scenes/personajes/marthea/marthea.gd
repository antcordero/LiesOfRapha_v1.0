extends CharacterBody2D

const SPEED = 80


var current_dir = "none"

func _physics_process(delta):
	player_movement(delta)

func player_movement(delta):
	if Input.is_action_pressed("ui_right"):
		current_dir = "right"
		player_animation(1)
		velocity.x = SPEED
		velocity.y = 0
	elif Input.is_action_pressed("ui_left"):
		current_dir = "left"
		player_animation(1)
		velocity.x = -SPEED
		velocity.y = 0
	elif Input.is_action_pressed("ui_down"):
		current_dir = "down"
		player_animation(1)
		velocity.y = SPEED
		velocity.x = 0
	elif Input.is_action_pressed("ui_up"):
		current_dir = "up"
		player_animation(1)
		velocity.y = -SPEED
		velocity.x = 0
	else:
		velocity.x = 0
		velocity.y = 0
		player_animation(0) #idle
	
	move_and_slide()

func player_animation(movement):
	var direction = current_dir
	var animation = $AnimatedSprite2D
	
	if direction == "right":
		animation.flip_h = false
		if movement == 1:
			animation.play("walk_side")
		elif movement == 0:
			animation.play("idle_side")
	
	if direction == "left":
		animation.flip_h = true
		if movement == 1:
			animation.play("walk_side")
		elif movement == 0:
			animation.play("idle_side")
	
	if direction == "down":
		animation.flip_h = true
		if movement == 1:
			animation.play("walk_down")
		elif movement == 0:
			animation.play("idle_down")
	
	if direction == "up":
		animation.flip_h = true
		if movement == 1:
			animation.play("walk_up")
		elif movement == 0:
			animation.play("idle_up")
	
