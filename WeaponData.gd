extends Resource
class_name WeaponData

## WeaponData: A resource to store unique settings for each gun.

@export_group("Visual Transforms (Hip)")
@export var weapon_scale: Vector3 = Vector3(0.3, 0.3, 0.3)
@export var weapon_position: Vector3 = Vector3(0.35, -0.25, -0.6)
@export var weapon_rotation: Vector3 = Vector3(0, 0, 0)

@export_group("ADS (Aim Down Sights)")
@export var ads_position: Vector3 = Vector3(0, -0.21, -0.5)
@export var ads_fov: float = 60.0
@export var ads_speed: float = 12.0

@export_group("Procedural Recoil")
@export var recoil_rotation_x: float = 2.0
@export var recoil_jitter: Vector3 = Vector3(0.01, 0.01, 0.01)
@export var recoil_recovery_speed: float = 10.0

@export_group("Animation Points (Components)")
@export var recoil_offset: Vector3 = Vector3(0, 0, 0.05)
@export var transition_speed: float = 30.0

@export_group("Muzzle Flash")
@export var muzzle_flash_enabled: bool = true
@export var muzzle_flash_energy: float = 10.0
@export var muzzle_flash_color: Color = Color(1, 0.8, 0.4)
@export var muzzle_flash_duration: float = 0.05

@export_group("Volumetric Smoke")
@export var smoke_enabled: bool = true
## Initial density of the fog volume (Physical lux-based units)
@export var smoke_density: float = 1.0
@export var smoke_albedo: Color = Color(1, 1, 1, 1)
@export var smoke_emission: Color = Color(0, 0, 0, 1)
## How long the smoke lingers
@export var smoke_duration: float = 1.5
## How fast the volume sphere expands after shooting
@export var smoke_expansion_speed: float = 2.0

@export_group("Stats")
@export var fire_rate: float = 0.1
@export var damage: float = 10.0
