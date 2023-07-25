#version 330 core

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform float glitch_intensity;

uniform sampler2D tex;

in vec2 uv;
out vec4 FragColor;


float NoiseSeed;
float randomFloat(){
  NoiseSeed = sin(NoiseSeed) * 84522.13219145687;
  return fract(NoiseSeed);
}

float SCurve (float value, float amount, float correction) {

	float curve = 1.0; 

    if (value < 0.5)
    {

        curve = pow(value, amount) * pow(2.0, amount) * 0.5; 
    }
        
    else
    { 	
    	curve = 1.0 - pow(1.0 - value, amount) * pow(2.0, amount) * 0.5; 
    }

    return pow(curve, correction);
}

//ACES tonemapping from: https://www.shadertoy.com/view/wl2SDt
vec3 ACESFilm(vec3 x)
{
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return (x*(a*x+b))/(x*(c*x+d)+e);
}

//Chromatic Abberation from: https://www.shadertoy.com/view/XlKczz
vec3 chromaticAbberation(sampler2D tex, vec2 uv, float amount)
{
    float aberrationAmount = amount/10.0;
   	vec2 distFromCenter = uv - 0.5;

    // stronger aberration near the edges by raising to power 3
    vec2 aberrated = aberrationAmount * pow(distFromCenter, vec2(3.0, 3.0));
    
    vec3 color = vec3(0.0);
    
    for (int i = 1; i <= 8; i++)
    {
        float weight = 1.0 / pow(2.0, float(i));
        color.r += texture(tex, uv - float(i) * aberrated).r * weight;
        color.b += texture(tex, uv + float(i) * aberrated).b * weight;
    }
    
    color.g = texture(tex, uv).g * 0.9961; // 0.9961 = weight(1)+weight(2)+...+weight(8);
    
    return color;
}

//film grain from: https://www.shadertoy.com/view/wl2SDt
vec3 filmGrain()
{
    return vec3(0.9 + randomFloat()*0.15);
}

//Sigmoid Contrast from: https://www.shadertoy.com/view/MlXGRf
vec3 contrast(vec3 color)
{
    return vec3(SCurve(color.r, 3.0, 1.0), 
                SCurve(color.g, 4.0, 0.7), 
                SCurve(color.b, 2.6, 0.6)
               );
}

//anamorphic-ish flares from: https://www.shadertoy.com/view/MlsfRl
vec3 flares(sampler2D tex, vec2 uv, float threshold, float intensity, float stretch, float brightness)
{
    threshold = 1.0 - threshold;
    
    vec3 hdr = texture(tex, uv).rgb;
    hdr = vec3(floor(threshold+pow(hdr.r, 1.0)));
    
    float d = intensity; //200.;
    float c = intensity*stretch; //100.;
    
    
    //horizontal
    for (float i=c; i>-1.0; i--)
    {
        float texL = texture(tex, uv+vec2(i/d, 0.0)).r;
        float texR = texture(tex, uv-vec2(i/d, 0.0)).r;
        hdr += floor(threshold+pow(max(texL,texR), 4.0))*(1.0-i/c);
    }
    
    //vertical
    for (float i=c/2.0; i>-1.0; i--)
    {
        float texU = texture(tex, uv+vec2(0.0, i/d)).r;
        float texD = texture(tex, uv-vec2(0.0, i/d)).r;
        hdr += floor(threshold+pow(max(texU,texD), 40.0))*(1.0-i/c) * 0.25;
    }
    
    hdr *= vec3(0.5,0.4,1.0); //tint
    
	return hdr*brightness;
}

//glow from: https://www.shadertoy.com/view/XslGDr (unused but useful)
vec3 samplef(vec2 tc);
vec3 blur(vec2 tc, float offs);
vec3 highlights(vec3 pixel, float thres);

vec3 glow()
{
	vec2 tc = uv.xy;
	vec3 color = blur(tc, 2.0);
	color += blur(tc, 3.0);
	color += blur(tc, 5.0);
	color += blur(tc, 7.0);
	color /= 3.0;
	
	// color += samplef(tc);
	
	float div_pos = u_mouse.x / u_resolution.x;
	if(u_mouse.x < 2.0) {
		div_pos = 0.5;
	}
    // vec3 image = texture(tex, uv).rgb;
	return mix(samplef(tc), color, 1.0);
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


//margins from: https://www.shadertoy.com/view/wl2SDt
vec3 margins(vec3 color, vec2 uv, float marginSize)
{
    if(uv.y < marginSize || uv.y > 1.0-marginSize)
    {
        return vec3(0.0);
    }else{
        return color;
    }
}

float sat( float t ) {
	return clamp( t, 0.0, 1.0 );
}

vec2 sat( vec2 t ) {
	return clamp( t, 0.0, 1.0 );
}

//remaps inteval [a;b] to [0;1]
float remap  ( float t, float a, float b ) {
	return sat( (t - a) / (b - a) );
}

//note: /\ t=[0;0.5;1], y=[0;1;0]
float linterp( float t ) {
	return sat( 1.0 - abs( 2.0*t - 1.0 ) );
}

vec3 spectrum_offset( float t ) {
    float t0 = 3.0 * t - 1.5;
    //return vec3(1.0/3.0);
	return clamp( vec3( -t0, 1.0-abs(t0), t0), 0.0, 1.0);
    /*
	vec3 ret;
	float lo = step(t,0.5);
	float hi = 1.0-lo;
	float w = linterp( remap( t, 1.0/6.0, 5.0/6.0 ) );
	float neg_w = 1.0-w;
	ret = vec3(lo,1.0,hi) * vec3(neg_w, w, neg_w);
	return pow( ret, vec3(1.0/2.2) );
*/
}

//note: [0;1]
float rand( vec2 n ) {
  return fract(sin(dot(n.xy, vec2(12.9898, 78.233)))* 43758.5453);
}

//note: [-1;1]
float srand( vec2 n ) {
	return rand(n) * 2.0 - 1.0;
}

float mytrunc( float x, float num_levels )
{
	return floor(x*num_levels) / num_levels;
}
vec2 mytrunc( vec2 x, float num_levels )
{
	return floor(x*num_levels) / num_levels;
}

vec3 glitch()
{
    float aspect = u_resolution.x / u_resolution.y;
    vec2 uv = uv;
    // uv.y = 1.0 - uv.y;
	
	float time = mod(u_time, 32.0); // + modelmat[0].x + modelmat[0].z;

	float GLITCH = glitch_intensity / 2.0;
	
    // float rdist = length( (uv - vec2(0.5,0.5))*vec2(aspect, 1.0) )/1.4;
    // GLITCH *= rdist;
    
	float gnm = sat( GLITCH );
	float rnd0 = rand( mytrunc( vec2(time, time), 6.0 ) );
	float r0 = sat((1.0-gnm)*0.7 + rnd0);
	float rnd1 = rand( vec2(mytrunc( uv.x, 10.0*r0 ), time) ); //horz
	//float r1 = 1.0f - sat( (1.0f-gnm)*0.5f + rnd1 );
	float r1 = 0.5 - 0.5 * gnm + rnd1;
	r1 = 1.0 - max( 0.0, ((r1<1.0) ? r1 : 0.9999999) ); //note: weird ass bug on old drivers
	float rnd2 = rand( vec2(mytrunc( uv.y, 40.0*r1 ), time) ); //vert
	float r2 = sat( rnd2 );

	float rnd3 = rand( vec2(mytrunc( uv.y, 10.0*r0 ), time) );
	float r3 = (1.0-sat(rnd3+0.8)) - 0.1;

	float pxrnd = rand( uv + time );

	float ofs = 0.05 * r2 * GLITCH * ( rnd0 > 0.5 ? 1.0 : -1.0 );
	ofs += 0.5 * pxrnd * ofs;

	uv.y += 0.1 * r3 * GLITCH;

    const int NUM_SAMPLES = 5;
    const float RCP_NUM_SAMPLES_F = 1.0 / float(NUM_SAMPLES);
    
	vec4 sum = vec4(0.0);
	vec3 wsum = vec3(0.0);
	for( int i=0; i<NUM_SAMPLES; ++i )
	{
		float t = float(i) * RCP_NUM_SAMPLES_F;
		uv.x = sat( uv.x + ofs * t );
		vec4 sampleimagecol = texture( tex, uv, -10.0 );
		vec3 s = spectrum_offset( t );
		sampleimagecol.rgb = sampleimagecol.rgb * s;
		sum += sampleimagecol;
		wsum += s;
	}
	sum.rgb /= wsum;
	sum.a *= RCP_NUM_SAMPLES_F;

    //FragColor = vec4( sum.bbb, 1.0 ); return;
    vec3 final;
	// final.a = sum.a;
	final.rgb = sum.rgb; // * outcol0.a;
    return final;
}


void main() {    
    vec3 color = glitch();


    // //chromatic abberation
    // vec3 color = chromaticAbberation(tex, uv, 0.2);
    
    //film grain
    color *= filmGrain();
    
    
    //ACES Tonemapping
    color = ACESFilm(color);
    
    
    //contrast
    color = contrast(color) * 0.9;
    
    //flare
    // color += flares(tex, uv, 0.9, 300.0, 0.1, 0.06);
    
	//glow
    color += glow();
    
    //margins
    // color = margins(color, uv, 0.1);
    

    //output
    FragColor = vec4(color, 1.0);
}