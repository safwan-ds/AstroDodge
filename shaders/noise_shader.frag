#version 330 core

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;

uniform sampler2D tex;

in vec2 uv;
out vec4 FragColor;

float random2d(vec2 coord){
    return fract(sin(dot(coord.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

float amount = 0.6;

void main(){
    vec2 coord = uv;

    vec4 image = texture(tex, coord);

    vec2 mouse = u_mouse / u_resolution;

    vec3 noise = vec3(random2d(coord * u_time + mouse) - 0.5) * amount;

    image.rgb += noise;

    FragColor = image;
}