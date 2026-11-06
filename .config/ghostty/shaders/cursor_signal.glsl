// Gotham cursor: a soft halo drifting through the bat-signal colors —
// cursor-color (signal yellow) → palette 3 (window amber) → palette 1
// (red sky) and back, breathing gently — plus, on jumps, a smear (red at
// the tail → yellow at the head) and a quick, tight searchlight ring
// (yellow cooling to amber). Same mechanics as cursor_sunset.glsl (GTA VI).
// The halo only lights the background, never the characters next to the
// cursor, so text stays crisp. Colors come from the active theme.

const float GLOW_RADIUS   = 9.0;   // px, falloff of the halo
const float GLOW_STRENGTH = 0.55;
const float CYCLE         = 4.5;   // seconds for one yellow → amber → red loop
const float BREATHE       = 0.30;  // 0 = steady, 1 = fades fully in and out
const float BREATHE_TIME  = 2.2;   // seconds per breath
const float UNFOCUSED     = 0.35;  // halo strength when the window isn't focused
const float SMEAR_TIME    = 0.20;  // seconds for the smear to snap shut
const float SMEAR_OPACITY = 0.70;
const float JUMP_CELLS    = 1.5;   // only jumps longer than this many cells
const float RING_TIME     = 0.30;  // seconds for the searchlight ring
const float RING_REACH    = 28.0;  // px the ring travels outwards
const float RING_WIDTH    = 1.2;   // px
const float RING_OPACITY  = 0.45;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }
float easeOutCubic(float t) { return 1.0 - pow(1.0 - t, 3.0); }

vec2 cursorCenter(vec4 c) { return vec2(c.x + c.z * 0.5, c.y - c.w * 0.5); }

float sdBox(vec2 p, vec2 center, vec2 halfSize) {
    vec2 d = abs(p - center) - halfSize;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// Distance to the shape swept by a box of half-size hs moving from a to b;
// h = 0 at a, 1 at b.
float sdSweptBox(vec2 p, vec2 a, vec2 b, vec2 hs, out float h) {
    vec2 ba = b - a;
    h = clamp(dot(p - a, ba) / max(dot(ba, ba), 1e-4), 0.0, 1.0);
    return sdBox(p, a + ba * h, hs);
}

// Smooth loop through three colors.
vec3 signalCycle(float t) {
    float k = fract(t) * 3.0;
    vec3 a = iCursorColor, b = iPalette[3], c = iPalette[1];
    if (k < 1.0) return mix(a, b, smoothstep(0.0, 1.0, k));
    if (k < 2.0) return mix(b, c, smoothstep(0.0, 1.0, k - 1.0));
    return mix(c, a, smoothstep(0.0, 1.0, k - 2.0));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 base = texture(iChannel0, fragCoord / iResolution.xy);
    vec2 cur  = cursorCenter(iCurrentCursor);
    vec2 size = iCurrentCursor.zw;
    vec2 prev = cursorCenter(iPreviousCursor);
    vec3 color = base.rgb;
    float alpha = base.a;

    // Smear: the head reaches the target fast, the tail follows and snaps.
    float since = iTime - iTimeCursorChange;
    float t = clamp(since / SMEAR_TIME, 0.0, 1.0);
    bool jumped = length(cur - prev) > max(size.x, size.y) * JUMP_CELLS;
    if (jumped && t < 1.0) {
        vec2 head = mix(prev, cur, easeOutCubic(min(t * 2.0, 1.0)));
        vec2 tail = mix(prev, cur, easeOutCubic(t));
        float h;
        float d = sdSweptBox(fragCoord, tail, head, size * 0.5, h);
        float smear = (1.0 - smoothstep(-1.0, 1.0, d)) * SMEAR_OPACITY * (1.0 - t * t);
        vec3 smearCol = mix(iPalette[1], iCursorColor, smoothstep(0.0, 0.8, h));
        color = mix(color, smearCol, smear);
        alpha = max(alpha, smear);
    }

    // Searchlight ring sweeping out from the landing point, cooling to amber.
    if (jumped && since < RING_TIME) {
        float k = since / RING_TIME;
        float radius = max(size.x, size.y) * 0.6 + RING_REACH * easeOutCubic(k);
        float ring = 1.0 - smoothstep(0.0, RING_WIDTH, abs(length(fragCoord - cur) - radius));
        ring *= (1.0 - k) * RING_OPACITY;
        color = mix(color, mix(iCursorColor, iPalette[3], k), ring);
        alpha = max(alpha, ring);
    }

    float dBox = sdBox(fragCoord, cur, size * 0.5);
    float focus = iFocus > 0 ? 1.0 : UNFOCUSED;
    float breathe = 1.0 - BREATHE * (0.5 + 0.5 * sin(iTime * 6.2832 / BREATHE_TIME));
    // Halo around the cell, extended a few px so a thin bar still gets a body.
    float glow = exp(-max(dBox + 3.0, 0.0) / GLOW_RADIUS) * GLOW_STRENGTH * focus * breathe;
    glow *= step(0.0, dBox);                                  // not over the cursor itself
    glow *= 1.0 - smoothstep(0.08, 0.25, luma(base.rgb));     // not over characters

    color += signalCycle(iTime / CYCLE) * glow;
    fragColor = vec4(color, max(alpha, glow));
}
