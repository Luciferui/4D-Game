// Dalle scellée du portail : pierre sombre + métal, gravée de glyphes
// temporels qui pulsent. Le portail n'existe qu'à partir de w = seal_w.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

#include "res://shaders/lib_noise.gdshaderinc"

// Décalage temporel (4D) : le clone i utilise TIME - i * dt.
// 0.0 (défaut) -> objet 3D classique, animation temps réel normale.
uniform float u_time_offset = 0.0;
uniform float u_alpha : hint_range(0.0, 1.0) = 1.0;

uniform vec4 u_body_color : source_color = vec4(0.09, 0.1, 0.12, 1.0);
uniform vec4 u_metal_color : source_color = vec4(0.3, 0.31, 0.34, 1.0);
uniform vec4 u_glyph_color : source_color = vec4(1.0, 0.42, 0.12, 1.0);
uniform float u_glyph_energy : hint_range(0.0, 8.0) = 2.4;
uniform float u_glyph_scale = 2.4;
uniform float u_pulse_speed = 1.4;
uniform float u_metallic : hint_range(0.0, 1.0) = 0.6;
uniform float u_roughness : hint_range(0.0, 1.0) = 0.35;

varying vec3 v_world;
varying vec3 v_normal_world;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_normal_world = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 plane = chrono_plane(v_world, v_normal_world);
	vec2 uv = plane * u_glyph_scale;

	// Bandes horizontales gravées, entrecoupées, + fentes verticales.
	float rows = fract(uv.y * 0.5);
	float bands = 1.0 - smoothstep(0.0, 0.12, abs(rows - 0.5) - 0.34);
	float dashes = step(0.42, chrono_noise(vec2(uv.x * 0.9, floor(uv.y * 0.5) * 7.0)));
	float glyph = clamp(bands * (0.35 + 0.65 * dashes), 0.0, 1.0);

	float seam = 1.0 - smoothstep(0.0, 0.05, abs(fract(uv.x * 0.5) - 0.5) - 0.45);
	float wear = chrono_fbm(uv * 0.6);

	vec3 albedo = mix(u_body_color.rgb, u_metal_color.rgb, 0.3 + 0.5 * wear);
	ALBEDO = albedo;
	METALLIC = u_metallic;
	ROUGHNESS = mix(u_roughness, 0.85, 1.0 - glyph);

	float t = TIME - u_time_offset;
	float pulse = 0.6 + 0.4 * sin(t * u_pulse_speed + v_world.y * 1.4);
	EMISSION = u_glyph_color.rgb * (glyph + seam * 0.45) * u_glyph_energy * pulse;
	ALPHA = u_alpha;
}
