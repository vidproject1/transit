@tool
extends Node3D

## LocalAnimator: Manages local animation points for weapon components.
## Allows you to define points (offsets) and animate between them.

@export_group("Points Configuration")
## Points are local offsets relative to the initial position.
@export var points: Array[Vector3] = [Vector3.ZERO, Vector3(0, 0, -0.07)] # Default: 7cm (70mm) back on Z

@export_group("Animation Controls")
@export var transition_speed: float = 15.0
@export var current_point_index: int = 0:
	set(v):
		current_point_index = clamp(v, 0, points.size() - 1)
		target_position = points[current_point_index]

var initial_position: Vector3
var target_position: Vector3

func _ready() -> void:
	initial_position = position
	target_position = points[current_point_index]

func _process(delta: float) -> void:
	# Smoothly interpolate to the target point
	position = position.lerp(initial_position + target_position, delta * transition_speed)
	
	if Engine.is_editor_hint():
		# In editor, we might want to visualize the points
		_draw_debug_points()

func play_sequence(sequence: Array[int], speed_multiplier: float = 1.0) -> void:
	for idx in sequence:
		current_point_index = idx
		# Wait for arrival (approximate arrival time based on speed)
		await get_tree().create_timer(1.0 / (transition_speed * speed_multiplier)).timeout

func _draw_debug_points() -> void:
	# Viewport visualization of where the points are
	pass
