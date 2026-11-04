shader_type canvas_item;
// Always-on subtle scanlines + vignette.

uniform float scanline_strength : hint_range(0.0, 0.5) = 0.10;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.55;

void fragment() {
	float vig = smoothstep(0.38, 1.0, distance(UV, vec2(0.5)) * 1.3);
	float scan = 0.5 + 0.5 * sin(FRAGCOORD.y * 3.14159265);
	float a = vig * vignette_strength + (1.0 - scan) * scanline_strength;
	COLOR = vec4(0.0, 0.0, 0.02, clamp(a, 0.0, 1.0));
}
