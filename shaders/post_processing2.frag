#version 330 core

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;

uniform sampler2D tex;

in vec2 uv;
out vec4 FragColor;


// Created by inigo quilez - iq/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

void main()
{
    vec2 q = uv.xy;
    q.y = 1 - q.y;
    vec2 fragCoord = 0.5 + (q-0.5)*(0.9 + 0.1*sin(0.2*u_time));

    vec3 oricol = texture( tex, vec2(q.x,1.0-q.y) ).xyz;
    vec3 col;

    col.r = texture(tex,vec2(fragCoord.x+0.003,-fragCoord.y)).x;
    col.g = texture(tex,vec2(fragCoord.x+0.000,-fragCoord.y)).y;
    col.b = texture(tex,vec2(fragCoord.x-0.003,-fragCoord.y)).z;

    col = clamp(col*0.5+0.5*col*col*1.2,0.0,1.0);

    col *= 0.5 + 0.5*16.0*fragCoord.x*fragCoord.y*(1.0-fragCoord.x)*(1.0-fragCoord.y);

    col *= vec3(0.95,1.05,0.95);

    col *= 0.9+0.1*sin(10.0*u_time+fragCoord.y*1000.0);

    col *= 0.99+0.01*sin(110.0*u_time);

    float comp = smoothstep( 0.2, 0.7, sin(u_time) );
    col = mix( col, oricol, clamp(-2.0+2.0*q.x+3.0*comp,0.0,1.0) );

    FragColor = vec4(col,1.0);
}