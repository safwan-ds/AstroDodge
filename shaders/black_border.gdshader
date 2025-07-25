shader_type canvas_item;

uniform float radius = 1.0;
uniform float speed : hint_range(0.0, 10.0) = 1.0;
uniform vec4 effect_color : source_color = vec4(0.251, 0.0, 0.0, 1.0);

float snoise(vec3 uv, float res)
{
    const vec3 s = vec3(1e0, 1e2, 1e3);
    uv *= res;

    vec3 uv0 = floor(mod(uv, res)) * s;
    vec3 uv1 = floor(mod(uv + vec3(1.0), res)) * s;

    vec3 f = fract(uv);
    f = f * f * (2.0 - 1.0 * f);

    vec4 v = vec4(uv0.x + uv0.y + uv0.z, uv1.x + uv0.y + uv0.z,
                  uv0.x + uv1.y + uv0.z, uv1.x + uv1.y + uv0.z);

    vec4 r = fract(sin(v * 1e-6) * 1e5);
    float r0 = mix(mix(r.x, r.y, f.x), mix(r.z, r.w, f.x), f.y);

    r = fract(sin((v + uv1.z - uv0.z) * 1e-3) * 1e-3);
    float r1 = mix(mix(r.x, r.y, f.x), mix(r.z, r.w, f.x), f.y);

    return mix(r0, r1, f.z) * 2.0 - 0.5;
}

void fragment()
{
    // Usar UV para escalar el efecto al ColorRect
    vec2 p = (UV - 0.5) * radius; // Normalizar a [-1, 1]

    float color = 4.0 - (3.0 * length(3.0 * p));

    vec3 coord = vec3(atan(p.x, p.y) / 6.2832 + 0.5, length(p) * 1.80, 0.5);

    float time = -TIME / speed;
    for (int i = 1; i <= 7; i++)
    {
        float power = pow(2.0, float(i));
        color += (1.5 / power) * snoise(coord + vec3(0.0, -time * 0.05, time * 0.01), power * 64.0);
    }

    // Ajustar transparencia: fuego transparente, bordes opacos
    float alpha = 1.0 - smoothstep(effect_color.a, 1.0, color);

    COLOR = vec4(color - (1.0 - effect_color.r), color - (1.0 - effect_color.g), color - (1.0 - effect_color.b), alpha);
}
