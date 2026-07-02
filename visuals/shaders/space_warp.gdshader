shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform vec2 warp_origins[8];
uniform float warp_intensities[8];
uniform float warp_radii[8];
uniform int warp_count;
uniform float warp_amplitude : hint_range(0.0, 0.15) = 0.06;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 total_offset = vec2(0.0);

	for (int i = 0; i < 8; i++) {
		if (i >= warp_count) {
			continue;
		}

		vec2 dir = uv - warp_origins[i];
		float dist = length(dir);
		float t = dist / warp_radii[i];

		// Expanding concentric rings — phase moves outward with intensity
		float rings = 4.0 + 2.0 * warp_intensities[i];
		float wave = sin(t * 6.2832 * rings - warp_intensities[i] * 3.1416);

		// Gaussian envelope: strongest at center, smooth falloff
		float envelope = exp(-t * t * 3.0) * (1.0 - smoothstep(0.0, 1.2, t));

		float amount = wave * envelope * warp_intensities[i] * warp_amplitude;
		total_offset += normalize(dir) * amount;
	}

	COLOR = texture(SCREEN_TEXTURE, uv + total_offset);
}
