extends Node3D

## Weapon controller.
## Features: Procedural Recoil, ADS, Component Animation, Volumetric Smoke.

@export var weapon_data: WeaponData

# Recoil/ADS tracking
var recoil_rot: float = 0.0
var recoil_pos: Vector3 = Vector3.ZERO
var is_ads: bool = false

@onready var slide_animator: Node3D = find_child("slide")
@onready var muzzle_flash: OmniLight3D = find_child("MuzzleFlash")
@onready var fog_volume: FogVolume = find_child("MuzzleSmoke")
@onready var audio_player: AudioStreamPlayer3D = find_child("FireAudio")
@onready var player: CharacterBody3D = get_tree().get_first_node_in_group("player")
@onready var camera: Camera3D = get_viewport().get_camera_3d()

func _ready() -> void:
	if weapon_data:
		_apply_weapon_data()
	
	if muzzle_flash: 
		muzzle_flash.visible = false
		muzzle_flash.light_volumetric_fog_energy = 5.0
		
	if fog_volume: 
		fog_volume.visible = false
		fog_volume.material = fog_volume.material.duplicate()
		if fog_volume.material:
			fog_volume.material.albedo = weapon_data.smoke_albedo
			fog_volume.material.emission = weapon_data.smoke_emission

	if audio_player and weapon_data.fire_sound:
		audio_player.stream = weapon_data.fire_sound

func _apply_weapon_data() -> void:
	scale = weapon_data.weapon_scale
	if slide_animator:
		if "points" in slide_animator:
			var pts: Array[Vector3] = [Vector3.ZERO, weapon_data.recoil_offset]
			slide_animator.points = pts
		if "transition_speed" in slide_animator:
			slide_animator.transition_speed = weapon_data.transition_speed

func _input(event: InputEvent) -> void:
	if not weapon_data: return
	if event.is_action_pressed("shoot"): _shoot()
	if event.is_action_pressed("ads"): is_ads = true
	elif event.is_action_released("ads"): is_ads = false

func _process(delta: float) -> void:
	if not weapon_data: return
	
	# Fallback if player wasn't found in _ready (e.g. tree order)
	if not player:
		player = get_tree().get_first_node_in_group("player")
		
	_handle_recoil_recovery(delta)
	
	var target_pos = weapon_data.weapon_position
	var target_rot = weapon_data.weapon_rotation
	
	if is_ads:
		target_pos = weapon_data.ads_position
		target_rot = Vector3.ZERO
	elif player and player.is_sprinting:
		target_pos = weapon_data.sprint_position
		target_rot = weapon_data.sprint_rotation
		
	# Apply positions
	position = position.lerp(target_pos + recoil_pos, delta * weapon_data.ads_speed)
	
	# Handle rotation (including recoil)
	var final_rot = target_rot
	final_rot.x -= recoil_rot
	
	var rot_speed = weapon_data.recoil_recovery_speed
	if player and player.is_sprinting:
		rot_speed = 15.0 # Snappier transition to sprint pose
		
	rotation_degrees = rotation_degrees.lerp(final_rot, delta * rot_speed)

func _handle_recoil_recovery(delta: float) -> void:
	recoil_rot = lerp(recoil_rot, 0.0, delta * weapon_data.recoil_recovery_speed)
	recoil_pos = recoil_pos.lerp(Vector3.ZERO, delta * weapon_data.recoil_recovery_speed)

func _shoot() -> void:
	if slide_animator and slide_animator.has_method("play_sequence"):
		var sequence: Array[int] = [1, 0]
		slide_animator.play_sequence(sequence, 4.0)
	
	if audio_player:
		audio_player.play()
	
	_trigger_muzzle_flash()
	_trigger_volumetric_smoke()
	_apply_recoil()

func _trigger_muzzle_flash() -> void:
	if not muzzle_flash: return
	muzzle_flash.visible = true
	await get_tree().create_timer(weapon_data.muzzle_flash_duration).timeout
	muzzle_flash.visible = false

func _trigger_volumetric_smoke() -> void:
	if not weapon_data.smoke_enabled or not fog_volume: return
	
	var mat: FogMaterial = fog_volume.material
	
	fog_volume.size = Vector3(0.1, 0.1, 0.1)
	mat.density = weapon_data.smoke_density
	mat.emission = weapon_data.smoke_emission * 4.0
	fog_volume.visible = true
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(fog_volume, "size", Vector3(1.0, 1.0, 1.0), weapon_data.smoke_duration)
	tween.tween_property(mat, "density", 0.0, weapon_data.smoke_duration).set_ease(Tween.EASE_IN)
	tween.tween_property(mat, "emission", Color(0, 0, 0, 1), weapon_data.smoke_duration)
	
	await tween.finished
	if fog_volume: fog_volume.visible = false

func _apply_recoil() -> void:
	recoil_rot += weapon_data.recoil_rotation_x
	recoil_pos += Vector3(randf_range(-weapon_data.recoil_jitter.x, weapon_data.recoil_jitter.x), randf_range(-weapon_data.recoil_jitter.y, weapon_data.recoil_jitter.y), randf_range(-weapon_data.recoil_jitter.z, weapon_data.recoil_jitter.z))
