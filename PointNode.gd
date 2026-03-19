@tool
extends Node3D

## PointNode: A single point in a PointGrid.
## Displays its number and a physical marker in the viewport.

@export var point_size: float = 0.2:
	set(v):
		point_size = v
		if marker_mesh:
			marker_mesh.mesh.radius = point_size
			marker_mesh.mesh.height = point_size * 2

@onready var debug_label: Label3D
@onready var marker_mesh: MeshInstance3D

func _ready() -> void:
	if Engine.is_editor_hint():
		_setup_debug_label()
		_setup_marker_mesh()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		if not debug_label: _setup_debug_label()
		if not marker_mesh: _setup_marker_mesh()
		
		# Update number based on node name
		debug_label.text = name

func _setup_debug_label() -> void:
	# Avoid duplicates
	for child in get_children():
		if child.name == "PointLabel":
			debug_label = child
			return
			
	debug_label = Label3D.new()
	debug_label.name = "PointLabel"
	debug_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	debug_label.no_depth_test = true
	debug_label.fixed_size = true
	debug_label.pixel_size = 0.002 # Reduced from 0.005
	debug_label.modulate = Color.CYAN
	debug_label.position.y = point_size + 0.1 # Offset label above point
	add_child(debug_label)
	debug_label.owner = owner

func _setup_marker_mesh() -> void:
	# Avoid duplicates
	for child in get_children():
		if child.name == "PointMarker":
			marker_mesh = child
			return
			
	marker_mesh = MeshInstance3D.new()
	marker_mesh.name = "PointMarker"
	marker_mesh.mesh = SphereMesh.new()
	marker_mesh.mesh.radius = point_size
	marker_mesh.mesh.height = point_size * 2
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color.CYAN
	mat.no_depth_test = true # Visible through walls
	marker_mesh.material_override = mat
	
	add_child(marker_mesh)
	marker_mesh.owner = owner
