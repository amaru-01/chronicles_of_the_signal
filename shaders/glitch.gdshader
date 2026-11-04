shader_type canvas_item;
// Screen glitch: horizontal tearing + RGB split. Driven by `intensity` (0 = off).

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest, repeat_disable;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint : source_color = vec4(0.0, 0.94, 1.0, 1.0);

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float band = floor(uv.y * 26.0);
	float n = rand(vec2(band, floor(TIME * 30.0)));
	float tear = (n - 0.5) * 0.14 * intensity * step(0.5, n);
	vec2 g = vec2(uv.x + tear, uv.y);
	float split = 0.014 * intensity;
	vec3 col;
	col.r = texture(screen_tex, g + vec2(split, 0.0)).r;
	col.g = texture(screen_tex, g).g;
	col.b = texture(screen_tex, g - vec2(split, 0.0)).b;
	col += tint.rgb * 0.22 * intensity * step(0.7, n);
	COLOR = vec4(col, 1.0);
}
