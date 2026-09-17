# Evaluation Request C000 — Baseline Wing

**Issued by:** Abdelrahman (Design Lead)
**Date issued:** 2026-09-17
**Sent to:** AI Workflow Lead, Conventional Workflow Lead
**Priority:** blocking — no design iteration can begin until this returns

---

## 1. Geometry

| Parameter | Value |
|---|---|
| Root airfoil (p_root) | NACA 0012 |
| Tip airfoil (p_tip) | NACA 0012 |
| Root chord (c_root) | 1.00 m |
| Tip chord (c_tip) | 1.00 m |
| Semi-span (b/2) | 3.00 m (fixed) |
| Sweep (Lambda) | 0 deg |
| Root twist | 0 deg (fixed) |
| Tip twist (theta_tip) | 0 deg |

Half-wing model. Symmetry plane at the root.

Computed half-wing volume: **V_bl = 0.247 m^3**
(NACA 4-digit area coefficient 0.685; see `wingVolume.m`. Please confirm
against your own geometry tool and report any disagreement — whichever
method we adopt must then be used for BOTH baseline and optimized cases.)

## 2. Flow conditions (fixed for every case this semester)

| Quantity | Value |
|---|---|
| Speed of sound, a_inf | 340 m/s |
| Freestream velocity, U_inf | 102 m/s |
| Density, rho_inf | 1.20 kg/m^3 |
| Dynamic viscosity, mu_inf | 2.448e-5 Pa*s |
| Static pressure, p_inf | 101325 Pa |
| Mach, M_inf | 0.30 |
| Reynolds, Re_cref | 5.0e6 |
| Dynamic pressure, q_inf | 6242.4 Pa |

## 3. Reference quantities

| Quantity | Value |
|---|---|
| Reference chord, c_ref | 1.00 m |
| Reference area, A_ref | 3.00 m^2 |

Coefficients use forces on ONE half wing and the fixed reference area:
CL = L / (q_inf * A_ref), CD = D / (q_inf * A_ref), Cp = (p - p_inf) / q_inf.

D is the force projection along the freestream direction; L is normal to
the freestream and upward.

## 4. What I need back

**Primary task:** sweep angle of attack until CL = 0.4. That alpha becomes
alpha_bl and is a fixed reference for the whole project.

Deliverables:

1. **alpha_bl** — the alpha giving CL = 0.4 (report to 3 decimal places)
2. **CD at that condition** — this is CD_bl, the number every later design
   is measured against
3. **Cp vs x/c** at root, mid-span, and tip
4. **Surface pressure contour** on the wing
5. **Mesh statistics** — cell count, max skewness, min cell volume,
   max non-orthogonal angle, max aspect ratio
6. **y+ evidence** — distribution or range over the wing surface
7. **Residual history** and **CD convergence history**
8. **Case files** — whatever is needed to reproduce the run

## 5. Quality requirements (from the project spec)

- Mesh: 360,000 to 440,000 cells
- y+ target: 30 to 100
- Far-field domain: approximately 20 m, wing centered
- Residuals reduced by at least six orders of magnitude
- CD oscillation in the converged region below three significant digits
- Mesh-quality metrics within the solver's recommended limits

**Important:** whatever mesh topology, y+ target, near-wall treatment, and
solver settings you use here must be reused for every later design. The
baseline-to-optimized comparison is only valid if the settings match.
Please document your settings now so we can lock them.

## 6. Naming convention

Return files prefixed `C000_ai_` or `C000_conv_` depending on workflow.
All later cases follow the same pattern with sequential IDs (C001, C002, ...).
Do not encode geometry in filenames — the decision log carries parameters.

## 7. Notes

- If you cannot hit CL = 0.4 exactly, bracket it and report the two
  surrounding alphas with their CL values; I will interpolate.
- Report problems early. A late "it didn't converge" costs the team a week.
- If the two workflows disagree on CD by more than a few percent, that is a
  finding worth documenting for the workflow-comparison deliverable, not a
  failure. Do not tune settings to force agreement.
