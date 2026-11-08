shader_type spatial;
// Physical world walls: dark wet brick, procedural and world-space so merged
// wall blocks line up. Lit, so the neon lights wash over it.

uniform vec3 brick_color : source_color = vec3(0.2, 0.09, 0.1);
uniform vec3 mortar_color : source_color = vec3(0.05, 0.04, 0.07);
uniform float brick_w = 0.5;
uniform float brick_h = 0.25;

varying vec3 wpos;
varying vec3 wnrm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 face_uv(vec3 p, vec3 n) {
	vec3 a = abs(n);
	if (a.y > 0.5) {
		return p.xz;
	}
	if (a.x > 0.5) {
		return p.zy;
	}
	return p.xy;
}

void fragment() {
	vec2 uv = face_uv(wpos, wnrm);
	vec2 b = vec2(uv.x / brick_w, uv.y / brick_h);
	b.x += mod(floor(b.y), 2.0) * 0.5;
	vec2 id = floor(b);
	vec2 f = fract(b);
	float mortar = max(step(f.x, 0.07), step(f.y, 0.14));
	float v = hash(id);
	vec3 col = brick_color * (0.55 + 0.9 * v);
	// Darker, grimier toward the ground.
	col *= mix(0.45, 1.0, clamp(wpos.y / 3.0, 0.0, 1.0));
	ALBEDO = mix(col, mortar_color, mortar);
	ROUGHNESS = mix(0.35, 0.9, v);
	SPECULAR = 0.5;
}
