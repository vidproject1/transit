extends Resource
class_name WeaponData

## WeaponData: A resource to store unique settings for each gun.
## This allows us to have hundreds of guns with unique artist-tuned transforms.

@export_group("Visual Transforms")
@export var weapon_scale: Vector3 = Vector3(1, 1, 1)
@export var weapon_position: Vector3 = Vector3(0.35, -0.25, -0.6)
@export var weapon_rotation: Vector3 = Vector3(0, 180, 0)

@export_group("Animation Points")
## Local offsets for the LocalAnimator (e.g., Slide recoil)
@export var recoil_offset: Vector3 = Vector3(0, 0, 0.05)
@export var transition_speed: float = 30.0

@export_group("Stats")
@export var fire_rate: float = 0.1
@export var damage: float = 10.0
