shader_type canvas_item;

uniform float strength : hint_range(0.0, 2.0) = 1.0;
uniform float radius : hint_range(0.0, 1.0) = 0.75;
uniform float softness : hint_range(0.0, 1.0) = 0.45;
uniform vec4 color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
    vec2 uv = UV;
    
    float dist = distance(uv, vec2(0.5));
    
    // FIXED: edges dark, center clear
    float vignette = smoothstep(radius - softness, radius, dist);
    
    COLOR = vec4(color.rgb, vignette * strength * color.a);
}