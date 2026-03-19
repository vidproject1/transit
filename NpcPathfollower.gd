extends CharacterBody3D

## NpcPathfollower: A simple example of an NPC following a PointGrid.

@export var point_grid_path: NodePath
@export var movement_speed: float = 3.0
@export var arrival_threshold: float = 0.5

var points: Array[Node3D] = []
var current_point_index: int = 0

@onready var grid: Node3D = get_node(point_grid_path)

func _ready() -> void:
	if grid and grid.has_method("get_sorted_points"):
		points = grid.get_sorted_points()

func _physics_process(delta: float) -> void:
	if points.is_empty(): return
	
	var target = points[current_point_index]
	var direction = (target.global_position - global_position).normalized()
	
	# Basic movement logic
	velocity = direction * movement_speed
	move_and_slide()
	
	# Check for arrival
	if global_position.distance_to(target.global_position) < arrival_threshold:
		current_point_index = (current_point_index + 1) % points.size()
