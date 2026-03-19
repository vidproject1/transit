@tool
extends Node3D

## PointGrid: Manages a collection of Global Points for navigation or pathing.
## Objects can be assigned to follow these points in chronological order.

@export var point_color: Color = Color.CYAN
@export var draw_lines: bool = true:
	set(v):
		draw_lines = v
		_update_debug_visuals()
@export var line_color: Color = Color.YELLOW

var debug_mesh: MeshInstance3D

func _ready() -> void:
	if Engine.is_editor_hint():
		_setup_debug_mesh()

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint(): return
	
	if not debug_mesh:
		_setup_debug_mesh()
	
	_update_debug_visuals()

func _setup_debug_mesh() -> void:
	# Avoid duplicates
	for child in get_children():
		if child.name == "DebugGridMesh":
			debug_mesh = child
			return
			
	debug_mesh = MeshInstance3D.new()
	debug_mesh.name = "DebugGridMesh"
	debug_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	debug_mesh.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	# Make it not pickable to avoid clicking lines instead of points
	debug_mesh.set_meta("_edit_lock_", true)
	debug_mesh.mesh = ImmediateMesh.new()
	var mat = StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = line_color
	mat.no_depth_test = true
	debug_mesh.material_override = mat
	add_child(debug_mesh)
	debug_mesh.owner = owner

func _update_debug_visuals() -> void:
	if not debug_mesh or not draw_lines: 
		if debug_mesh: debug_mesh.mesh.clear_surfaces()
		return
		
	var points = get_sorted_points()
	if points.size() < 2:
		debug_mesh.mesh.clear_surfaces()
		return
		
	var mesh: ImmediateMesh = debug_mesh.mesh
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	for i in range(points.size() - 1):
		var p1 = points[i].position
		var p2 = points[i+1].position
		mesh.surface_add_vertex(p1)
		mesh.surface_add_vertex(p2)
		
	mesh.surface_end()

func get_sorted_points() -> Array[Node3D]:
	var points: Array[Node3D] = []
	for child in get_children():
		# Only include nodes that aren't our internal debug mesh
		if child is Node3D and child.name != "DebugGridMesh":
			points.append(child)
	
	# Sort by name (integer conversion)
	points.sort_custom(func(a, b):
		var num_a = a.name.to_int()
		var num_b = b.name.to_int()
		return num_a < num_b
	)
	return points
