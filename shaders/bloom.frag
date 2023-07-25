#version 330 core

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform float glitch_intensity;

uniform sampler2D tex;

in vec2 uv;
out vec4 FragColor;

vec3 samplef(vec2 tc);
vec3 blur(vec2 tc, float offs);
vec3 highlights(vec3 pixel, float thres);

void main()
{
	vec2 tc = uv.xy;
	vec3 color = blur(tc, 2.0);
	color += blur(tc, 3.0);
	color += blur(tc, 5.0);
	color += blur(tc, 7.0);
	color /= 3.0;
	
	color += samplef(tc);
	
	float div_pos = u_mouse.x / u_resolution.x;
	if(u_mouse.x < 2.0) {
		div_pos = 0.5;
	}
    // vec3 image = texture(tex, uv).rgb;
	FragColor.xyz = mix(samplef(tc), color, 1.0);
	FragColor.w = 1.0;
}

vec3 samplef(vec2 tc)
{
	float factor = 1.5;
	return pow(texture(tex, tc).xyz, vec3(factor, factor, factor));
}

vec3 hsample(vec2 tc)
{
	return highlights(samplef(tc), 0.6);
}

vec3 blur(vec2 tc, float offs)
{
	vec4 xoffs = offs * vec4(-2.0, -1.0, 1.0, 2.0) / u_resolution.x;
	vec4 yoffs = offs * vec4(-2.0, -1.0, 1.0, 2.0) / u_resolution.y;
	
	vec3 color = vec3(0.0, 0.0, 0.0);
	color += hsample(tc + vec2(xoffs.x, yoffs.x)) * 0.00366;
	color += hsample(tc + vec2(xoffs.y, yoffs.x)) * 0.01465;
	color += hsample(tc + vec2(    0.0, yoffs.x)) * 0.02564;
	color += hsample(tc + vec2(xoffs.z, yoffs.x)) * 0.01465;
	color += hsample(tc + vec2(xoffs.w, yoffs.x)) * 0.00366;
	
	color += hsample(tc + vec2(xoffs.x, yoffs.y)) * 0.01465;
	color += hsample(tc + vec2(xoffs.y, yoffs.y)) * 0.05861;
	color += hsample(tc + vec2(    0.0, yoffs.y)) * 0.09524;
	color += hsample(tc + vec2(xoffs.z, yoffs.y)) * 0.05861;
	color += hsample(tc + vec2(xoffs.w, yoffs.y)) * 0.01465;
	
	color += hsample(tc + vec2(xoffs.x, 0.0)) * 0.02564;
	color += hsample(tc + vec2(xoffs.y, 0.0)) * 0.09524;
	color += hsample(tc + vec2(    0.0, 0.0)) * 0.15018;
	color += hsample(tc + vec2(xoffs.z, 0.0)) * 0.09524;
	color += hsample(tc + vec2(xoffs.w, 0.0)) * 0.02564;
	
	color += hsample(tc + vec2(xoffs.x, yoffs.z)) * 0.01465;
	color += hsample(tc + vec2(xoffs.y, yoffs.z)) * 0.05861;
	color += hsample(tc + vec2(    0.0, yoffs.z)) * 0.09524;
	color += hsample(tc + vec2(xoffs.z, yoffs.z)) * 0.05861;
	color += hsample(tc + vec2(xoffs.w, yoffs.z)) * 0.01465;
	
	color += hsample(tc + vec2(xoffs.x, yoffs.w)) * 0.00366;
	color += hsample(tc + vec2(xoffs.y, yoffs.w)) * 0.01465;
	color += hsample(tc + vec2(    0.0, yoffs.w)) * 0.02564;
	color += hsample(tc + vec2(xoffs.z, yoffs.w)) * 0.01465;
	color += hsample(tc + vec2(xoffs.w, yoffs.w)) * 0.00366;

	return color;
}

vec3 highlights(vec3 pixel, float thres)
{
	float val = (pixel.x + pixel.y + pixel.z) / 0.1;
	return pixel * smoothstep(thres - 0.1, thres + 0.1, val);
}