#define Bayer4(a) (Bayer2(0.5 * a) * 0.25 + Bayer2(a))
#define Bayer8(a) (Bayer4(0.5 * a) * 0.25 + Bayer2(a))
#define FBM_OCTAVES 5
#define FBM_LACUNARITY 1.25
#define FBM_GAIN 1.0
#define FBM_SCALE 4.0
#define MAX_CLICKS 10
#define PIXEL_SIZE 4.0

uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uClickPosition[MAX_CLICKS];
uniform float uClickTimes[MAX_CLICKS];

out vec4 fragColor;

float Bayer2(vec2 a) {
    a = floor(a);
    return fract(a.x / 2.0 + a.y * a.y * 0.75);
}
float hash11(float n) {
    return fract(sin(n) * 43758.5453);
}
float vnoise(vec3 p) {
    vec3 ip = floor(p);
    vec3 fp = fract(p);
    float n000 = hash11(dot(ip + vec3(0.0, 0.0, 0.0), vec3(1.0, 57.0, 113.0)));
    float n100 = hash11(dot(ip + vec3(1.0, 0.0, 0.0), vec3(1.0, 57.0, 113.0)));
    float n010 = hash11(dot(ip + vec3(0.0, 1.0, 0.0), vec3(1.0, 57.0, 113.0)));
    float n110 = hash11(dot(ip + vec3(1.0, 1.0, 0.0), vec3(1.0, 57.0, 113.0)));
    float n001 = hash11(dot(ip + vec3(0.0, 0.0, 1.0), vec3(1.0, 57.0, 113.0)));
    float n101 = hash11(dot(ip + vec3(1.0, 0.0, 1.0), vec3(1.0, 57.0, 113.0)));
    float n011 = hash11(dot(ip + vec3(0.0, 1.0, 1.0), vec3(1.0, 57.0, 113.0)));
    float n111 = hash11(dot(ip + vec3(1.0, 1.0, 1.0), vec3(1.0, 57.0, 113.0)));
    vec3 w = fp * fp * fp * (fp * (fp * 6.0 - 15.0) + 10.0);
    float x00 = mix(n000, n100, w.x);
    float x10 = mix(n010, n110, w.x);
    float x01 = mix(n001, n101, w.x);
    float x11 = mix(n011, n111, w.x);
    float y0  = mix(x00, x10, w.y);
    float y1  = mix(x01, x11, w.y);
    return mix(y0, y1, w.z) * 2.0 - 1.0;
}
float fbm2(vec2 uv, float t) {
    vec3 p = vec3(uv * FBM_SCALE, t);
    float amp = 1.0;
    float freq = 1.0;
    float sum = 1.0;
    for (int i = 0; i < FBM_OCTAVES; ++i) {
        sum += amp * vnoise(p * freq);
        freq *= FBM_LACUNARITY;
        amp *= FBM_GAIN;
    }
    return sum * 0.5 + 0.5;
}
void main() {
    vec2 fragCoord = gl_FragCoord.xy - uResolution * 0.5;
    float aspectRatio = uResolution.x / uResolution.y;

    float cellPixelSize = 4.0 * PIXEL_SIZE;
    vec2 cellId = floor(fragCoord / cellPixelSize);
    vec2 cellCoord = cellId * cellPixelSize;

    vec2 uv = cellCoord / uResolution * vec2(aspectRatio, 1.0);
    float feed = fbm2(uv, uTime * 0.05);
    feed = feed * 0.5 - 0.65;

    const float speed = 0.5;
    const float thickness = 0.05;
    const float dampenTime = 2.0;
    const float dampenRadius = 12.0;

    for (int i = 0; i < MAX_CLICKS; ++i) {
        vec2 position = uClickPosition[i];
        if (position.x < 0.0) {
            continue;
        }
        float radius = distance(uv, (position - uResolution * 0.5 - cellPixelSize * 0.5) / uResolution * vec2(aspectRatio, 1.0));

        float time = max(uTime - uClickTimes[i], 0.0);
        float waveRadius = speed * time;

        float ring = exp(-pow((radius - waveRadius) / thickness, 2.0));
        float attenuation = exp(-dampenTime * time) * exp(-dampenRadius * radius);

        feed = max(feed, ring * attenuation);
    }
    fragColor = vec4(0.75, 0.75, 0.75, step(0.5, feed + Bayer8(fragCoord / PIXEL_SIZE) - 0.5));
}
