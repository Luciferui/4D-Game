// Lueur temporelle : bandes d'énergie qui défilent, veines de bruit, et
// option anneau (rune au sol). Additif, non éclairé : parfait pour tout ce
// qui doit « briller » sans être un objet physique.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

#include "res://shaders/lib_noise.gdshaderinc"

// Décalage temporel (4D) : le clone i utilise TIME - i * dt.
// 0.0 (défaut) -> objet 3D classique, animation temps réel normale.
uniform float u_time_offset = 0.0;
uniform float u_alpha : hint_range(0.0, 1.0) = 1.0;

uniform vec4 u_color : source_color = vec4(0.3, 0.85, 1.0, 1.0);
uniform float u_energy : hint_range(0.0, 8.0) = 2.0;
uniform float u_scale = 3.0;
uniform float u_speed = 0.6;
uniform float u_lines : hint_range(0.0, 1.0) = 1.0;
uniform float u_ring_radius : hint_range(0.0, 1.0) = 0.0;
uniform float u_ring_width : hint_range(0.005, 0.3) = 0.06;
uniform float u_fade : hint_range(0.0, 1.0) = 0.0;

varying vec3 v_world;
varying vec3 v_normal_world;
varying vec3 v_local;
varying vec2 v_uv;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_normal_world = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_local = VERTEX;
	v_uv = UV;
}

void fragment() {
	vec2 plane = chrono_plane(v_world, v_normal_world) * u_scale;
	float t = TIME - u_time_offset;
	float flow = t * u_speed;

	float lines = 0.5 + 0.5 * sin((plane.y + plane.x * 0.35 - flow) * 6.28318);
	lines = pow(lines, 4.0);
	float veins = chrono_fbm(plane * 0.6 + vec2(0.0, -flow * 0.7));
	float glow = mix(1.0, lines, u_lines) * (0.35 + 0.9 * veins);

	if (u_ring_radius > 0.001) {
		float ring = 1.0 - smoothstep(0.0, max(u_ring_width, 0.001), abs(length(v_local.xz) - u_ring_radius));
		glow *= ring;
	}
	float vertical_fade = 1.0 - clamp(v_uv.y, 0.0, 1.0);
	glow *= mix(1.0, vertical_fade, u_fade);

	ALBEDO = u_color.rgb * u_energy;
	ALPHA = clamp(glow, 0.0, 1.0) * u_alpha;
}
