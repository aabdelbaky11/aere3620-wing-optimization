# Evaluation Request C005 (Conventional) — C004 Airfoils, Taper 0.35

**Issued by:** Abdelrahman (Design Lead)
**Date issued:** 2026-10-29
**Sent to:** Conventional Workflow Lead
**Priority:** first design case for the conventional workflow. Use the SAME mesh settings, y+ target, near-wall treatment and solver settings locked for C000_conv.

---

## 1. Why this case

The AI workflow validated this exact geometry at **4.08%** below its own baseline (`results-ai/C005_ai/`). Running the identical wing in STAR-CCM+ gives us:
- a constraint-satisfying improvement in the conventional workflow (Conventional milestone 3), and the +5 bonus if it clears 3% in both workflows
- a like-for-like case for the workflow comparison section of the final report

## 2. Geometry (rows marked * differ from C000)

| Parameter | Value |
|---|---|
| Root airfoil (p_root) | NACA 2415 * |
| Tip airfoil (p_tip) | NACA 2412 * |
| Root chord (c_root) | 1.337 m * |
| Tip chord (c_tip) | 0.468 m * |
| Taper ratio | 0.35 * |
| Semi-span (b/2) | 3.00 m (fixed) |
| Sweep (Lambda) | 0 deg |
| Root twist | 0 deg (fixed) |
| Tip twist (theta_tip) | 0 deg |

**SOLIDWORKS:** sketch the NACA 2415 section (chord 1.337 m) at the root plane and the NACA 2412 section (chord 0.468 m) on a plane 3.00 m out. Both leading edges on the same line (zero sweep), both chord lines parallel (zero twist). Loft with **no start/end tangency constraints** so the surface is a straight (ruled) loft — that is what the volume check assumes. Flat tip, same as C000_conv.

**Volume check:** Mass Properties should give about **0.2595 m^3** (straight-loft estimate 0.25954 m^3, +5.1% over V_bl = 0.24688 m^3). Report the exact value. Anything under 0.24688 m^3 means the loft is wrong — stop and tell me before running.

## 3. Flow conditions and reference quantities

Identical to C000_conv (spec values):
- U = 102 m/s, rho = 1.20 kg/m^3, mu = 2.448e-5 Pa s, p = 101325 Pa (M = 0.30, Re = 5.0e6 on c_ref)
- **A_ref = 3.00 m^2 and c_ref = 1.00 m** — keep these even though this wing's planform area is 2.7075 m^2. CL and CD must be on 3.00 m^2 to compare with C000_conv.
- Cp reference: q = 6242.4 Pa

Keep the cell count inside **360,000–440,000**. C000_conv was at 439,710, so check the count after meshing — the smaller wing may shift it.

## 4. Finding alpha for CL = 0.4

| | Conventional workflow |
|---|---|
| alpha1 | **4.48 deg** |
| alpha2 | 5.48 deg |

Then `alpha3 = trimAlpha(alpha1, CL1, alpha2, CL2)` and repeat until |CL − 0.4| ≤ 0.001 with **CL ≥ 0.4**. The AI workflow trimmed this wing at 4.04 deg; your C000 needed 0.43 deg more than the AI one, so 4.48 deg should land close.

Predicted result (run_week7.m, calibrated to your C000): about **−4.0 to −4.1%** in CD vs CD_bl(conv) = 0.020620.

## 5. What I need back

Same package as C000_conv, prefix `C005_conv_`, in `results-conventional/C005_conv/`:
- alpha, CL, CD (7 significant figures, like the baseline) and the SOLIDWORKS volume
- **CD history for the whole run** and the residual history (label check: Sa_nut and Energy)
- Mesh: cell count, max skewness angle, min cell volume, aspect ratio, wall y+ min and max
- Cp vs x/c on the wing at root, mid-span and tip, and the surface Cp contour
- The .sim file
