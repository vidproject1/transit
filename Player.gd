extends CharacterBody3D

## AAA FPS Controller
## Features: Smooth movement, Sprinting, Crouching, Peaking (Leaning), Head Bob, Dynamic FOV.

@export_group("Movement Settings")
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var crouch_speed: float = 3.0
@export var acceleration: float = 10.0
@export var friction: float = 12.0
@export var air_control: float = 0.3
@export var jump_velocity: float = 12.0
@export var gravity_multiplier: float = 5.0
@export var fall_gravity_multiplier: float = 8.0

@export_group("Camera Settings")
@export var mouse_sensitivity: float = 0.002
@export var base_fov: float = 75.0
@export var sprint_fov_multiplier: float = 1.1
@export var camera_smooth_speed: float = 15.0

@export_group("Crouch Settings")
@export var crouch_height: float = 1.0
@export var stand_height: float = 2.0
@export var crouch_transition_speed: float = 10.0

@export_group("Lean Settings")
@export var lean_angle: float = 15.0
@export var lean_offset: float = 0.5
@export var lean_speed: float = 8.0

@export_group("Head Bob Settings")
@export var bob_freq: float = 2.0
@export var bob_amp: float = 0.08
@export var sprint_bob_amp: float = 0.12
@export var sprint_bob_freq: float = 3.0

@export_group("Impact Settings")
@export var landing_dip_amount: float = 0.2
@export var landing_dip_speed: float = 15.0

# Runtime variables
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_speed: float = walk_speed
var t_bob: float = 0.0
var target_lean: float = 0.0
var target_lean_offset: float = 0.0
var landing_dip: float = 0.0
var was_on_floor: bool = true
var is_sprinting: bool = false

@onready var neck: Node3D = $Neck
@onready var camera: Camera3D = $Neck/Camera3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var current_weapon: Node3D = find_child("JunkerV1", true)

func _ready() -> void:
	add_to_group("player")
	if not Engine.is_editor_hint():
		# Wait a frame for the window to settle
		await get_tree().process_frame
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint(): return
	
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		neck.rotate_x(-event.relative.y * mouse_sensitivity)
		neck.rotation.x = clamp(neck.rotation.x, deg_to_rad(-85), deg_to_rad(85))
	
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	
	_handle_movement(delta)
	_handle_crouch(delta)
	_handle_lean(delta)
	_handle_head_bob(delta)
	_handle_fov(delta)
	_handle_landing_impact(delta)
	
	was_on_floor = is_on_floor()
	move_and_slide()

func _handle_landing_impact(delta: float) -> void:
	if not was_on_floor and is_on_floor():
		landing_dip = landing_dip_amount
	
	landing_dip = lerp(landing_dip, 0.0, delta * landing_dip_speed)

func _handle_movement(delta: float) -> void:
	# Add gravity
	if not is_on_floor():
		if velocity.y > 0:
			velocity.y -= gravity * gravity_multiplier * delta
		else:
			velocity.y -= gravity * fall_gravity_multiplier * delta

	# Handle Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Handle Sprint
	var is_moving_forward = Input.is_action_pressed("move_forward")
	if Input.is_action_pressed("sprint") and is_on_floor() and is_moving_forward and velocity.length() > 0.1:
		current_speed = lerp(current_speed, sprint_speed, delta * 10.0)
		is_sprinting = true
	elif Input.is_action_pressed("crouch"):
		current_speed = lerp(current_speed, crouch_speed, delta * 10.0)
		is_sprinting = false
	else:
		current_speed = lerp(current_speed, walk_speed, delta * 10.0)
		is_sprinting = false

	# Get Input
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var accel = acceleration if is_on_floor() else acceleration * air_control
	var fric = friction if is_on_floor() else friction * air_control
	
	if direction:
		velocity.x = lerp(velocity.x, direction.x * current_speed, accel * delta)
		velocity.z = lerp(velocity.z, direction.z * current_speed, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, fric * delta)
		velocity.z = move_toward(velocity.z, 0, fric * delta)

func _handle_crouch(delta: float) -> void:
	var target_height = stand_height
	if Input.is_action_pressed("crouch"):
		target_height = crouch_height
	
	var capsule: CapsuleShape3D = collision_shape.shape
	capsule.height = lerp(capsule.height, target_height, delta * crouch_transition_speed)
	
	# Adjust camera height relative to capsule
	neck.position.y = lerp(neck.position.y, capsule.height - 0.2, delta * crouch_transition_speed)

func _handle_lean(delta: float) -> void:
	if Input.is_action_pressed("lean_left"):
		target_lean = lean_angle
		target_lean_offset = -lean_offset
	elif Input.is_action_pressed("lean_right"):
		target_lean = -lean_angle
		target_lean_offset = lean_offset
	else:
		target_lean = 0.0
		target_lean_offset = 0.0
	
	camera.rotation.z = lerp_angle(camera.rotation.z, deg_to_rad(target_lean), delta * lean_speed)

func _handle_head_bob(delta: float) -> void:
	var current_bob_freq = sprint_bob_freq if is_sprinting else bob_freq
	var current_bob_amp = sprint_bob_amp if is_sprinting else bob_amp
	
	t_bob += delta * velocity.length() * float(is_on_floor())
	var bob_pos = Vector3.ZERO
	bob_pos.y = sin(t_bob * current_bob_freq) * current_bob_amp
	bob_pos.x = cos(t_bob * current_bob_freq / 2) * current_bob_amp
	
	# Combine bob and landing impact
	var target_y = bob_pos.y - landing_dip
	camera.position.y = lerp(camera.position.y, target_y, delta * camera_smooth_speed)
	camera.position.x = lerp(camera.position.x, bob_pos.x + target_lean_offset, delta * camera_smooth_speed)

func _handle_fov(delta: float) -> void:
	var target_fov = base_fov
	var transition_speed = 5.0
	
	# Priority 1: ADS (Aim Down Sights)
	if current_weapon and current_weapon.get("is_ads"):
		var weapon_data = current_weapon.get("weapon_data")
		if weapon_data:
			target_fov = weapon_data.ads_fov
			transition_speed = weapon_data.ads_speed
	# Priority 2: Sprinting
	elif Input.is_action_pressed("sprint") and velocity.length() > walk_speed:
		target_fov = base_fov * sprint_fov_multiplier
		transition_speed = 5.0
	
	camera.fov = lerp(camera.fov, target_fov, delta * transition_speed)
