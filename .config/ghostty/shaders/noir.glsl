// Gotham noir post-processing: red-sky haze, vignette, film grain.
// Text glow and exposure are off (they made characters hard to read).

const float TEXT_EXPOSURE   = 1.0;   // 1.0 = off (was 1.30); >1 brightens text, blooming it
const float BLOOM_THRESHOLD = 0.45;
const float BLOOM_STRENGTH  = 0.0;   // text glow off (was 0.45); the cursor glow lives in cursor_signal.glsl
const float BLOOM_RADIUS    = 2.5;   // px between taps
const vec3  SKY_RED         = vec3(0.55, 0.06, 0.07);
const float SKY_STRENGTH    = 0.14;  // 0.0 disables the red sky
const float SKY_FLOOR       = 0.35;  // share of the haze that reaches the bottom
const float VIGNETTE        = 0.06;
const float GRAIN           = 0.02;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 base = texture(iChannel0, uv);
    vec3 color = base.rgb;
    vec2 px = 1.0 / iResolution.xy;

    // Exposure: lift anything brighter than the background (i.e. text).
    color *= mix(1.0, TEXT_EXPOSURE, smoothstep(0.08, 0.30, luma(base.rgb)));

    // Glow: gather bright neighbours on two rings of 8 taps.
    vec3 bloom = vec3(0.0);
    for (int ring = 1; ring <= 2 && BLOOM_STRENGTH > 0.0; ring++) {
        for (int i = 0; i < 8; i++) {
            float a = 6.2831853 * (float(i) + 0.5 * float(ring)) / 8.0;
            vec2 off = vec2(cos(a), sin(a)) * BLOOM_RADIUS * float(ring) * px;
            vec3 s = texture(iChannel0, uv + off).rgb;
            bloom += s * smoothstep(BLOOM_THRESHOLD, 1.0, luma(s)) / float(ring);
        }
    }
    color += bloom / 12.0 * BLOOM_STRENGTH;

    // Red sky: a wash over the whole background, deepening toward the top
    // (Ghostty's fragCoord has y = 0 at the top). Painted only on empty
    // background so text keeps its full contrast.
    // Only on the see-through background, so cmd+shift+b (opaque) turns it off.
    float glass = 1.0 - smoothstep(0.97, 0.995, base.a);
    float textMask = (1.0 - smoothstep(0.08, 0.25, luma(base.rgb))) * glass;
    float sky = mix(SKY_FLOOR, 1.0, smoothstep(0.0, 1.0, 1.0 - uv.y)) * textMask;
    color += SKY_RED * sky * SKY_STRENGTH;

    // Vignette.
    vec2 c = uv - 0.5;
    color *= 1.0 - VIGNETTE * smoothstep(0.45, 1.0, dot(c, c) * 2.0);

    // Film grain, re-rolled ~24 times per second like a projector.
    float frame = floor(iTime * 24.0);
    color += (hash(fragCoord + frame * 17.0) - 0.5) * GRAIN * glass;

    fragColor = vec4(color, max(base.a, sky * SKY_STRENGTH));
}
