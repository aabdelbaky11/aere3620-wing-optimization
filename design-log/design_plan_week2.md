# Candidate Design Plan — Week 2

**Design Lead:** Abdelrahman Abdelbaky
**Status:** awaiting baseline results (C000). Geometries below are pre-verified
against the volume constraint and ready to issue as soon as α_bl and CD_bl land.

---

## 1. What actually drives CD here

**Induced drag.** D_i ~ L² / (q · b² · e). Semi-span is fixed at 3.00 m. Lift is
pinned by CL ≥ 0.4 and the fixed A_ref = 3.00 m², so L ≈ 7490 N on the half wing
regardless of what we do. Span and lift are both locked, so **span efficiency e
is the only handle on induced drag.** At AR 6 and CL 0.4, induced drag is likely
more than half the total, which makes e the single biggest lever available.

**Profile drag.** Scales with actual wetted area and sectional Cd. The key point:
CD is normalized by the *fixed* A_ref = 3.00 m², not by the real planform area.
Shrink the real wing and the drag force falls while the denominator stays put —
so reducing area is a direct CD reduction. The volume constraint is what limits
how far this goes.

**The constraint.** V ≥ 0.2466 m³. Only chords and airfoil thickness enter it.
Sweep, twist, and angle of attack do not change sectional area, so they are free.

---

## 2. Candidates

All geometries verified at **+2.00% volume margin** (V = 0.2515 m³ vs V_bl =
0.2466 m³). The margin is deliberate — the spec voids any improvement if a
constraint is violated "even by a small amount," so we are not running at equality.

| Case | Root airfoil | Tip airfoil | c_root | c_tip | Λ | θ_tip | S_half | ΔS |
|---|---|---|---|---|---|---|---|---|
| C000 | NACA 0012 | NACA 0012 | 1.000 | 1.000 | 0° | 0° | 3.000 | — |
| C001 | NACA 2412 | NACA 2412 | 1.010 | 1.010 | 0° | 0° | 3.030 | +1.0% |
| C002 | NACA 0012 | NACA 0012 | 1.361 | 0.612 | 0° | 0° | 2.960 | −1.3% |
| C003 | NACA 2412 | NACA 2412 | 1.361 | 0.612 | 0° | −2° | 2.960 | −1.3% |
| C004 | NACA 2415 | NACA 2412 | 1.266 | 0.570 | 0° | −2° | 2.754 | −8.2% |

### C001 — camber, nothing else
NACA 0012 is symmetric and needs roughly 3.5° of α to reach CL = 0.4. A cambered
section reaches it at lower α with a better pressure distribution and less
suction-peak drag. Camber does not change the thickness distribution, so it does
not touch the volume constraint — chord is nudged to 1.010 m purely to buy margin.

**Tests:** does camber alone reduce CD, and by how much.
**Expected:** modest win, 1–3%.

### C002 — taper, nothing else
Taper ratio 0.45 is near the classic optimum for an untwisted wing, pushing the
spanwise loading toward elliptical and raising e. Also trims 1.3% of wetted area.

**Tests:** how much of the induced drag we can recover through loading alone.
**Expected:** the largest single effect.

### C003 — combine the winners, add washout
Camber plus taper plus 2° of washout. Twist is free with respect to volume, so
it costs nothing to try. Washout unloads the tip; whether that helps or hurts
depends on where C002's loading lands relative to elliptical.

**Tests:** whether the effects stack, and the sign of the twist sensitivity.
**Note:** if C003 comes back worse than C002, rerun with θ_tip = +2° instead.

### C004 — thickness-for-area trade
Thicken the root to 15% and shrink the chords to hold volume. This cuts wetted
area by **8.2%**, the largest area reduction available, which should cut profile
drag directly. The counter-pressure is that thicker sections carry higher
sectional Cd, so this could go either way.

**Tests:** whether the area saving beats the thickness penalty.
**This is the highest-variance case and the one most worth running.**

---

## 3. Sequencing

Run C001 and C002 first, one variable each. With runs this expensive, isolating
effects beats sweeping — we need to know which lever actually moves CD before
spending teammate hours on combinations.

Then C003 and C004 based on what comes back.

**Sweep stays at 0° for now.** At M = 0.30 there is no compressibility to relieve,
and sweep tends to cost a little span efficiency. Worth one confirmation case
late in the project, not early.

---

## 4. Open questions for the workflow leads

- **What airfoil parameterization do your tools accept?** The spec leaves p_root
  and p_tip open. If NACA 4-digit codes work directly, the table above is ready
  to run. If you need coordinate files, tell me and I will generate them.
- **Can you handle twist?** θ_tip requires rotating the tip section about the
  chord line. Confirm before I issue C003.
- **Does your geometry tool agree on volume?** Report your computed V for C000.
  If it disagrees with 0.2466 m³, we adopt one method and use it for every case.
