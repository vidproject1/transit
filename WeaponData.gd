extends Resource
class_name WeaponData

## WeaponData: A resource to store unique settings for each gun.
## This allows us to have hundreds of guns with unique artist-tuned transforms.

@export_group("Visual Transforms (Hip)")
@export var weapon_scale: Vector3 = Vector3(0.3, 0.3, 0.3)
@export var weapon_position: Vector3 = Vector3(0.35, -0.25, -0.6)
@export var weapon_rotation: Vector3 = Vector3(0, 0, 0)

@export_group("ADS (Aim Down Sights)")
@export var ads_position: Vector3 = Vector3(0, -0.15, -0.5)
@export var ads_fov: float = 60.0
@export var ads_speed: float = 12.0

@export_group("Procedural Recoil")
## Max upward rotation in degrees when firing.
@export var recoil_rotation_x: float = 2.0
## Max random jitter offset in X, Y, Z.
@export var recoil_jitter: Vector3 = Vector3(0.01, 0.01, 0.01)
## How fast the weapon returns to its neutral position.
@export var recoil_recovery_speed: float = 10.0

@export_group("Animation Points (Components)")
## Local offsets for the LocalAnimator (e.g., Slide recoil)
@export var recoil_offset: Vector3 = Vector3(0, 0, 0.05)
@export var transition_speed: float = 30.0

@export_group("Stats")
@export var fire_rate: float = 0.1
@export var damage: float = 10.0
