shader_type spatial;
// Physical world floor: dark paving with glossy puddles. Compatibility has no
// screen-space reflections, so the "wet" look is low roughness + neon highlights.

uniform vec3 paving_color : source_color = vec3(0.12, 0.12, 0.2);
uniform vec3 puddle_tint : source_color = vec3(0.04, 0.08, 0.2);
uniform float tile_size = 2.0;

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x),
			mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void fragment() {
	vec2 uv = wpos.xz / tile_size;
	vec2 g = abs(fract(uv - 0.5) - 0.5) / fwidth(uv);
	float seam = 1.0 - clamp(min(g.x, g.y), 0.0, 1.0);
	float n = vnoise(wpos.xz * 0.6) * 0.6 + vnoise(wpos.xz * 2.1) * 0.4;
	float puddle = smoothstep(0.62, 0.7, n);
	vec3 col = paving_color * (0.8 + 0.5 * hash(floor(uv)));
	col = mix(col, vec3(0.01), seam * 0.7);
	ALBEDO = mix(col, puddle_tint, puddle);
	ROUGHNESS = mix(0.75, 0.04, puddle);
	METALLIC = puddle * 0.5;
	SPECULAR = mix(0.4, 1.0, puddle);
}
