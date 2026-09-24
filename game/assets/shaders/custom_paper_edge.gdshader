shader_type canvas_item;
render_mode unshaded;

// The source is the complete posed fighter, rendered once into a transparent
// viewport. Expanding its combined alpha creates one external paper edge.
uniform float edge_pixels = 8.0;
uniform float edge_opacity = 0.98;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	if (edge_pixels <= 0.0 || edge_opacity <= 0.0) {
		COLOR = source;
	} else if (source.a > 0.02) {
		COLOR = source;
	} else {
		vec2 radius = TEXTURE_PIXEL_SIZE * edge_pixels;
		float neighbor = 0.0;
		float enclosed_joint = 0.0;
		// Four axes sample all eight directions. Reusing each opposite pair to
		// recognize an interior limb gap cuts the former 20 texture reads down
		// to 8 for every transparent pixel.
		for (int i = 0; i < 4; i++) {
			float angle = float(i) * 0.7853981634;
			vec2 direction = vec2(cos(angle), sin(angle));
			float near_a = texture(TEXTURE, UV + direction * radius).a;
			float near_b = texture(TEXTURE, UV - direction * radius).a;
			neighbor = max(neighbor, max(near_a, near_b));
			enclosed_joint = max(enclosed_joint, step(0.12, near_a) * step(0.12, near_b));
		}
		COLOR = vec4(1.0, 0.99, 0.96, step(0.12, neighbor) * (1.0 - enclosed_joint) * edge_opacity);
	}
}
