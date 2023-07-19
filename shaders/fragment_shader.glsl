#version 430

uniform sampler2D tex;

in vec2 uv;
out vec4 FragColor;

void main(){
    FragColor=vec4(
        texture(tex,uv).r*1.,
        texture(tex,uv).g*1.,
        texture(tex,uv).b*1.,
        1.
    );
}