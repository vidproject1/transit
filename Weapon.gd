extends Node3D

## Weapon controller.
## Features: Procedural Recoil, ADS, Component Animation, Volumetric Smoke, Ammo & Stylish Reloads, Hitscans with Spread.

@export var weapon_data: WeaponData
@export var impact_scene: PackedScene = preload("res://Impact.tscn")

# State tracking
var recoil_rot_x: float = 0.0
var recoil_rot_y: float = 0.0
var recoil_pos: Vector3 = Vector3.ZERO
var is_ads: bool = false
var current_ammo: int = 10
var is_reloading: bool = false
var reload_tilt: float = 0.0

# Magazine tracking
var original_mag_pos: Vector3
@onready var slide_animator: Node3D = find_child("slide")
@onready var mag_node: Node3D = find_child("mag", true)

@onready var muzzle_flash: OmniLight3D = find_child("MuzzleFlash")
@onready var fog_volume: FogVolume = find_child("MuzzleSmoke")
@onready var audio_player: AudioStreamPlayer3D = find_child("FireAudio")
@onready var player: CharacterBody3D = get_tree().get_first_node_in_group("player")

var camera: Camera3D
var hit_ray: RayCast3D

func _ready() -> void:
	await get_tree().process_frame
	camera = get_viewport().get_camera_3d()
	
	if camera:
		hit_ray = RayCast3D.new()
		camera.add_child(hit_ray)
		hit_ray.target_position = Vector3(0, 0, -100)
		hit_ray.enabled = true
		hit_ray.collision_mask = 1
		if player: hit_ray.add_exception(player)

	if mag_node:
		original_mag_pos = mag_node.position
	
	if weapon_data:
		current_ammo = weapon_data.max_ammo
		_apply_weapon_data()
	
	if muzzle_flash: muzzle_flash.visible = false
	if fog_volume: 
		fog_volume.visible = false
		fog_volume.material = fog_volume.material.duplicate()

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
	elif is_reloading:
		target_pos += Vector3(0.05, -0.05, 0.1)
		
	position = position.lerp(target_pos + recoil_pos, delta * weapon_data.ads_speed)
	
	var final_rot = target_rot
	final_rot.x -= recoil_rot_x
	final_rot.y += recoil_rot_y # Random side bounce
	final_rot.z += reload_tilt
	
	var rot_speed = weapon_data.recoil_recovery_speed
	if player and player.is_sprinting:
		rot_speed = 15.0
	elif is_reloading:
		rot_speed = 10.0
		
	rotation_degrees = rotation_degrees.lerp(final_rot, delta * rot_speed)

func _handle_recoil_recovery(delta: float) -> void:
	recoil_rot_x = lerp(recoil_rot_x, 0.0, delta * weapon_data.recoil_recovery_speed)
	recoil_rot_y = lerp(recoil_rot_y, 0.0, delta * weapon_data.recoil_recovery_speed)
	recoil_pos = recoil_pos.lerp(Vector3.ZERO, delta * weapon_data.recoil_recovery_speed)

func _shoot() -> void:
	if current_ammo <= 0: return
	current_ammo -= 1
	
	_perform_hitscan()
	
	if slide_animator and slide_animator.has_method("play_sequence"):
		if current_ammo > 0:
			var sequence: Array[int] = [1, 0]
			slide_animator.play_sequence(sequence, 4.0)
		else:
			slide_animator.set("current_point_index", 1)
	
	if audio_player: audio_player.play()
	_trigger_muzzle_flash()
	_trigger_volumetric_smoke()
	_apply_recoil()

func _perform_hitscan() -> void:
	if not hit_ray: return
	
	# Apply Bullet Spread
	var current_spread = weapon_data.bullet_spread
	if is_ads: current_spread *= weapon_data.ads_spread_multiplier
	
	# Randomize the ray direction
	var spread_offset = Vector3(
		randf_range(-current_spread, current_spread),
		randf_range(-current_spread, current_spread),
		0
	)
	hit_ray.target_position = Vector3(0, 0, -100) + spread_offset
	hit_ray.force_raycast_update()
	
	if not hit_ray.is_colliding(): return
	
	var hit_pos = hit_ray.get_collision_point()
	var hit_normal = hit_ray.get_collision_normal()
	var collider = hit_ray.get_collider()
	
	# Damage Logic
	if collider:
		# Check for Headshot first (requires specific group or name)
		var is_headshot = collider.is_in_group("head")
		
		# Look for Health node on collider or its parent
		var health_node = collider.find_child("Health", true)
		if not health_node and collider.get_parent():
			health_node = collider.get_parent().find_child("Health", true)
			
		if health_node and health_node.has_method("take_damage"):
			health_node.take_damage(weapon_data.damage, is_headshot)
	
	if impact_scene:
		var impact = impact_scene.instantiate()
		get_tree().root.add_child(impact)
		impact.global_position = hit_pos
		if hit_normal.is_equal_approx(Vector3.UP) or hit_normal.is_equal_approx(Vector3.DOWN):
			impact.look_at(hit_pos + hit_normal, Vector3.RIGHT)
		else:
			impact.look_at(hit_pos + hit_normal, Vector3.UP)
		impact.rotate_object_local(Vector3.RIGHT, deg_to_rad(90))
		if collider is Node3D:
			impact.reparent(collider)

func _reload() -> void:
	if is_reloading: return
	is_reloading = true
	var tilt_tween = create_tween().set_parallel(true)
	tilt_tween.tween_property(self, "reload_tilt", -45.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if mag_node:
		var falling_mag = mag_node.duplicate()
		get_tree().root.add_child(falling_mag)
		falling_mag.global_transform = mag_node.global_transform
		_make_mag_fall(falling_mag)
		mag_node.visible = false
	await get_tree().create_timer(0.4).timeout
	if mag_node:
		mag_node.position = original_mag_pos + Vector3(-0.3, -0.4, 0)
		mag_node.visible = true
		var mag_tween = create_tween()
		mag_tween.tween_property(mag_node, "position", original_mag_pos, 0.4).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.4).timeout
	if slide_animator: slide_animator.set("current_point_index", 0)
	var untilt_tween = create_tween()
	untilt_tween.tween_property(self, "reload_tilt", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
	await untilt_tween.finished
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
	recoil_rot_x += weapon_data.recoil_rotation_x
	recoil_rot_y += randf_range(-weapon_data.recoil_rotation_y, weapon_data.recoil_rotation_y)
	recoil_pos += Vector3(randf_range(-weapon_data.recoil_jitter.x, weapon_data.recoil_jitter.x), randf_range(-weapon_data.recoil_jitter.y, weapon_data.recoil_jitter.y), randf_range(-weapon_data.recoil_jitter.z, weapon_data.recoil_jitter.z))
