@tool
extends Node3D

## FluorescentLight: A simple rectangular light fixture with emissive mesh and light source.

@export var light_color: Color = Color(1, 1, 1):
	set(value):
		light_color = value
		_update_light()

@export_range(0.0, 16.0, 0.1) var brightness: float = 1.0:
	set(value):
		brightness = value
		_update_light()

@export var light_range: float = 10.0:
	set(value):
		light_range = value
		_update_light()

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var omni_light: OmniLight3D = $OmniLight3D

func _ready():
	_update_light()

func _update_light():
	if not is_inside_tree(): return
	
	if not mesh_instance: mesh_instance = get_node_or_null("MeshInstance3D")
	if not omni_light: omni_light = get_node_or_null("OmniLight3D")
	
	if omni_light:
		omni_light.light_color = light_color
		omni_light.light_energy = brightness
		omni_light.omni_range = light_range
		
	if mesh_instance:
		var mat = mesh_instance.get_active_material(0)
		if mat is StandardMaterial3D:
			# Duplicate to avoid changing other instances if not unique
			if not mat.resource_local_to_scene:
				mat = mat.duplicate()
				mesh_instance.set_surface_override_material(0, mat)
			
			mat.albedo_color = light_color
			mat.emission_enabled = true
			mat.emission = light_color
			mat.emission_energy_multiplier = brightness * 2.0 # Make the mesh look "hotter" than the light it casts
