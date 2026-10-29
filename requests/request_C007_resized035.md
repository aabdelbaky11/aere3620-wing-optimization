# Evaluation Request C007 — C005 Re-sized to +1% Volume (Taper 0.35)

**Issued by:** Abdelrahman (Design Lead)
**Date issued:** 2026-10-29
**Sent to:** AI Workflow Lead
**Priority:** next AI run. Same locked mesh and solver settings, and the fixed-viscosity Re rule. Replaces C006.

---

## 1. Geometry (rows marked * differ from C005)

| Parameter | Value |
|---|---|
| Root airfoil (p_root) | NACA 2415 |
| Tip airfoil (p_tip) | NACA 2412 |
| Root chord (c_root) | 1.313 m * |
| Tip chord (c_tip) | 0.460 m * |
| Taper ratio | 0.35 |
| Semi-span (b/2) | 3.00 m (fixed) |
| Sweep (Lambda) | 0 deg |
| Root twist | 0 deg (fixed) |
| Tip twist (theta_tip) | 0 deg |

Same planform shape as C005, scaled down 1.8%. **Expected tool volume_val ≈ 0.2543 m^3 (+3.0% over V_bl = 0.246898).** Check the tool's volume before starting CFD — it must be at least 0.246898 m^3.

**Why this case:** C005 carried +6.8% more volume than the constraint needs, and extra volume means extra wetted area. This case keeps the taper and removes most of that margin, so it tests the volume lever by itself. The screening model got this kind of change right on C004 (3.74% predicted vs 3.71% CFD).

Predicted result (run_week7.m): **−4.85%** in CD vs C000_ai_v2.

## 2. Flow conditions

Identical to C004_v2 / C005:
- Generate the geometry first and read the tool's MAC (`reference_length`). Expected about **0.947 m** (the tool's MAC has run 0.9916 × the trapezoid MAC on C004 and C005).
- Set **reynolds_number = 5.0e6 × that MAC** (about 4.73e6). Confirm mu ≈ 2.4515e-5 in `thermophysicalProperties`.
- CL target = 0.4005 × 3.00 / S_vsp. Trapezoid S = 2.6595 m^2, which gives about **0.4518**. Use the tool's S.

## 3. Finding alpha for CL = 0.4

Start at **alpha = 4.12 deg** (C005 trimmed at 4.04 deg; the smaller wing needs slightly more).

## 4. What I need back

Same package as C005, prefix `C007_ai_`, in `results-ai/C007_ai/`.
