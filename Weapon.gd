extends Node3D

## Weapon controller.
## Features: Procedural Recoil, ADS, Component Animation, Volumetric Smoke, Ammo & Reloads.

@export var weapon_data: WeaponData

# State tracking
var recoil_rot: float = 0.0
var recoil_pos: Vector3 = Vector3.ZERO
var is_ads: bool = false
var current_ammo: int = 10
var is_reloading: bool = false

@onready var slide_animator: Node3D = find_child("slide")
@onready var mag_node: Node3D = find_child("mag", true)
@onready var muzzle_flash: OmniLight3D = find_child("MuzzleFlash")
@onready var fog_volume: FogVolume = find_child("MuzzleSmoke")
@onready var audio_player: AudioStreamPlayer3D = find_child("FireAudio")
@onready var player: CharacterBody3D = get_tree().get_first_node_in_group("player")
@onready var camera: Camera3D = get_viewport().get_camera_3d()

func _ready() -> void:
	if weapon_data:
		current_ammo = weapon_data.max_ammo
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
			slide_animator.set("points", pts)
		if "transition_speed" in slide_animator:
			slide_animator.set("transition_speed", weapon_data.transition_speed)

func _input(event: InputEvent) -> void:
	if not weapon_data or is_reloading: return
	
	if event.is_action_pressed("shoot"): _shoot()
	if event.is_action_pressed("reload"): _reload()
	
	if event.is_action_pressed("ads"): is_ads = true
	elif event.is_action_released("ads"): is_ads = false

func _process(delta: float) -> void:
	if not weapon_data: return
	
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
		
	position = position.lerp(target_pos + recoil_pos, delta * weapon_data.ads_speed)
	
	var final_rot = target_rot
	final_rot.x -= recoil_rot
	
	var rot_speed = weapon_data.recoil_recovery_speed
	if player and player.is_sprinting:
		rot_speed = 15.0
		
	rotation_degrees = rotation_degrees.lerp(final_rot, delta * rot_speed)

func _handle_recoil_recovery(delta: float) -> void:
	recoil_rot = lerp(recoil_rot, 0.0, delta * weapon_data.recoil_recovery_speed)
	recoil_pos = recoil_pos.lerp(Vector3.ZERO, delta * weapon_data.recoil_recovery_speed)

func _shoot() -> void:
	if current_ammo <= 0:
		# TODO: Play empty click sound
		return
	
	current_ammo -= 1
	
	# Handle slide animation
	if slide_animator and slide_animator.has_method("play_sequence"):
		if current_ammo > 0:
			var sequence: Array[int] = [1, 0]
			slide_animator.play_sequence(sequence, 4.0)
		else:
			slide_animator.set("current_point_index", 1)
	
	if audio_player:
		audio_player.play()
	
	_trigger_muzzle_flash()
	_trigger_volumetric_smoke()
	_apply_recoil()

func _reload() -> void:
	if is_reloading: return
	is_reloading = true
	
	# 1. Drop the old mag
	if mag_node:
		var old_mag = mag_node
		var global_trans = old_mag.global_transform
		
		var new_mag = old_mag.duplicate()
		add_child(new_mag)
		mag_node = new_mag
		
		# Ensure the new mag has a LocalAnimator with correct points
		var anim_script = load("res://LocalAnimator.gd")
		var anim_found = false
		for child in new_mag.get_children():
			if child.get_script() == anim_script:
				anim_found = true
				var pts: Array[Vector3] = [Vector3.ZERO, Vector3(0, -0.5, 0)]
				child.set("points", pts)
				child.set("current_point_index", 1)
				break
		
		if not anim_found:
			var anim_node = Node3D.new()
			anim_node.name = "Animator"
			anim_node.set_script(anim_script)
			new_mag.add_child(anim_node)
			var pts: Array[Vector3] = [Vector3.ZERO, Vector3(0, -0.5, 0)]
			anim_node.set("points", pts)
			anim_node.set("current_point_index", 1)
		
		old_mag.reparent(get_tree().root)
		old_mag.global_transform = global_trans
		_make_mag_fall(old_mag)
	
	# 2. Animate new mag in
	await get_tree().create_timer(0.3).timeout
	if mag_node:
		var anim_script = load("res://LocalAnimator.gd")
		for child in mag_node.get_children():
			if child.get_script() == anim_script:
				child.set("current_point_index", 0)
				break
	
	# 3. Reset slide
	await get_tree().create_timer(0.4).timeout
	if slide_animator:
		slide_animator.set("current_point_index", 0)
		
	current_ammo = weapon_data.max_ammo
	is_reloading = false

func _make_mag_fall(mag: Node3D) -> void:
	var tween = create_tween()
	var fall_target = mag.global_position + Vector3(randf_range(-1, 1), -10, randf_range(-1, 1))
	var rand_rot = Vector3(randf_range(-180, 180), randf_range(-180, 180), randf_range(-180, 180))
	
	tween.set_parallel(true)
	tween.tween_property(mag, "global_position", fall_target, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(mag, "global_rotation_degrees", rand_rot, 2.0)
	
	await tween.finished
	mag.queue_free()

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
