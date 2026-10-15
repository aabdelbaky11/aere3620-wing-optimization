# Evaluation Request C005 — C004 Airfoils, Taper 0.35

**Issued by:** Abdelrahman (Design Lead)
**Date issued:** 2026-10-15
**Sent to:** AI Workflow Lead
**Priority:** run after the C000 and C004 re-runs (`request_C000_C004_rerun_fixedmu.md`). Same locked mesh and solver settings, and the fixed-viscosity Re rule.

---

## 1. Geometry (rows marked * differ from C004)

| Parameter | Value |
|---|---|
| Root airfoil (p_root) | NACA 2415 |
| Tip airfoil (p_tip) | NACA 2412 |
| Root chord (c_root) | 1.337 m * |
| Tip chord (c_tip) | 0.468 m * |
| Taper ratio | 0.35 * |
| Semi-span (b/2) | 3.00 m (fixed) |
| Sweep (Lambda) | 0 deg |
| Root twist | 0 deg (fixed) |
| Tip twist (theta_tip) | 0 deg |

Half-wing volume (wingVolume.m): **V = 0.2515 m^3**, +2.0% over V_bl. Please report the OpenVSP volume too.

**Why this case:** C004 validated 4.00% (before the viscosity fix). This is the first step of a line search along taper ratio on the C004 airfoil family: 0.45 (C004) → 0.35 (C005) → 0.30 (C006). The calibrated screening model predicts the drag keeps falling as taper goes down. C004 beat its prediction (4.00% vs 3.74%), so the 5% tier is within reach.

## 2. Flow conditions

Identical to the C000/C004 re-runs:
- Generate the geometry first and read the MAC the tool reports (`reference_length`). Expected about 0.964 m.
- Set **reynolds_number = 5.0e6 × that MAC** (about 4.82e6).
- Confirm mu ≈ 2.4515e-5 in `thermophysicalProperties`.
- CL target = 0.4005 × 3.00 / S_vsp. Trapezoid S = 2.7075 m^2, which gives about 0.4438. Use the tool's S.

## 3. Finding alpha for CL = 0.4

Start at **alpha = 3.9 deg** (C004 trimmed at 3.88 deg, and taper barely moves alpha).

Predicted result (run_week4.m, calibrated to C000_ai): **−4.59%** in CD.

## 4. What I need back

Same package as C004, prefix `C005_ai_`.
