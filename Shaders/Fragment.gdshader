shader_type spatial;

uniform sampler2D tex;   // 👈 we define texture ourselves
uniform float glitch_strength : hint_range(0.0, 1.0);
uniform float time_scale = 6.0;

float rand(vec2 co){
	return fract(sin(dot(co, vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * time_scale;

	// 🔹 horizontal slice glitch
	float slice = step(0.5, fract(uv.y * 12.0 + t));
	uv.x += slice * (rand(vec2(t, uv.y)) - 0.5) * 0.08 * glitch_strength;

	// 🔹 vertical glitch
	float v_slice = step(0.7, rand(vec2(floor(uv.x * 20.0), t)));
	uv.y += v_slice * 0.05 * glitch_strength;

	// 🔹 RGB split
	float offset = glitch_strength * 0.02;

	float r = texture(tex, uv + vec2(offset, 0)).r;
	float g = texture(tex, uv).g;
	float b = texture(tex, uv - vec2(offset, 0)).b;

	vec3 col = vec3(r, g, b);

	// 🔹 flicker
	col *= 1.0 - glitch_strength * rand(vec2(t));

	ALBEDO = col;
	ALPHA = texture(tex, uv).a;
}