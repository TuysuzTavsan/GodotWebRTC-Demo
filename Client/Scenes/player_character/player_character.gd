extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var anim_tree
var anim_player
var attack_state : bool = false
var attack_count : int = 1
var attack_timer : int = 0


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	anim_tree = $AnimationTree.get("parameters/playback")
	anim_player = $AnimationPlayer
	
	if get_multiplayer_authority() == (1 if User.is_host else 2):
		$Camera2D.enabled = true
		$Control/VBoxContainer/Control2/Label.text = User.user_name
	else:
		$Control/VBoxContainer/Control2/Label.text = User.other_user_name
		set_physics_process(false)
		set_process(false)
		set_process_input(false)

func _process(delta):
	check_health()
	set_animation()

func check_health():
	if $Control/VBoxContainer/Control/TextureProgressBar.value <= 0:
		die.rpc()

func _physics_process(delta):
	
	
	if Input.is_action_pressed("move_left"):
		$Sprite2D.flip_h = true
		$Area2D.transform.x.x = -1
		sync_flip.rpc(-1)
	if Input.is_action_pressed("move_right"):
		$Sprite2D.flip_h = false
		$Area2D.transform.x.x = 1
		sync_flip.rpc(1)
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	move_and_slide()

func set_animation():
	
	if Input.is_action_just_pressed("jump") :
		anim_tree.travel("Jump")
		sync_animation.rpc("Jump")
	elif Input.is_action_just_pressed("left_mouse"):
		attack_state = true
		attack_timer = Time.get_ticks_msec()
		match attack_count:
			1:
				anim_tree.travel("Attack_1")
				sync_animation.rpc("Attack_1")
				attack_count = 2
			2:
				anim_tree.travel("Attack_2")
				sync_animation.rpc("Attack_2")
				attack_count = 3
			3:
				anim_tree.travel("Attack_3")
				sync_animation.rpc("Attack_3")
				attack_count = 1
	elif Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
		if is_on_floor() and not attack_state:
			anim_tree.travel("Run")
			sync_animation.rpc("Run")
	elif is_on_floor() and not attack_state:
		anim_tree.travel("Idle")
		sync_animation.rpc("Idle")
	
	
	if attack_state:
		if Time.get_ticks_msec() - attack_timer >= 500:
			attack_state = false
			attack_count = 1

@rpc("any_peer","call_local","reliable")
func die():
	$AnimationTree.set_active(false)
	anim_player.play("Dead")
	set_physics_process(false)
	set_process(false)

@rpc("any_peer","call_remote","reliable")
func sync_animation(anim_name: StringName):
	anim_tree.travel(anim_name)


@rpc("any_peer","call_remote","reliable")
func sync_flip(dir : int):
	$Area2D.transform.x.x = dir

@rpc("any_peer","call_local","reliable")
func hit_received():
	anim_tree.start("Hurt", true)
	$Control/VBoxContainer/Control/TextureProgressBar.value -= 5

func _on_area_2d_body_entered(body):
	if body != self:
		body.hit_received.rpc()
