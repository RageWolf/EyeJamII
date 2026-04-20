extends CharacterBody3D

const SPEED = 4.0
const GRAVITY = -9.8
const ACCELERATION = 15.0
const FRICTION = 12.0

func _physics_process(delta):
	var direction = Vector3.ZERO
	
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_back"):
		direction.z += 1
	if Input.is_action_pressed("move_front"):
		direction.z -= 1
	
	if direction != Vector3.ZERO:
		direction = direction.normalized()
	
	# gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	# acceleration when moving, friction when stopping
	if direction != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, direction.x * SPEED, ACCELERATION * delta)
		velocity.z = move_toward(velocity.z, direction.z * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		velocity.z = move_toward(velocity.z, 0, FRICTION * delta)
	
	move_and_slide()
