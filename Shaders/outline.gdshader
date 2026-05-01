shader_type spatial;
render_mode cull_front, unshaded;
uniform vec4 outline_color : source_color;
uniform float outline_width = 0.01;

void vertex() {
	vec4 clip_position = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	vec3 clip_normal = mat3(PROJECTION_MATRIX) * (mat3(MODELVIEW_MATRIX) * NORMAL);
	
	vec2 normal_xy = clip_normal.xy;
	if (length(normal_xy) > 0.0001) {
		vec2 offset = normalize(normal_xy) / VIEWPORT_SIZE * clip_position.w * outline_width * 2.0;
		clip_position.xy += offset;
	} else {
		clip_position.z += 0.001;
	}
	
	POSITION = clip_position;
}

void fragment() {
	ALBEDO = outline_color.rgb;
	ALPHA = outline_color.a;
}