# Evaluation Request C008 (Conventional) — Taper 0.30, Re-sized

**Issued by:** Abdelrahman (Design Lead)
**Date issued:** 2026-11-05
**Sent to:** Conventional Workflow Lead
**Priority:** next conventional run, and the team's most important case right now. Use the SAME mesh settings, near-wall treatment and solver settings as C000_conv and C005_conv.

---

## 1. Why this case

C005_conv came back at **2.33%** — a valid, constraint-satisfying improvement, so the conventional workflow now has its changed design. Thanks for the full package.

This case is the AI workflow's best design so far (`results-ai/C008_ai/`, **4.81%**). It matters for two reasons:
- **Bonus:** the AI workflow is already above 3%. If the conventional workflow also clears 3%, the team bonus goes from +3 to **+5** for everyone. That needs **CD ≤ 0.020002** (3% below your C000 CD of 0.0206204).
- **Report:** a second identical wing in both workflows gives the comparison section two data points instead of one.

Prediction (run_week8.m): **2.75% to 3.05%**. It is right on the line, so the run quality below matters.

## 2. Geometry (rows marked * differ from C005_conv)

| Parameter | Value |
|---|---|
| Root airfoil (p_root) | NACA 2415 |
| Tip airfoil (p_tip) | NACA 2412 |
| Root chord (c_root) | 1.348 m * |
| Tip chord (c_tip) | 0.404 m * |
| Taper ratio | 0.30 * |
| Semi-span (b/2) | 3.00 m (fixed) |
| Sweep (Lambda) | 0 deg |
| Root twist | 0 deg (fixed) |
| Tip twist (theta_tip) | 0 deg |

**SOLIDWORKS:** same method as C005 — NACA 2415 at the root plane (chord 1.348 m), NACA 2412 on a plane 3.00 m out (chord 0.404 m), leading edges on one line, chord lines parallel, straight loft with no tangency constraints, flat tip. Use the same airfoil coordinate source you used for C005.

**Volume check:** Mass Properties should give about **0.2505 m^3** (straight-loft estimate 0.250485 m^3, +1.46% over V_bl = 0.24688 m^3). Your C005 volume matched the estimate to 0.02%, so expect the same here. Report the exact value. **Anything under 0.24688 m^3 means stop and tell me** — the constraint is strict.

## 3. Flow conditions and reference quantities

Identical to C005_conv:
- U = 102 m/s, rho = 1.20 kg/m^3, mu = 2.448e-5 Pa s, p = 101325 Pa
- **A_ref = 3.00 m^2 and c_ref = 1.00 m** (this wing's planform area is 2.628 m^2 — keep 3.00)
- Cp reference: q = 6242.4 Pa

**Mesh:** keep the cell count inside **360,000–440,000** (C005 was 426,966).

**Wall y+:** C005 reached a max of **105**; the spec range is **30–100**. If the max is still above 100 after meshing, thin the first prism layer slightly (a few percent) until max y+ ≤ 100, and tell me the change. Everything else stays locked.

## 4. Finding alpha for CL = 0.4

| | Conventional workflow |
|---|---|
| alpha1 | **5.15 deg** |
| alpha2 | 5.65 deg |

Then `alpha3 = trimAlpha(alpha1, CL1, alpha2, CL2)` and repeat until |CL − 0.4| ≤ 0.001 with **CL ≥ 0.4**. Your C005 trimmed 0.93 deg above the AI workflow's C005, and the AI C008 trimmed at 4.22 deg, so 5.15 deg should land close.

**Please list every alpha you ran with its CL** — the report needs the trim history.

## 5. What I need back

Same package as C005_conv, prefix `C008_conv_`, in `results-conventional/C008_conv/`:
- alpha, CL, CD (7 significant figures) and the SOLIDWORKS volume
- the alpha / CL trim history (section 4)
- CD history for the whole run and the residual history
- Mesh: cell count, max skewness angle, min cell volume, aspect ratio, wall y+ min and max
- Cp vs x/c at root, mid-span and tip, and the surface Cp contour
- The .sim file
- A line or two in the README (the C005_conv one is empty)

## 6. One question on C005_conv

On the identical wing, the AI workflow's alpha dropped 1.38 deg from its C000 and yours dropped 0.87 deg, and your drag drop is 59% of the AI one. Volume matched, so chords and thickness are right. Can you confirm two things:
1. The C005 summary repeats the C000 note about a "more accurate and refined airfoil geometry." Is that just carried over, or did the airfoil build change between C000 and C005?
2. Where did the NACA 2415 / 2412 coordinates come from (generator, point count), and is the camber line in there (max camber 2% at 40% chord)?
