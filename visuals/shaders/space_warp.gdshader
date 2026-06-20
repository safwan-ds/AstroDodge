shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform vec2 warp_origin = vec2(0.5, 0.5);
uniform float warp_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float warp_radius : hint_range(0.0, 1.0) = 0.35;
uniform float warp_amplitude : hint_range(0.0, 0.15) = 0.06;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 dir = uv - warp_origin;
	float dist = length(dir);
	float t = dist / warp_radius;
	
	// Expanding concentric rings — phase moves outward with intensity
	float rings = 4.0 + 2.0 * warp_intensity;
	float wave = sin(t * 6.2832 * rings - warp_intensity * 3.1416);
	
	// Gaussian envelope: strongest at center, smooth falloff
	float envelope = exp(-t * t * 3.0) * (1.0 - smoothstep(0.0, 1.2, t));
	
	float amount = wave * envelope * warp_intensity * warp_amplitude;
	
	vec2 distorted_uv = uv + normalize(dir) * amount;
	COLOR = texture(SCREEN_TEXTURE, distorted_uv);
}
