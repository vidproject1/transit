shader_type spatial;
render_mode blend_mix, cull_disabled, unshaded;

uniform sampler2D texture_albedo : source_color;
uniform sampler2D depth_texture : hint_depth_texture;
uniform float proximity_fade_distance = 0.2;

uniform int particles_anim_h_frames = 1;
uniform int particles_anim_v_frames = 1;

void vertex() {
	// Standard Billboard logic
	mat4 mat_world = mat4(
		normalize(INV_VIEW_MATRIX[0]),
		normalize(INV_VIEW_MATRIX[1]),
		normalize(INV_VIEW_MATRIX[2]),
		MODEL_MATRIX[3]
	);
	
	// Particle rotation from INSTANCE_CUSTOM
	float rot = INSTANCE_CUSTOM.x;
	mat4 mat_rot = mat4(
		vec4(cos(rot), -sin(rot), 0.0, 0.0),
		vec4(sin(rot), cos(rot), 0.0, 0.0),
		vec4(0.0, 0.0, 1.0, 0.0),
		vec4(0.0, 0.0, 0.0, 1.0)
	);
	
	MODELVIEW_MATRIX = VIEW_MATRIX * mat_world * mat_rot;
	
	// Scale maintenance
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
		vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
		vec4(0.0, 0.0, 0.0, 1.0)
	);
}

void fragment() {
	vec4 tex = texture(texture_albedo, UV);
	
	// 1. Soft Radial Mask to force a round shape and kill square corners
	float dist = distance(UV, vec2(0.5));
	float radial = 1.0 - smoothstep(0.3, 0.5, dist);
	
	// 2. Erosion Logic: smoke dissolves as it lives
	// Noise alpha is sharpened by particle age (COLOR.a)
	float erosion = 1.0 - COLOR.a;
	float alpha_shape = smoothstep(erosion, erosion + 0.2, pow(tex.a, 1.5));
	
	// 3. Proximity Fade (Soft Particles)
	float depth = texture(depth_texture, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	float proximity_fade = clamp((linear_depth - VERTEX.z) / proximity_fade_distance, 0.0, 1.0);
	
	ALBEDO = COLOR.rgb;
	ALPHA = alpha_shape * radial * COLOR.a * proximity_fade;
}
