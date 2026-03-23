extends Control

@onready var world_env: WorldEnvironment = get_tree().get_first_node_in_group("world_environment")
@onready var shadow_toggle = %ShadowToggle
@onready var ssao_toggle = %SSAOToggle
@onready var glow_toggle = %GlowToggle
@onready var volumetric_toggle = %VolumetricToggle
@onready var aa_option = %AAOption
@onready var close_button = %CloseButton

func _ready():
	hide()
	# Initialize toggles based on current environment settings
	if world_env and world_env.environment:
		var env = world_env.environment
		ssao_toggle.button_pressed = env.ssao_enabled
		glow_toggle.button_pressed = env.glow_enabled
		volumetric_toggle.button_pressed = env.volumetric_fog_enabled
	
	# Shadows
	shadow_toggle.button_pressed = ProjectSettings.get_setting("rendering/shadows/directional_shadow/size") > 0
	
	# Connect signals
	shadow_toggle.toggled.connect(_on_shadow_toggled)
	ssao_toggle.toggled.connect(_on_ssao_toggled)
	glow_toggle.toggled.connect(_on_glow_toggled)
	volumetric_toggle.toggled.connect(_on_volumetric_toggled)
	aa_option.item_selected.connect(_on_aa_selected)
	close_button.pressed.connect(toggle_menu)

func toggle_menu():
	visible = !visible
	if visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().paused = true
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_tree().paused = false

func _on_shadow_toggled(button_pressed: bool):
	# Note: In a real build, you might want to adjust shadow map sizes at runtime
	# For now, we'll just toggle visibility of directional light shadows if possible
	var lights = get_tree().get_nodes_in_group("lights")
	for light in lights:
		if light is DirectionalLight3D or light is OmniLight3D:
			light.shadow_enabled = button_pressed

func _on_ssao_toggled(button_pressed: bool):
	if world_env and world_env.environment:
		world_env.environment.ssao_enabled = button_pressed

func _on_glow_toggled(button_pressed: bool):
	if world_env and world_env.environment:
		world_env.environment.glow_enabled = button_pressed

func _on_volumetric_toggled(button_pressed: bool):
	if world_env and world_env.environment:
		world_env.environment.volumetric_fog_enabled = button_pressed

func _on_aa_selected(index: int):
	var viewport = get_viewport()
	match index:
		0: # Disabled
			viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
			viewport.msaa_3d = Viewport.MSAA_DISABLED
			viewport.use_taa = false
		1: # Low (FXAA)
			viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
			viewport.msaa_3d = Viewport.MSAA_DISABLED
			viewport.use_taa = false
		2: # Medium (MSAA 2x)
			viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
			viewport.msaa_3d = Viewport.MSAA_2X
			viewport.use_taa = false
		3: # High (MSAA 4x + TAA)
			viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
			viewport.msaa_3d = Viewport.MSAA_4X
			viewport.use_taa = true
