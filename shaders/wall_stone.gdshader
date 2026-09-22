// Maçonnerie procédurale : appareil à joints décalés, pierres nuancées,
// mousse et terre au pied des murs.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

#include "res://shaders/lib_noise.gdshaderinc"

uniform vec4 u_block_color : source_color = vec4(0.46, 0.43, 0.39, 1.0);
uniform vec4 u_block_color_alt : source_color = vec4(0.34, 0.33, 0.325, 1.0);
uniform vec4 u_mortar_color : source_color = vec4(0.165, 0.16, 0.155, 1.0);
uniform vec4 u_dirt_color : source_color = vec4(0.15, 0.19, 0.12, 1.0);
uniform float u_block_width = 1.35;
uniform float u_row_height = 0.55;
uniform float u_mortar_width : hint_range(0.005, 0.3) = 0.05;
uniform float u_roughness : hint_range(0.0, 1.0) = 0.88;
uniform float u_relief : hint_range(0.0, 1.0) = 0.25;
uniform float u_dirt_height : hint_range(0.0, 6.0) = 1.3;
uniform float u_dirt_amount : hint_range(0.0, 1.0) = 0.7;

varying vec3 v_world;
varying vec3 v_normal_world;

float wall_shape(vec2 uv) {
	float row = floor(uv.y);
	float shift = mod(row, 2.0) * 0.5;
	vec2 lc = vec2(fract(uv.x + shift), fract(uv.y));
	vec2 edge = min(lc, vec2(1.0) - lc);
	return smoothstep(0.0, max(u_mortar_width, 0.001), min(edge.x, edge.y));
}

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_normal_world = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 plane = chrono_plane(v_world, v_normal_world);
	vec2 uv = vec2(plane.x / max(u_block_width, 0.001), plane.y / max(u_row_height, 0.001));
	float shape = wall_shape(uv);
	float row = floor(uv.y);
	float tone = chrono_hash12(vec2(floor(uv.x + mod(row, 2.0) * 0.5), row) * 2.1);

	vec3 albedo = mix(u_block_color_alt.rgb, u_block_color.rgb, tone);
	float weather = chrono_fbm(uv * 1.6 + vec2(5.0, 9.0));
	albedo = mix(albedo, u_block_color_alt.rgb * 0.82, smoothstep(0.5, 1.0, weather) * 0.5);
	albedo = mix(u_mortar_color.rgb, albedo, shape);

	float dirt = 1.0 - smoothstep(0.0, max(u_dirt_height, 0.001), v_world.y);
	dirt = clamp(dirt * (0.55 + 1.0 * chrono_fbm(v_world.xz * 0.8 + vec2(v_world.y * 2.0, 3.0))), 0.0, 1.0);
	// La terre et la mousse ne poussent qu'au-dessus du niveau du sol.
	dirt *= step(0.0, v_world.y);
	albedo = mix(albedo, u_dirt_color.rgb, dirt * u_dirt_amount);
	ALBEDO = albedo;
	ROUGHNESS = mix(0.96, u_roughness, shape);
	METALLIC = 0.0;

	vec3 an = abs(v_normal_world);
	vec3 axis_u = vec3(1.0, 0.0, 0.0);
	vec3 axis_v = vec3(0.0, 1.0, 0.0);
	if (an.y >= max(an.x, an.z)) {
		axis_u = vec3(1.0, 0.0, 0.0);
		axis_v = vec3(0.0, 0.0, 1.0);
	} else if (an.x >= an.z) {
		axis_u = vec3(0.0, 0.0, 1.0);
		axis_v = vec3(0.0, 1.0, 0.0);
	}
	float e = 0.05;
	float sx = wall_shape(uv + vec2(e, 0.0));
	float sy = wall_shape(uv + vec2(0.0, e));
	vec3 grad = (axis_u * (sx - shape) + axis_v * (sy - shape)) * (u_relief * 3.0);
	NORMAL = normalize((VIEW_MATRIX * vec4(normalize(v_normal_world - grad), 0.0)).xyz);
}
