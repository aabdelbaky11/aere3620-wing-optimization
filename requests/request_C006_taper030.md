# Evaluation Request C006 — C004 Airfoils, Taper 0.30

**Issued by:** Abdelrahman (Design Lead)
**Date issued:** 2026-10-15
**Sent to:** AI Workflow Lead
**Priority:** run after C005. Same locked mesh and solver settings, and the fixed-viscosity Re rule.

---

## 1. Geometry (rows marked * differ from C004)

| Parameter | Value |
|---|---|
| Root airfoil (p_root) | NACA 2415 |
| Tip airfoil (p_tip) | NACA 2412 |
| Root chord (c_root) | 1.374 m * |
| Tip chord (c_tip) | 0.412 m * |
| Taper ratio | 0.30 * |
| Semi-span (b/2) | 3.00 m (fixed) |
| Sweep (Lambda) | 0 deg |
| Root twist | 0 deg (fixed) |
| Tip twist (theta_tip) | 0 deg |

Half-wing volume (wingVolume.m): **V = 0.2515 m^3**, +2.0% over V_bl. The tip chord is still well above the 0.2 m lower bound.

**Why this case:** this is the second step of the taper line search (0.45 → 0.35 → 0.30). The screening model predicts this is the first point past the 5% tier. If C006 comes out worse than C005, the minimum is bracketed between 0.30 and 0.45, and we narrow it from there.

## 2. Flow conditions

Identical to the C000/C004 re-runs:
- Generate the geometry first and read the MAC the tool reports (`reference_length`). Expected about 0.971 m.
- Set **reynolds_number = 5.0e6 × that MAC** (about 4.86e6).
- Confirm mu ≈ 2.4515e-5 in `thermophysicalProperties`.
- CL target = 0.4005 × 3.00 / S_vsp. Trapezoid S = 2.679 m^2, which gives about 0.4484. Use the tool's S.

## 3. Finding alpha for CL = 0.4

Start at **alpha = 3.9 deg**, or at C005's trimmed alpha if C005 is done first.

Predicted result (run_week4.m, calibrated to C000_ai): **−5.04%** in CD.

## 4. What I need back

Same package as C004, prefix `C006_ai_`.
