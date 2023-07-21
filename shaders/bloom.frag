#version 330

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;

uniform sampler2D tex;

in vec2 uv;
out vec4 FragColor;

const int kernelSize = 9;
const float blurSize = 2.0 / 512.0;
const float intensity = 0.5;

// Gaussian kernel for 9x9 blur
const float kernel[kernelSize * kernelSize] = float[](
    1.0,  4.0,  6.0,  8.0,  10.0, 8.0,  6.0,  4.0,  1.0,
    4.0, 16.0, 24.0, 32.0, 40.0, 32.0, 24.0, 16.0, 4.0,
    6.0, 24.0, 36.0, 48.0, 60.0, 48.0, 36.0, 24.0, 6.0,
    8.0, 32.0, 48.0, 64.0, 80.0, 64.0, 48.0, 32.0, 8.0,
    10.0, 40.0, 60.0, 80.0, 100.0, 80.0, 60.0, 40.0, 10.0,
    8.0, 32.0, 48.0, 64.0, 80.0, 64.0, 48.0, 32.0, 8.0,
    6.0, 24.0, 36.0, 48.0, 60.0, 48.0, 36.0, 24.0, 6.0,
    4.0, 16.0, 24.0, 32.0, 40.0, 32.0, 24.0, 16.0, 4.0,
    1.0,  4.0,  6.0,  8.0,  10.0, 8.0,  6.0,  4.0,  1.0
);

void main()
{
    vec4 sum = vec4(0);

    // Apply Gaussian blur in both x and y directions
    for (int i = -kernelSize / 2; i <= kernelSize / 2; i++)
    {
        for (int j = -kernelSize / 2; j <= kernelSize / 2; j++)
        {
            vec2 offset = vec2(float(i), float(j)) * blurSize;
            sum += texture(tex, uv + offset) * kernel[(i + kernelSize / 2) * kernelSize + j + kernelSize / 2];
        }
    }

    // Normalize the sum by dividing with the sum of kernel weights
    sum /= 1024.0;

    // Adjust intensity and add original texture for mixing
    FragColor = sum * intensity + texture(tex, uv);
}
