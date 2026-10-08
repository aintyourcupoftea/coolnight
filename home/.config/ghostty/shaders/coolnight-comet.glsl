// ╔══════════════════════════════════════════════════════════════════════╗
// ║  coolnight comet · neon cursor effects for Ghostty 1.3               ║
// ║                                                                      ║
// ║  smear   when the cursor jumps, its four corners race to the new     ║
// ║          cell at different speeds (leading edge snaps, trailing      ║
// ║          edge lags), leaving a comet that fades cursor-green → cyan  ║
// ║  beacon  a quick neon ripple around the cursor whenever a window or  ║
// ║          split gains focus, so you can spot it in a tiled layout     ║
// ║                                                                      ║
// ║  Every pixel outside those brief effects is passed through as-is:    ║
// ║  the background image, opacity and blur are never touched.           ║
// ╚══════════════════════════════════════════════════════════════════════╝

// ─── Tunables ───────────────────────────────────────────────────────────
#define DURATION         0.20  // s until the tail catches up with the cursor
#define LEAD_DURATION    0.05  // s until the leading edge lands
#define MIN_JUMP_CELLS   1.5   // shorter moves (plain typing) leave no trail
#define HEAD_ALPHA       0.85  // trail opacity right behind the cursor
#define TAIL_ALPHA       0.06  // trail opacity at its far end
#define GLOW_ALPHA       0.40  // neon halo around the trail (0 = off)
#define GLOW_CELLS       0.45  // halo reach, in cell heights
#define TAIL_PALETTE     6     // ANSI color the tail fades into (6 = cyan)
#define BEACON           1     // focus ripple: 1 = on, 0 = off
#define BEACON_DURATION  0.40  // s
#define LINEAR_BLENDING  1     // 1 for alpha-blending = linear / linear-corrected, 0 for native

// ─── Helpers ────────────────────────────────────────────────────────────

// Uniform colors arrive gamma-encoded; with linear blending, iChannel0 is
// linear, so convert before mixing or the trail comes out washed-out.
vec3 toBlendSpace(vec3 c) {
#if LINEAR_BLENDING
    return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c));
#else
    return c;
#endif
}

float sdBox(vec2 p, vec2 halfSize) {
    vec2 d = abs(p) - halfSize;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// Signed distance to a quad, negative inside. Works for either winding.
float sdQuad(vec2 p, vec2 v[4]) {
    float d = dot(p - v[0], p - v[0]);
    float s = 1.0;
    for (int i = 0, j = 3; i < 4; j = i, i++) {
        vec2 e = v[j] - v[i];
        vec2 w = p - v[i];
        vec2 b = w - e * clamp(dot(w, e) / max(dot(e, e), 1e-4), 0.0, 1.0);
        d = min(d, dot(b, b));
        bvec3 c = bvec3(p.y >= v[i].y, p.y < v[j].y, e.x * w.y > e.y * w.x);
        if (all(c) || all(not(c))) s = -s;
    }
    return s * sqrt(d);
}

float easeOutCubic(float x) {
    float y = 1.0 - x;
    return 1.0 - y * y * y;
}

// Roughly one cell height for any cursor style (block, bar or underline).
float cellUnit(vec4 cursor) {
    return max(cursor.w, 2.0 * cursor.z);
}

// Ghostty works in premultiplied alpha, so a plain mix is the "over" operator.
vec4 over(vec4 dst, vec3 color, float alpha) {
    return mix(dst, vec4(color, 1.0), clamp(alpha, 0.0, 1.0));
}

// ─── Main ───────────────────────────────────────────────────────────────

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = texture(iChannel0, fragCoord / iResolution.xy);
    if (iFocus == 0 || iCursorVisible == 0) return;

    // On every backend a cursor covers [x, x+w] × [y-h, y] in fragCoord space.
    vec4 cur = iCurrentCursor;
    if (cur.z < 1.0 || cur.w < 1.0) return;
    vec2 curHalf = cur.zw * 0.5;
    vec2 curCenter = cur.xy + vec2(curHalf.x, -curHalf.y);

    vec3 headColor = toBlendSpace(iCurrentCursorColor.rgb);
    vec3 tailColor = toBlendSpace(iPalette[TAIL_PALETTE]);

    // Never paint over the cursor cell itself (or the glyph under a block).
    float outsideCursor = smoothstep(-0.5, 0.5, sdBox(fragCoord - curCenter, curHalf));

    // ── beacon ──────────────────────────────────────────────────────────
#if BEACON
    float tf = iTime - iTimeFocus;
    if (tf >= 0.0 && tf < BEACON_DURATION) {
        float unit = cellUnit(cur);
        float p = tf / BEACON_DURATION;
        float sd = sdBox(fragCoord - curCenter, curHalf);
        float radius = unit * mix(0.05, 0.85, easeOutCubic(p));
        float ring = 1.0 - smoothstep(0.0, 0.2 * unit, abs(sd - radius));
        float core = 1.0 - clamp(sd / (0.9 * unit), 0.0, 1.0);
        float fade = (1.0 - p) * (1.0 - p);
        fragColor = over(fragColor, headColor, (0.4 * ring + 0.2 * core * core * core) * fade * outsideCursor);
    }
#endif

    // ── smear ───────────────────────────────────────────────────────────
    float t = iTime - iTimeCursorChange;
    vec4 prv = iPreviousCursor;
    if (t < 0.0 || t >= DURATION || prv.z < 1.0 || prv.w < 1.0) return;

    vec2 prvHalf = prv.zw * 0.5;
    vec2 prvCenter = prv.xy + vec2(prvHalf.x, -prvHalf.y);
    vec2 delta = curCenter - prvCenter;
    float dist = length(delta);
    float unit = max(cellUnit(cur), cellUnit(prv));
    float cellWidth = max(max(cur.z, prv.z), 0.45 * unit);
    if (dist < MIN_JUMP_CELLS * cellWidth) return;
    vec2 dir = delta / dist;

    // Each corner eases from the old cursor to the new one; corners facing
    // the direction of travel arrive first, the ones behind drag the tail.
    const vec2 corner[4] = vec2[4](
        vec2(-1.0, -1.0), vec2(1.0, -1.0), vec2(1.0, 1.0), vec2(-1.0, 1.0));
    vec2 quad[4];
    float tailProgress = 1.0;
    for (int i = 0; i < 4; i++) {
        float lead = dot(corner[i], dir) * 0.70710678;  // -1 behind … 1 ahead
        float dur = mix(LEAD_DURATION, DURATION, 0.5 - 0.5 * lead);
        float k = easeOutCubic(clamp(t / dur, 0.0, 1.0));
        tailProgress = min(tailProgress, k);
        quad[i] = mix(prvCenter + prvHalf * corner[i], curCenter + curHalf * corner[i], k);
    }

    // Cheap reject: skip pixels outside the trail's bounding box + halo.
    float glowReach = GLOW_CELLS * unit;
    vec2 lo = min(min(quad[0], quad[1]), min(quad[2], quad[3])) - glowReach;
    vec2 hi = max(max(quad[0], quad[1]), max(quad[2], quad[3])) + glowReach;
    if (any(lessThan(fragCoord, lo)) || any(greaterThan(fragCoord, hi))) return;

    float sd = sdQuad(fragCoord, quad);

    // 0 at the tail end of the comet, 1 at the cursor.
    vec2 tailPoint = mix(prvCenter, curCenter, tailProgress);
    float span = max(dot(curCenter - tailPoint, dir), 1.0);
    float along = clamp(dot(fragCoord - tailPoint, dir) / span, 0.0, 1.0);

    float body = mix(TAIL_ALPHA, HEAD_ALPHA, along * along);
    float falloff = 1.0 - clamp(sd / glowReach, 0.0, 1.0);
    float halo = GLOW_ALPHA * along * falloff * falloff;
    float inside = 1.0 - smoothstep(-0.75, 0.75, sd);
    float fade = 1.0 - smoothstep(0.6, 1.0, t / DURATION);

    vec3 color = mix(tailColor, headColor, along);
    fragColor = over(fragColor, color, mix(halo, body, inside) * fade * outsideCursor);
}
