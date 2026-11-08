shader_type canvas_item;
// Reality-swap transition. `old_tex` is the frame captured just before the swap.
// A jagged diagonal line sweeps left to right: behind it the live (new) world is
// visible, ahead of it the old frame is still shown. progress 0 -> 1.

uniform sampler2D old_tex : filter_nearest, repeat_disable;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 edge_color : source_color = vec4(0.9, 1.0, 1.0, 1.0);
uniform vec4 edge_glow : source_color = vec4(0.0, 0.95, 1.0, 1.0);
uniform float slant = 0.45;
uniform float jag = 0.045;
uniform float edge_width = 0.006;

float hash(float n) {
	return fract(sin(n * 91.345) * 47453.5453);
}

void fragment() {
	vec2 uv = UV;
	// Jagged offset per horizontal band, re-rolled a few times a second.
	float band = floor(uv.y * 54.0);
	float j = (hash(band + floor(TIME * 18.0)) - 0.5) * jag;
	float t = uv.x + (uv.y - 0.5) * slant + j;
	float front = mix(-0.35, 1.35, progress);
	float d = t - front;

	if (d < -edge_width * 4.0) {
		COLOR = vec4(0.0); // new world, live view shows through
	} else if (d < edge_width) {
		float core = 1.0 - smoothstep(0.0, edge_width, abs(d));
		vec3 c = mix(edge_glow.rgb * 2.0, edge_color.rgb * 2.5, core);
		COLOR = vec4(c, 1.0);
	} else {
		// RGB split on the old frame, strongest near the line.
		float s = 0.012 * (1.0 - smoothstep(0.0, 0.25, d));
		vec3 col;
		col.r = texture(old_tex, uv + vec2(s, 0.0)).r;
		col.g = texture(old_tex, uv).g;
		col.b = texture(old_tex, uv - vec2(s, 0.0)).b;
		COLOR = vec4(col, 1.0);
	}
}
