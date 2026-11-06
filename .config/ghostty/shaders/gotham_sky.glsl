// Gotham sky: an art-deco skyline, a pale moon, brick-built Batman and Joker minifigs flying
// across now and then (alone or in a chase), and a few bats in between. Painted only on empty background, so
// everything passes *behind* the text.

const float PERIOD             = 150.0; // seconds per appearance slot (bats fly halfway between)
const float PERIOD_JITTER      = 30.0;  // random delay within the slot -> every 2-3 minutes
const float GLIDE_TIME         = 14.0;  // seconds for the glider to cross the window
const float BAT_TIME           = 9.0;
const float FIGURE_SIZE        = 60.0;  // px, half the cape's span (minifig is ~0.9x this tall)
const float BAT_SIZE           = 9.0;   // px, half wingspan of the bats
const float FIGURE_OPACITY     = 0.95;
const float CHASE_LAG          = 0.12;  // how far Batman trails the Joker in a chase
const vec3  SILHOUETTE         = vec3(0.012, 0.010, 0.016);
const float SILHOUETTE_OPACITY = 0.9;
const vec3  MOON_COLOR         = vec3(0.20, 0.16, 0.11);
const float MOON_RADIUS        = 0.09;  // fraction of window height, 0.0 hides it
const float SKYLINE_HEIGHT     = 0.65;  // scales both rows of towers, 0.0 hides the city
const float CITY_OPACITY       = 0.5;  // how solid the towers are (1.0 = fully opaque)
const vec3  CITY_FAR           = vec3(0.105, 0.035, 0.045);  // towers lost in the red smog
const vec3  CITY_NEAR          = vec3(0.020, 0.018, 0.026);
const vec3  WINDOW_LIGHT       = vec3(0.300, 0.200, 0.065);
const vec3  BEACON             = vec3(0.900, 0.120, 0.100);

// Minifig palette.
const vec3 COWL   = vec3(0.075, 0.075, 0.090);
const vec3 SUIT   = vec3(0.250, 0.250, 0.280);
const vec3 LEGS   = vec3(0.110, 0.110, 0.130);
const vec3 YELLOW = vec3(0.960, 0.780, 0.180);  // classic minifig face
const vec3 BELT   = vec3(0.900, 0.680, 0.120);
const vec3 WHITE  = vec3(0.940, 0.940, 0.920);
const vec3 PURPLE = vec3(0.420, 0.200, 0.620);
const vec3 PLUM   = vec3(0.290, 0.130, 0.430);
const vec3 GREEN  = vec3(0.300, 0.700, 0.250);
const vec3 HAIR   = vec3(0.220, 0.600, 0.200);
const vec3 ORANGE = vec3(0.950, 0.500, 0.120);
const vec3 RED    = vec3(0.850, 0.100, 0.150);

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }
float hash11(float n) { return fract(sin(n * 127.1) * 43758.5453); }
mat2 rot(float a) { float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

float sdBox(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}
float sdRoundBox(vec2 p, vec2 b, float r) { return sdBox(p, b - r) - r; }
float sdSegment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    return length(pa - ba * clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0));
}

// Signed "inside" measure (> 0 inside) of a scalloped bat wing pair.
float wings(vec2 p, float flap) {
    float x = abs(p.x);
    float top = 0.08 + 0.30 * pow(x, 1.4) + 0.25 * flap * x * x;
    float bottom = top - (0.42 * (1.0 - x) + 0.10) + 0.10 * abs(sin(x * 9.42));
    return min(min(top - p.y, p.y - bottom), 1.0 - x);
}

// Plain flying bat: wings, body, head, ears.
float batShape(vec2 p, float flap, float aa) {
    if (dot(p, p) > 2.0) return 0.0;
    float x = abs(p.x);
    float d = wings(p, flap);
    d = max(d, (1.0 - length(p / vec2(0.13, 0.30))) * 0.13);
    d = max(d, 0.10 - length(p - vec2(0.0, 0.26)));
    d = max(d, min(0.47 - 3.0 * abs(x - 0.07) - p.y, p.y - 0.28));
    return smoothstep(0.0, aa, d);
}

// Paint a layer: sd < 0 inside.
void layer(inout vec4 acc, vec3 col, float sd, float aa) {
    float m = 1.0 - smoothstep(-aa, aa, sd);
    acc = vec4(mix(acc.rgb, col, m), max(acc.a, m));
}

// Brick-built caped crusader, gliding with the cape held out.
// Returns rgb + coverage in a.
vec4 minifig(vec2 p, float ripple, float legSwing, float aa) {
    vec4 acc = vec4(0.0);
    if (dot(p, p) > 2.0) return acc;
    float x = abs(p.x);

    // Cape, behind everything.
    layer(acc, COWL, -wings(p - vec2(0.0, 0.07), ripple), aa);

    // Legs kick alternately (seen from the front, a minifig's hip swing
    // reads as each leg lifting and dropping).
    float kick = sign(p.x) * legSwing;
    layer(acc, LEGS, sdBox(vec2(x - 0.078, p.y + 0.36 - kick), vec2(0.072, 0.16)), aa);
    layer(acc, LEGS * 0.8, sdBox(p - vec2(0.0, -0.18), vec2(0.155, 0.035)), aa);

    // Tapered torso with chest emblem and utility belt.
    float ty = clamp((p.y + 0.14) / 0.30, 0.0, 1.0);
    float torso = max(x - mix(0.155, 0.105, ty), abs(p.y - 0.01) - 0.15);
    layer(acc, SUIT, torso, aa);
    layer(acc, BELT, (length((p - vec2(0.0, 0.07)) / vec2(0.075, 0.045)) - 1.0) * 0.045, aa);
    acc.rgb = mix(acc.rgb, COWL, batShape((p - vec2(0.0, 0.062)) / 0.062, 0.0, aa / 0.062));
    layer(acc, BELT, sdBox(p - vec2(0.0, -0.115), vec2(0.15, 0.025)), aa);

    // Arms reaching out to hold the cape, C-shaped claw hands.
    layer(acc, SUIT, sdSegment(vec2(x, p.y), vec2(0.12, 0.12), vec2(0.27, 0.19)) - 0.04, aa);
    vec2 hp = vec2(x, p.y) - vec2(0.30, 0.21);
    float claw = abs(length(hp) - 0.032) - 0.016;
    claw = max(claw, -sdBox(rot(-0.6) * hp - vec2(0.03, 0.0), vec2(0.03, 0.015)));
    layer(acc, COWL, claw, aa);

    // Head: yellow face, cowl over the top with white eye slits, pointed ears.
    layer(acc, YELLOW, sdRoundBox(p - vec2(0.0, 0.28), vec2(0.085, 0.11), 0.035), aa);
    float cowl = max(sdRoundBox(p - vec2(0.0, 0.28), vec2(0.088, 0.112), 0.035), 0.245 - p.y);
    cowl = min(cowl, sdBox(vec2(x - 0.075, p.y - 0.24), vec2(0.013, 0.05)));
    layer(acc, COWL, cowl, aa);
    layer(acc, COWL, -min(0.48 - 2.6 * abs(x - 0.055) - p.y, p.y - 0.36), aa);
    layer(acc, WHITE, sdBox(vec2(x - 0.035, p.y - 0.30), vec2(0.022, 0.009)), aa);
    layer(acc, COWL, sdBox(p - vec2(0.0, 0.205), vec2(0.03, 0.006)), aa);

    // Plastic shading: light from the top-left plus two specular glints.
    acc.rgb *= 0.82 + 0.3 * clamp(0.5 - p.x * 1.2 + p.y * 0.6, 0.0, 1.0);
    float glint = exp(-dot(p - vec2(-0.045, 0.34), p - vec2(-0.045, 0.34)) / 0.0006)
                + exp(-dot(p - vec2(-0.07, 0.10), p - vec2(-0.07, 0.10)) / 0.0008);
    acc.rgb += vec3(0.35) * glint * acc.a;
    return acc;
}

// Brick-built Joker, floating under a bunch of balloons.
vec4 jokerFig(vec2 p, float sway, float legSwing, float aa) {
    vec4 acc = vec4(0.0);
    if (dot(p, p) > 2.2) return acc;
    float x = abs(p.x);

    // Balloons on strings, swaying, behind everything.
    for (int i = 0; i < 3; i++) {
        float fi = float(i) - 1.0;
        vec2 c = vec2(fi * 0.17 + sway * 0.25, 0.80 - abs(fi) * 0.08);
        vec2 hand = vec2(fi > 0.5 ? 0.30 : -0.30, 0.21);
        layer(acc, vec3(0.75), sdSegment(p, hand, c - vec2(0.0, 0.125)) - 0.004, aa);
        vec3 col = i == 0 ? PURPLE : (i == 1 ? GREEN : ORANGE);
        layer(acc, col, (length((p - c) / vec2(0.10, 0.125)) - 1.0) * 0.10, aa);
        layer(acc, col * 0.8, sdBox(p - c + vec2(0.0, 0.13), vec2(0.015, 0.012)), aa);
        float shine = exp(-dot(p - c - vec2(-0.03, 0.05), p - c - vec2(-0.03, 0.05)) / 0.0005);
        acc.rgb += vec3(0.4) * shine;
    }

    // Legs kick alternately, like Batman's.
    float kick = sign(p.x) * legSwing;
    layer(acc, PURPLE, sdBox(vec2(x - 0.078, p.y + 0.36 - kick), vec2(0.072, 0.16)), aa);
    layer(acc, PLUM, sdBox(p - vec2(0.0, -0.18), vec2(0.155, 0.035)), aa);

    // Purple jacket over a green vest, orange bow tie.
    float ty = clamp((p.y + 0.14) / 0.30, 0.0, 1.0);
    float torso = max(x - mix(0.155, 0.105, ty), abs(p.y - 0.01) - 0.15);
    layer(acc, PURPLE, torso, aa);
    layer(acc, GREEN, max(torso, x - 0.05), aa);
    layer(acc, PLUM, max(torso, abs(x - 0.05) - 0.006), aa);
    layer(acc, ORANGE, length(vec2(x - 0.024, (p.y - 0.135) * 1.4)) - 0.022, aa);
    layer(acc, ORANGE * 0.8, length(p - vec2(0.0, 0.135)) - 0.011, aa);

    // Arms up holding the balloon strings, white-gloved claw hands.
    layer(acc, PURPLE, sdSegment(vec2(x, p.y), vec2(0.12, 0.12), vec2(0.27, 0.19)) - 0.04, aa);
    vec2 hp = vec2(x, p.y) - vec2(0.30, 0.21);
    float claw = abs(length(hp) - 0.032) - 0.016;
    claw = max(claw, -sdBox(rot(-0.6) * hp - vec2(0.03, 0.0), vec2(0.03, 0.015)));
    layer(acc, WHITE, claw, aa);

    // Head: white face, slicked green hair, black eyes, wide red grin.
    layer(acc, WHITE, sdRoundBox(p - vec2(0.0, 0.28), vec2(0.085, 0.11), 0.035), aa);
    float hair = max(sdRoundBox(p - vec2(0.0, 0.28), vec2(0.09, 0.114), 0.035), 0.335 - p.y);
    hair = min(hair, sdBox(vec2(x - 0.078, p.y - 0.33), vec2(0.012, 0.04)));
    hair = min(hair, length(p - vec2(0.03, 0.39)) - 0.055);
    layer(acc, HAIR, hair, aa);
    layer(acc, HAIR * 0.7, sdBox(rot(0.35 * sign(p.x)) * vec2(x - 0.035, p.y - 0.315), vec2(0.022, 0.005)), aa);
    layer(acc, COWL, (length((vec2(x, p.y) - vec2(0.035, 0.29)) / vec2(0.012, 0.016)) - 1.0) * 0.012, aa);
    float grin = abs(length(p - vec2(0.0, 0.275)) - 0.062) - 0.011;
    layer(acc, RED, max(grin, p.y - 0.255), aa);

    // Plastic shading, same light as Batman.
    acc.rgb *= 0.82 + 0.3 * clamp(0.5 - p.x * 1.2 + p.y * 0.6, 0.0, 1.0);
    float glint = exp(-dot(p - vec2(-0.045, 0.34), p - vec2(-0.045, 0.34)) / 0.0006);
    acc.rgb += vec3(0.30) * glint * acc.a;
    return acc;
}

// One row of art-deco towers: a base block, a setback, an optional crown and
// spire, lit windows and a red beacon on the spires. Returns coverage;
// light gets the window/beacon glow (already coloured).
float skyline(vec2 fc, vec2 res, float cellW, float minH, float maxH, float seed,
              float windows, out vec3 light) {
    light = vec3(0.0);
    float cell = floor(fc.x / cellW);
    float lx = fc.x - (cell + 0.5) * cellW;
    float ax = abs(lx);
    float h1 = hash11(cell * 1.31 + seed);
    float h2 = hash11(cell * 2.17 + seed + 4.0);
    float h3 = hash11(cell * 3.71 + seed + 9.0);
    float h = res.y * mix(minH, maxH, h1) * SKYLINE_HEIGHT;
    float hw = cellW * mix(0.30, 0.46, h2);
    if (h < 1.0) return 0.0;

    // Base, setback, crown.
    float sd = sdBox(vec2(lx, fc.y - h * 0.5), vec2(hw, h * 0.5));
    float h2top = h * 1.10;
    sd = min(sd, sdBox(vec2(lx, fc.y - h2top * 0.5), vec2(hw * 0.70, h2top * 0.5)));
    float crown = h * 1.18;
    if (h3 > 0.35) sd = min(sd, sdBox(vec2(lx, fc.y - crown * 0.5), vec2(hw * 0.40, crown * 0.5)));
    float cover = 1.0 - smoothstep(-0.5, 0.5, sd);

    // Spire.
    float top = h3 > 0.35 ? crown : h2top;
    float spireLen = h * 0.16;
    if (h3 > 0.6) {
        float sp = min(min(3.0 * (1.0 - (fc.y - top) / spireLen) - ax, fc.y - top), top + spireLen - fc.y);
        cover = max(cover, smoothstep(0.0, 1.0, sp));
        float beacon = 1.0 - smoothstep(1.0, 2.5, length(vec2(lx, fc.y - top - spireLen)));
        light += BEACON * beacon;
    }

    // Window grid on the base block, a few of them lit.
    if (windows > 0.0 && ax < hw - 4.0 && fc.y < h - 6.0) {
        vec2 wid = floor(vec2(lx + hw, fc.y) / vec2(9.0, 13.0));
        vec2 wp = mod(vec2(lx + hw, fc.y), vec2(9.0, 13.0));
        float pane = step(3.0, wp.x) * step(wp.x, 7.0) * step(4.0, wp.y) * step(wp.y, 10.0);
        float on = step(0.84, hash11(cell * 91.7 + wid.x * 7.3 + wid.y * 3.1 + seed));
        light += WINDOW_LIGHT * windows * pane * on;
    }
    return cover;
}

// Smooth random flight path: enters through one edge, swoops through two
// random points inside the window, and exits through a different edge.
// Works in y-up pixel space; t in [0, 1] is eased in and out.
vec2 edgePoint(float side, float along, vec2 res, float margin) {
    if (side < 1.0) return vec2(-margin, along * res.y);
    if (side < 2.0) return vec2(res.x + margin, along * res.y);
    if (side < 3.0) return vec2(along * res.x, res.y + margin);
    return vec2(along * res.x, -margin);
}

void flightPath(float seed, float t, vec2 res, float margin, out vec2 pos, out vec2 vel) {
    float s0 = floor(hash11(seed) * 4.0);
    float s1 = mod(s0 + 1.0 + floor(hash11(seed + 1.0) * 3.0), 4.0);
    vec2 a = edgePoint(s0, mix(0.15, 0.85, hash11(seed + 2.0)), res, margin);
    vec2 d = edgePoint(s1, mix(0.15, 0.85, hash11(seed + 3.0)), res, margin);
    vec2 b = res * mix(vec2(0.15), vec2(0.85), vec2(hash11(seed + 4.0), hash11(seed + 5.0)));
    vec2 c = res * mix(vec2(0.15), vec2(0.85), vec2(hash11(seed + 6.0), hash11(seed + 7.0)));
    float e = t * t * t * (t * (t * 6.0 - 15.0) + 10.0);  // smootherstep ease in-out
    float u = 1.0 - e;
    pos = u * u * u * a + 3.0 * u * u * e * b + 3.0 * u * e * e * c + e * e * e * d;
    vel = 3.0 * u * u * (b - a) + 6.0 * u * e * (c - b) + 3.0 * e * e * (d - c);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 base = texture(iChannel0, uv);
    vec2 res = iResolution.xy;
    // Ghostty's fragCoord has y = 0 at the top; draw in y-up space instead.
    vec2 fc = vec2(fragCoord.x, res.y - fragCoord.y);
    // Gotham only lives on the see-through background: toggling the window
    // opaque (toggle_background_opacity, cmd+shift+b) hides all of it.
    float glass = 1.0 - smoothstep(0.97, 0.995, base.a);
    float background = (1.0 - smoothstep(0.08, 0.25, luma(base.rgb))) * glass;
    vec3 color = base.rgb;

    // Moon with a soft halo, tucked into the top-right corner.
    float r = res.y * MOON_RADIUS;
    float moonDist = length(fc - (res - vec2(r * 1.9)));
    float moon = MOON_RADIUS > 0.0 ? 1.0 - smoothstep(r - 1.5, r + 1.5, moonDist) : 0.0;
    float halo = MOON_RADIUS > 0.0 ? exp(-max(moonDist - r, 0.0) / (r * 0.7)) * 0.25 : 0.0;
    color += MOON_COLOR * max(moon, halo) * background;

    // Gotham skyline: hazy far row, dark near row with lit windows.
    vec3 farLight, nearLight;
    float far = skyline(fc, res, 52.0, 0.14, 0.34, 3.0, 0.35, farLight);
    float near = skyline(fc + vec2(23.0, 0.0), res, 74.0, 0.07, 0.22, 11.0, 1.0, nearLight);
    far *= CITY_OPACITY;
    near *= CITY_OPACITY;
    color = mix(color, CITY_FAR, far * background) + farLight * CITY_OPACITY * background;
    color = mix(color, CITY_NEAR, near * background) + nearLight * CITY_OPACITY * background;
    float city = max(far, near) * background;

    // A small flock of bats, halfway between glides, sharing one random path.
    float sil = 0.0;
    float flock = floor((iTime + PERIOD * 0.5) / PERIOD);
    float tb = mod(iTime + PERIOD * 0.5, PERIOD) - hash11(flock + 71.0) * PERIOD_JITTER;
    if (tb >= 0.0 && tb < BAT_TIME) {
        for (int i = 0; i < 5; i++) {
            float fi = float(i);
            float delay = hash11(flock * 13.0 + fi) * 2.0;
            float prog = (tb - delay) / (BAT_TIME - 2.0);
            if (prog < 0.0 || prog > 1.0) continue;
            vec2 pos, vel;
            flightPath(flock * 29.0 + 100.0, prog, res, BAT_SIZE * 2.0 + 50.0, pos, vel);
            pos += (vec2(hash11(fi * 3.7 + flock), hash11(fi * 5.3 + flock)) - 0.5) * 70.0;
            pos.y += sin(iTime * 3.0 + fi * 1.7) * 8.0;
            float size = BAT_SIZE * (0.8 + 0.5 * hash11(fi + 2.0));
            vec2 p = (fc - pos) / size;
            sil = max(sil, batShape(p, sin(iTime * 14.0 + fi * 2.1), 1.5 / size));
        }
    }
    color = mix(color, SILHOUETTE, sil * SILHOUETTE_OPACITY * background);
    float cover = max(city, sil * SILHOUETTE_OPACITY);

    // The minifigs: each pass is Batman alone, the Joker alone, or a chase
    // (Joker in front, Batman on the same path just behind). Random eased
    // swoop, banking into the turns.
    float cycle = floor(iTime / PERIOD);
    float t = mod(iTime, PERIOD) - hash11(cycle + 51.0) * PERIOD_JITTER;
    float scene = hash11(cycle + 31.0);
    bool chase = scene >= 0.66;
    bool showJoker = scene >= 0.33;
    bool showBatman = scene < 0.33 || chase;
    float aa = 1.0 / FIGURE_SIZE;
    vec2 pos, vel;

    float pj = t / GLIDE_TIME;
    if (showJoker && pj >= 0.0 && pj <= 1.0) {
        flightPath(cycle * 17.0, pj, res, FIGURE_SIZE * 1.3, pos, vel);
        vec2 p = rot(-0.35 * vel.x / max(length(vel), 1.0)) * ((fc - pos) / FIGURE_SIZE);
        vec4 fig = jokerFig(p, sin(iTime * 1.7), 0.035 * sin(iTime * 3.4), aa);
        float m = fig.a * FIGURE_OPACITY * background;
        color = mix(color, fig.rgb, m);
        cover = max(cover, m);
    }

    float pb = chase ? pj - CHASE_LAG : pj;
    if (showBatman && pb >= 0.0 && pb <= 1.0) {
        flightPath(cycle * 17.0, pb, res, FIGURE_SIZE * 1.3, pos, vel);
        vec2 p = rot(-0.35 * vel.x / max(length(vel), 1.0)) * ((fc - pos) / FIGURE_SIZE);
        vec4 fig = minifig(p, 0.18 * sin(iTime * 2.2), 0.035 * sin(iTime * 3.0), aa);
        float m = fig.a * FIGURE_OPACITY * background;
        color = mix(color, fig.rgb, m);
        cover = max(cover, m);
    }

    fragColor = vec4(color, max(base.a, max(cover, moon * background)));
}
