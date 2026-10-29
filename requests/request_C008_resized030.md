# Evaluation Request C008 — Taper 0.30, Re-sized to +1% Volume

**Issued by:** Abdelrahman (Design Lead)
**Date issued:** 2026-10-29
**Sent to:** AI Workflow Lead
**Priority:** run after C007. Same locked mesh and solver settings, and the fixed-viscosity Re rule. Replaces C006 (same taper, but C006 carried ~5% extra volume).

---

## 1. Geometry (rows marked * differ from C007)

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

**Expected tool volume_val ≈ 0.2542 m^3 (+2.9% over V_bl = 0.246898).** Check it before starting CFD. The tip chord is still double the 0.2 m lower bound.

**Why this case:** this is the third point of the line search along taper on the re-sized family. C004_v2 (0.45) and C005 (0.35) are the first two, moved onto the re-sized chords with the model. A parabola through the three points (lineSearchQuad.m) tells us whether the minimum is bracketed or the search should step further.

C005 showed lower taper helps less than the week-6 model said (0.37 points from 0.45 to 0.35, not 0.86). With that correction the model predicts **−5.09%** in CD vs C000_ai_v2 — right at the 5% tier, so this run decides it.

## 2. Flow conditions

Identical to C007:
- Read the tool's MAC first. Expected about **0.953 m**, so **reynolds_number ≈ 4.76e6** (5.0e6 × MAC). Confirm mu ≈ 2.4515e-5.
- CL target = 0.4005 × 3.00 / S_vsp. Trapezoid S = 2.628 m^2, which gives about **0.4572**. Use the tool's S.

## 3. Finding alpha for CL = 0.4

Start at **alpha = 4.17 deg**.

## 4. What I need back

Same package as C005, prefix `C008_ai_`, in `results-ai/C008_ai/`.
