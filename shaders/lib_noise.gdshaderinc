// Fonctions utilitaires partagées par les shaders du niveau (bruit procédural + projection monde).

float chrono_hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float chrono_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = chrono_hash12(cell);
	float b = chrono_hash12(cell + vec2(1.0, 0.0));
	float c = chrono_hash12(cell + vec2(0.0, 1.0));
	float d = chrono_hash12(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float chrono_fbm(vec2 p) {
	float total = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 5; i++) {
		total += chrono_noise(p) * amp;
		p *= 2.03;
		amp *= 0.5;
	}
	return total;
}

// Projection "triplanaire" : choisit l'axe le plus plat de la normale et renvoie
// les coordonnées monde correspondantes, pour obtenir un motif continu et sans
// étirement sur des boîtes de tailles très différentes (murs, sols, piliers).
vec2 chrono_plane(vec3 world_pos, vec3 world_normal) {
	vec3 an = abs(world_normal);
	if (an.y >= max(an.x, an.z)) {
		return world_pos.xz;
	} else if (an.x >= an.z) {
		return world_pos.zy;
	}
	return world_pos.xy;
}
