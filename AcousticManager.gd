extends Node3D

## AcousticManager: Procedural reverb based on environmental raycasting.
## Samples the space around the player to adjust reverb parameters.

@export var enabled: bool = true
@export var ray_length: float = 20.0
@export var update_frequency: float = 0.1 # Every 100ms
@export var reverb_bus_name: String = "Reverb"

# Parameters for mapping
@export var min_room_size: float = 0.05
@export var max_room_size: float = 0.4
@export var wet_multiplier: float = 0.2
@export var damping_base: float = 0.8 # Very muffled for a cleaner tail
@export var spread_base: float = 0.3 # Lower spread reduces "swirling" oscillation

var time_since_update: float = 0.0
var reverb_index: int = -1
var reverb_effect: AudioEffectReverb

# Ray directions: Forward, Back, Left, Right, Up, Down
var directions: Array[Vector3] = [
	Vector3.FORWARD, Vector3.BACK, 
	Vector3.LEFT, Vector3.RIGHT, 
	Vector3.UP, Vector3.DOWN
]

func _ready() -> void:
	reverb_index = AudioServer.get_bus_index(reverb_bus_name)
	if reverb_index != -1:
		reverb_effect = AudioServer.get_bus_effect(reverb_index, 0)

func _process(delta: float) -> void:
	if not enabled or reverb_index == -1: return
	
	time_since_update += delta
	if time_since_update >= update_frequency:
		time_since_update = 0.0
		_update_acoustics()

func _update_acoustics() -> void:
	var space_state = get_world_3d().direct_space_state
	var total_distance: float = 0.0
	var hits: int = 0
	
	for dir in directions:
		# Convert local direction to global
		var global_dir = global_transform.basis * dir
		var query = PhysicsRayQueryParameters3D.create(global_position, global_position + global_dir * ray_length)
		# Exclude player from hits
		query.exclude = [get_parent().get_rid()]
		
		var result = space_state.intersect_ray(query)
		if result:
			var dist = global_position.distance_to(result.position)
			total_distance += dist
			hits += 1
		else:
			# If ray misses, we treat it as "open air"
			total_distance += ray_length
	
	# Calculate "Roominess"
	var avg_dist = total_distance / directions.size()
	
	# If we hit nothing (all rays missed or very far), dry it out
	if hits == 0:
		_apply_reverb(0.0, 0.0) # Outdoor / No reverb
	else:
		# Map average distance to room size (0.0 to 1.0)
		var room_size = clamp(avg_dist / ray_length, min_room_size, max_room_size)
		# Enclosedness: Higher hits = more enclosed = more wet signal
		var wetness = (float(hits) / directions.size()) * wet_multiplier
		
		_apply_reverb(room_size, wetness)

func _apply_reverb(room_size: float, wetness: float) -> void:
	if not reverb_effect: return
	
	# Smoothly interpolate parameters to avoid pops
	reverb_effect.room_size = lerp(reverb_effect.room_size, room_size, 0.1)
	reverb_effect.wet = lerp(reverb_effect.wet, wetness, 0.1)
	
	# Lower spread reduces the "swirling/oscillation" artifacts
	reverb_effect.spread = lerp(reverb_effect.spread, spread_base + (room_size * 0.2), 0.1)
	
	# Also adjust damping based on room size. Small rooms should be very dry/damped.
	# Increasing damping_base kills the "ringing" tail.
	reverb_effect.damping = clamp(damping_base + (1.0 - room_size) * 0.2, 0.0, 1.0)
