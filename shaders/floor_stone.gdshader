// Dalles de pierre procédurales pour le sol : joints creusés, usure, et
// lueur cyan optionnelle qui suinte entre les joints (utilisée dans le caveau).
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

#include "res://shaders/lib_noise.gdshaderinc"

uniform vec4 u_deep_color : source_color = vec4(0.19, 0.19, 0.215, 1.0);
uniform vec4 u_light_color : source_color = vec4(0.4, 0.375, 0.35, 1.0);
uniform vec4 u_grout_color : source_color = vec4(0.055, 0.055, 0.07, 1.0);
uniform vec4 u_glow_color : source_color = vec4(0.25, 0.85, 1.0, 1.0);
uniform float u_tile_size = 1.0;
uniform float u_grout_width : hint_range(0.005, 0.4) = 0.06;
uniform float u_roughness : hint_range(0.0, 1.0) = 0.8;
uniform float u_grout_glow : hint_range(0.0, 4.0) = 0.0;
uniform float u_relief : hint_range(0.0, 1.0) = 0.25;
uniform float u_grime : hint_range(0.0, 1.0) = 0.5;

varying vec3 v_world;
varying vec3 v_normal_world;

float floor_shape(vec2 uv) {
	vec2 lc = fract(uv);
	vec2 edge = min(lc, vec2(1.0) - lc);
	return smoothstep(0.0, max(u_grout_width, 0.001), min(edge.x, edge.y));
}

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_normal_world = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 uv = v_world.xz / max(u_tile_size, 0.001);
	float shape = floor_shape(uv);
	float tone = chrono_hash12(floor(uv) * 1.73);

	vec3 albedo = mix(u_deep_color.rgb, u_light_color.rgb, 0.25 + 0.75 * tone);
	float blotch = chrono_fbm(uv * 0.5 + vec2(11.0, 4.0));
	albedo = mix(albedo, u_light_color.rgb * 1.2, smoothstep(0.52, 0.95, blotch) * u_grime);
	albedo = mix(u_grout_color.rgb, albedo, shape);
	albedo *= 0.93 + chrono_fbm(uv * 7.5) * 0.1;

	ALBEDO = albedo;
	ROUGHNESS = mix(0.96, u_roughness, shape);
	METALLIC = 0.0;
	EMISSION = u_glow_color.rgb * (1.0 - shape) * u_grout_glow;

	// Léger chanfrein : on incline la normale autour des joints.
	float e = 0.05;
	float sx = floor_shape(uv + vec2(e, 0.0));
	float sz = floor_shape(uv + vec2(0.0, e));
	vec3 grad = (vec3(1.0, 0.0, 0.0) * (sx - shape) + vec3(0.0, 0.0, 1.0) * (sz - shape)) * (u_relief * 3.0);
	NORMAL = normalize((VIEW_MATRIX * vec4(normalize(v_normal_world - grad), 0.0)).xyz);
}
