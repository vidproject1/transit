extends Node3D

## Weapon controller.
## Uses WeaponData resource for unique artist-tuned settings.

@export var weapon_data: WeaponData

@onready var slide_animator: Node3D = find_child("slide")

func _ready() -> void:
	if weapon_data:
		_apply_weapon_data()

func _apply_weapon_data() -> void:
	scale = weapon_data.weapon_scale
	position = weapon_data.weapon_position
	rotation_degrees = weapon_data.weapon_rotation
	
	if slide_animator and slide_animator.has_method("set"):
		# Update the LocalAnimator's points from the resource
		var points: Array[Vector3] = [Vector3.ZERO, weapon_data.recoil_offset]
		slide_animator.points = points
		slide_animator.transition_speed = weapon_data.transition_speed

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cock_weapon"):
		_cock_weapon()
	
	if event.is_action_pressed("shoot"):
		_shoot()

func _cock_weapon() -> void:
	if slide_animator and slide_animator.has_method("play_sequence"):
		var sequence: Array[int] = [1, 0]
		await slide_animator.play_sequence(sequence, 0.5)

func _shoot() -> void:
	if slide_animator and slide_animator.has_method("play_sequence"):
		# Fast slide kickback
		var sequence: Array[int] = [1, 0]
		slide_animator.play_sequence(sequence, 4.0)
	
	# Add recoil to player here if needed
	_apply_recoil()

func _apply_recoil() -> void:
	# Placeholder for camera recoil or procedural kick
	pass
