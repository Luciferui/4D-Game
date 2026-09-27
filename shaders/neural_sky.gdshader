// Ciel neuronal optimise : toile de neurones procedurale avec decharges douces.
// Pas d'orage ni de tonnerre. Moitie des calculs du shader original.
shader_type sky;

#include "res://shaders/lib_noise.gdshaderinc"

// Decalage temporel (4D) : coherent avec les autres shaders du niveau.
uniform float u_time_offset = 0.0;

uniform vec4 u_deep_color : source_color = vec4(0.006, 0.004, 0.016, 1.0);
uniform vec4 u_tissue_color : source_color = vec4(0.05, 0.02, 0.1, 1.0);
uniform vec4 u_neuron_color : source_color = vec4(0.35, 0.75, 1.0, 1.0);
uniform vec4 u_fire_color : source_color = vec4(1.0, 0.62, 0.24, 1.0);

uniform float u_density : hint_range(0.5, 8.0) = 2.2;
uniform float u_node_glow : hint_range(0.0, 4.0) = 1.0;
uniform float u_wire_glow : hint_range(0.0, 4.0) = 0.7;
uniform float u_pulse_speed : hint_range(0.0, 12.0) = 3.2;
uniform float u_drift : hint_range(0.0, 0.2) = 0.01;

// Voronoi 3D allege : distance au plus proche germe et au second.
void neural_voronoi(vec3 p, out float f1, out float f2, out vec3 id1) {
	vec3 base = floor(p);
	f1 = 1e9;
	f2 = 1e9;
	id1 = vec3(0.0);
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			for (int z = -1; z <= 1; z++) {
				vec3 cell = base + vec3(float(x), float(y), float(z));
				vec3 jitter = vec3(
					chrono_hash12(cell.xy + cell.z * 1.7),
					chrono_hash12(cell.yz + cell.x * 2.3),
					chrono_hash12(cell.zx + cell.y * 3.1));
				float d = length(cell + jitter - p);
				if (d < f1) {
					f2 = f1;
					f1 = d;
					id1 = cell;
				} else if (d < f2) {
					f2 = d;
				}
			}
		}
	}
}

// Couche neuronale : lueur douce des corps cellulaires (x) et des axones (y).
vec2 neural_layer(vec3 dir, float scale, float offset, float t) {
	vec3 p = dir * scale + vec3(offset);
	float f1;
	float f2;
	vec3 id1;
	neural_voronoi(p, f1, f2, id1);

	float rnd = chrono_hash12(id1.xy + id1.z * 4.7);

	// Decharge douce : puissances reduites pour un feu lisse et peu couteux.
	float blink = pow(0.5 + 0.5 * sin(t * (0.45 + 0.9 * rnd) * 6.28318 + rnd * 6.28318), 3.0);
	float surge = pow(0.5 + 0.5 * sin(dot(dir, vec3(rnd - 0.5, rnd * 0.7, 0.33)) * 2.0 - t * u_pulse_speed * 0.25), 4.0);
	float fire = clamp(blink + surge, 0.0, 1.0);

	// Corps cellulaire : coeur doux + halo.
	float node = exp(-f1 * f1 * 100.0) * (0.2 + 1.0 * fire) + 0.04 * exp(-f1 * 5.0);
	// Axone : filament sur la frontiere des cellules.
	float edge = 1.0 - smoothstep(0.0, 0.05, f2 - f1);
	float wire = edge * (0.2 + 0.5 * fire);

	return vec2(node, wire);
}

// Couleur du ciel pour une direction donnee.
vec3 neural_sky_color(vec3 eye) {
	float t = TIME - u_time_offset;

	// Lente derive : le ciel tourne doucement autour du zenith.
	float yaw = t * u_drift;
	vec3 dir = vec3(eye.x * cos(yaw) - eye.z * sin(yaw), eye.y, eye.x * sin(yaw) + eye.z * cos(yaw));

	// Fond : tissu cerebral diffus (2 octaves au lieu de 5 dans le fbm).
	float n1 = chrono_noise(dir.xy * 2.4 + vec2(dir.z * 3.1, t * 0.01));
	float n2 = chrono_noise(dir.xy * 5.0 + vec2(dir.z * 6.2, t * 0.02));
	float haze = n1 * 0.7 + n2 * 0.3;
	vec3 col = mix(u_deep_color.rgb, u_tissue_color.rgb, pow(haze, 2.2));

	// Toile neuronale unique (une seule passe Voronoi au lieu de deux).
	vec2 layer = neural_layer(dir, u_density, 3.0, t);

	vec3 hot = mix(u_neuron_color.rgb, u_fire_color.rgb, layer.y * 0.5);
	col += mix(u_neuron_color.rgb, u_fire_color.rgb, layer.x * 0.6) * layer.x * u_node_glow;
	col += hot * layer.y * u_wire_glow;

	return col;
}

void sky() {
	COLOR = neural_sky_color(normalize(EYEDIR));
}
