#version 430

in vec2 vert;
in vec2 texCoord;
out vec2 uv;

void main(){
    uv=texCoord;
    gl_Position=vec4(vert,0.,1.);
}