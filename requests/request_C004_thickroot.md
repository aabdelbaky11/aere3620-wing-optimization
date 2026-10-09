# Evaluation Request C004 — Thick Root + Taper 0.45

**Issued by:** Abdelrahman (Design Lead)
**Date issued:** 2026-10-08
**Sent to:** AI Workflow Lead (now); Conventional Workflow Lead (after its C000 is re-run)
**Priority:** run right after C002 — use the SAME mesh settings, y+ target, near-wall treatment, and solver settings locked for C000

---

## 1. Geometry (rows marked * differ from C000)

| Parameter | Value |
|---|---|
| Root airfoil (p_root) | NACA 2415 * |
| Tip airfoil (p_tip) | NACA 2412 * |
| Root chord (c_root) | 1.266 m * |
| Tip chord (c_tip) | 0.570 m * |
| Semi-span (b/2) | 3.00 m (fixed) |
| Sweep (Lambda) | 0 deg |
| Root twist | 0 deg (fixed) |
| Tip twist (theta_tip) | 0 deg |

Airfoil section varies linearly from root to tip (thickness 15% → 12%, camber 2% at 40% chord at both ends). Chord varies linearly.

Half-wing volume (wingVolume.m): **V = 0.2515 m^3**, +2.0% over V_bl. Please report your own geometry tool's volume (AI tool gave 0.246898 m^3 for C000).

**Why this case:** after calibrating the low-fidelity model to both C000 results, C004 is the only candidate predicted above 2% under every drag model (2.8–3.8%). The thicker root holds the volume with smaller chords, which cuts wetted area by about 8%; taper 0.45 keeps the loading near elliptic (e ≈ 0.99).

## 2. Flow conditions and reference quantities

Identical to C000 (see `request_C000_baseline.md`). A_ref stays 3.00 m^2 and c_ref stays 1.00 m.

## 3. Finding alpha for CL = 0.4

The sections are cambered, so alpha will be well below C000's.

| | AI workflow | Conventional workflow |
|---|---|---|
| alpha1 | **3.53 deg** | **2.83 deg** |
| alpha2 | 4.53 deg | 3.83 deg |

Then `alpha3 = trimAlpha(alpha1, CL1, alpha2, CL2)` and repeat until |CL − 0.4| ≤ 0.001 with CL ≥ 0.4.

Predicted result (run_week4.m, calibrated to your own C000): AI −3.74%, Conv −3.78% in CD.

## 4. What I need back

Same package as C000: alpha, CL, CD, Cp vs x/c at root / mid-span / tip, surface Cp contour, mesh statistics (cell count, max skewness, max non-orthogonality, max aspect ratio, min cell volume), y+ range, residual and CD histories, case files. File prefix `C004_ai_` or `C004_conv_`.
