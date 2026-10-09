# Evaluation Request C002 — Taper 0.45

**Issued by:** Abdelrahman (Design Lead)
**Date prepared:** 2026-10-02 · **Issued:** 2026-10-08 (AI workflow now; conventional after its C000 is re-run)
**Sent to:** AI Workflow Lead, Conventional Workflow Lead
**Priority:** run as soon as C000 is converged — use the SAME mesh settings, y+ target, near-wall treatment, and solver settings locked for C000

---

## 1. Geometry (only the rows marked * differ from C000)

| Parameter | Value |
|---|---|
| Root airfoil (p_root) | NACA 0012 |
| Tip airfoil (p_tip) | NACA 0012 |
| Root chord (c_root) | 1.361 m * |
| Tip chord (c_tip) | 0.612 m * |
| Semi-span (b/2) | 3.00 m (fixed) |
| Sweep (Lambda) | 0 deg |
| Root twist | 0 deg (fixed) |
| Tip twist (theta_tip) | 0 deg |

Half-wing volume (wingVolume.m): **V = 0.2515 m^3**, +2.0% over V_bl = 0.2466 m^3. Please report your own geometry tool's volume.

**Why this case:** isolates the taper effect. Low-fidelity screen predicts span efficiency 0.956 → 0.991 and about 2.5% lower CD than C000 — the best single change.

## 2. Flow conditions and reference quantities

Identical to C000 (see `request_C000_baseline.md`). A_ref stays 3.00 m^2 and c_ref stays 1.00 m even though the planform changed.

## 3. Finding alpha for CL = 0.4 (3 runs, not a sweep)

Starting angles are now workflow-specific (run_week4.m scales the lifting-line estimate by each workflow's own C000 result):

| | AI workflow | Conventional workflow |
|---|---|---|
| alpha1 | **5.31 deg** | **4.65 deg** |
| alpha2 | 6.31 deg | 5.65 deg |

1. Run at alpha1
2. Run at alpha2 = alpha1 + 1 deg
3. `alpha3 = trimAlpha(alpha1, CL1, alpha2, CL2)` → run at alpha3
4. If |CL3 − 0.4| > 0.001, repeat step 3 with the last two points

Report the final alpha with CL ≥ 0.4 (the constraint is strict — 0.3999 voids the case).

Predicted result (run_week4.m, calibrated to your own C000): AI −2.33%, Conv −2.21% in CD.

## 4. What I need back

Same package as C000: alpha, CL, CD, Cp vs x/c at root / mid-span / tip, surface Cp contour, mesh statistics, y+ evidence, residual and CD histories, case files. File prefix `C002_ai_` or `C002_conv_`.
