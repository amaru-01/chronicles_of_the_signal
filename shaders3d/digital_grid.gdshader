shader_type spatial;
render_mode unshaded;
// Digital world surfaces: dark fill with a glowing wireframe grid, projected in
// world space so merged wall blocks and the floor all share one grid.

uniform vec3 fill_color : source_color = vec3(0.02, 0.03, 0.13);
uniform vec3 line_color : source_color = vec3(0.0, 0.95, 1.0);
uniform vec3 major_color : source_color = vec3(0.85, 0.2, 1.0);
uniform float cell_size = 1.0;
uniform float major_every = 4.0;
uniform float glow = 1.6;

varying vec3 wpos;
varying vec3 wnrm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
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

float grid_line(vec2 uv, float width) {
	vec2 w = fwidth(uv) * width;
	vec2 g = abs(fract(uv - 0.5) - 0.5) / max(w, vec2(0.0001));
	return 1.0 - clamp(min(g.x, g.y), 0.0, 1.0);
}

void fragment() {
	vec2 uv = face_uv(wpos, wnrm) / cell_size;
	float minor = grid_line(uv, 1.0);
	float major = grid_line(uv / major_every, 1.6);
	vec3 col = fill_color;
	col = mix(col, line_color * glow, minor);
	col = mix(col, major_color * glow, major);
	// Walls fade toward the top so they read as light, not solid.
	float up = abs(wnrm.y);
	col *= mix(1.0, 0.75, up);
	ALBEDO = col;
}
