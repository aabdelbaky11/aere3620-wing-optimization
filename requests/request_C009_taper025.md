# Evaluation Request C009 — Taper 0.25, Re-sized (Line Search Step 4)

**Issued by:** Abdelrahman (Design Lead)
**Date issued:** 2026-11-05
**Sent to:** AI Workflow Lead
**Priority:** next AI run. Same locked mesh and solver settings, and the fixed-viscosity Re rule.

---

## 1. Geometry (rows marked * differ from C008)

| Parameter | Value |
|---|---|
| Root airfoil (p_root) | NACA 2415 |
| Tip airfoil (p_tip) | NACA 2412 |
| Root chord (c_root) | 1.383 m * |
| Tip chord (c_tip) | 0.346 m * |
| Taper ratio | 0.25 * |
| Semi-span (b/2) | 3.00 m (fixed) |
| Sweep (Lambda) | 0 deg |
| Root twist | 0 deg (fixed) |
| Tip twist (theta_tip) | 0 deg |

Sized the same way as C007/C008. **Expected tool volume_val ≈ 0.2541 m^3 (+2.9% over V_bl = 0.246898).** Check it before starting CFD — it must be at least 0.246898 m^3. Tip chord 0.346 m, well above the 0.2 m bound.

**Why this case:** C007 and C008 put two CFD points on the re-sized family. With C004_v2 moved onto it, the parabola through taper 0.45 / 0.35 / 0.30 (lineSearchQuad.m) is **not bracketed** — drag is still falling at 0.30, but more slowly (0.43 points from 0.45 to 0.35, then 0.15 from 0.35 to 0.30). Its minimum sits at taper 0.154, too far past the data to trust, so this run expands the search by one step.

Predicted (run_week8.m): **−4.92%** (parabola) to **−4.95%** (llScreen anchored on C008). If it comes in above C008, the minimum is bracketed and the taper search is done. 5% is unlikely from taper alone.

## 2. Flow conditions

Identical to C008:
- Read the tool's MAC first. Expected about **0.960 m** (trapezoid MAC 0.9682 × the 0.9915 tool ratio from C008), so **reynolds_number ≈ 4.80e6** (5.0e6 × MAC). Confirm mu ≈ 2.4515e-5.
- CL target = 0.4005 × 3.00 / S_vsp. Trapezoid S = 2.5935 m^2, which gives about **0.4633**. Use the tool's S.

## 3. Finding alpha for CL = 0.4

Start at **alpha = 4.28 deg**.

## 4. What I need back

Same package as C008, prefix `C009_ai_`, in `results-ai/C009_ai/`.

If Gabriel asks for help with C008_conv this week, that comes first — the conventional 3% is worth more to the team than this point.
