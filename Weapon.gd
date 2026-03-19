extends Node3D

## Weapon controller.
## Uses WeaponData resource for unique artist-tuned settings.
## Features: Procedural Recoil, ADS (Aim Down Sights), Component Animation.

@export var weapon_data: WeaponData

# Recoil tracking
var recoil_rot: float = 0.0
var recoil_pos: Vector3 = Vector3.ZERO

# ADS tracking
var is_ads: bool = false
var current_ads_fov: float = 75.0

@onready var slide_animator: Node3D = find_child("slide")
@onready var muzzle_flash: OmniLight3D = find_child("MuzzleFlash")
@onready var player: CharacterBody3D = get_tree().get_first_node_in_group("player")
@onready var camera: Camera3D = get_viewport().get_camera_3d()

func _ready() -> void:
	if weapon_data:
		_apply_weapon_data()
	
	if muzzle_flash:
		muzzle_flash.visible = false
		muzzle_flash.light_energy = weapon_data.muzzle_flash_energy
		muzzle_flash.light_color = weapon_data.muzzle_flash_color
	
	# Fallback if group isn't set
	if not player:
		# Search parent hierarchy for Player
		var p = get_parent()
		while p:
			if p is CharacterBody3D:
				player = p
				break
			p = p.get_parent()

func _apply_weapon_data() -> void:
	scale = weapon_data.weapon_scale
	# Position and Rotation are handled in _process for interpolation
	if slide_animator and slide_animator.has_method("set"):
		var points: Array[Vector3] = [Vector3.ZERO, weapon_data.recoil_offset]
		slide_animator.points = points
		slide_animator.transition_speed = weapon_data.transition_speed

func _input(event: InputEvent) -> void:
	if not weapon_data: return
	
	if event.is_action_pressed("cock_weapon"):
		_cock_weapon()
	
	if event.is_action_pressed("shoot"):
		_shoot()
		
	if event.is_action_pressed("ads"):
		is_ads = true
	elif event.is_action_released("ads"):
		is_ads = false

func _process(delta: float) -> void:
	if not weapon_data: return
	
	_handle_recoil_recovery(delta)
	_handle_ads_logic(delta)
	
	# Apply final transforms
	var target_pos = weapon_data.ads_position if is_ads else weapon_data.weapon_position
	position = position.lerp(target_pos + recoil_pos, delta * weapon_data.ads_speed)
	
	# Rotation combines the weapon's default rotation with recoil kick
	rotation_degrees.x = lerp(rotation_degrees.x, weapon_data.weapon_rotation.x - recoil_rot, delta * weapon_data.recoil_recovery_speed)
	rotation_degrees.y = lerp(rotation_degrees.y, weapon_data.weapon_rotation.y, delta * weapon_data.recoil_recovery_speed)
	rotation_degrees.z = lerp(rotation_degrees.z, weapon_data.weapon_rotation.z, delta * weapon_data.recoil_recovery_speed)

func _handle_recoil_recovery(delta: float) -> void:
	recoil_rot = lerp(recoil_rot, 0.0, delta * weapon_data.recoil_recovery_speed)
	recoil_pos = recoil_pos.lerp(Vector3.ZERO, delta * weapon_data.recoil_recovery_speed)

func _handle_ads_logic(delta: float) -> void:
	if not camera: camera = get_viewport().get_camera_3d()
	if not camera: return
	
	# Simple FOV shift (Player.gd also handles FOV, so we need to be careful)
	# For now, we'll let the weapon affect the camera directly
	var target_fov = weapon_data.ads_fov if is_ads else 75.0
	camera.fov = lerp(camera.fov, target_fov, delta * weapon_data.ads_speed)

func _shoot() -> void:
	if slide_animator and slide_animator.has_method("play_sequence"):
		var sequence: Array[int] = [1, 0]
		slide_animator.play_sequence(sequence, 4.0)
	
	_trigger_muzzle_flash()
	_apply_recoil()

func _trigger_muzzle_flash() -> void:
	if not weapon_data.muzzle_flash_enabled or not muzzle_flash: return
	
	muzzle_flash.visible = true
	await get_tree().create_timer(weapon_data.muzzle_flash_duration).timeout
	muzzle_flash.visible = false

func _cock_weapon() -> void:
	if slide_animator and slide_animator.has_method("play_sequence"):
		var sequence: Array[int] = [1, 0]
		await slide_animator.play_sequence(sequence, 0.5)

func _apply_recoil() -> void:
	# Upward kick
	recoil_rot += weapon_data.recoil_rotation_x
	
	# Random jitter
	recoil_pos += Vector3(
		randf_range(-weapon_data.recoil_jitter.x, weapon_data.recoil_jitter.x),
		randf_range(-weapon_data.recoil_jitter.y, weapon_data.recoil_jitter.y),
		randf_range(-weapon_data.recoil_jitter.z, weapon_data.recoil_jitter.z)
	)
