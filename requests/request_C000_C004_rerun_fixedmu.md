# Evaluation Request — Re-run C000 and C004 at Fixed Viscosity

**Issued by:** Abdelrahman (Design Lead)
**Date issued:** 2026-10-15
**Sent to:** AI Workflow Lead
**Priority:** run these two BEFORE C005 and C006. Every improvement percentage depends on the new C000.

---

## 1. The problem

The agent holds Re = 5.0e6 based on each wing's own OpenVSP MAC (`-reference_length`). Because the MAC changes with the planform, the viscosity changes from case to case:

| Case | MAC (reference_length) | mu used (thermophysicalProperties) | Re based on c_ref = 1.00 m |
|---|---|---|---|
| C000 | 0.99131 m | 2.4302e-5 | 5.04e6 |
| C002 | 1.02491 m | 2.5126e-5 | 4.88e6 |
| C004 | 0.95390 m | 2.3385e-5 | 5.24e6 |

The spec fixes mu and defines Re on c_ref = 1.00 m (Re = 5.0e6). A higher Re means lower skin friction. So C004 ran in slightly easier flow than C000 (worth roughly 0.3 points of its 4.00%), and C002 ran in slightly harder flow. The spec requires the same fixed flow conditions for baseline and optimized designs, so C004 can't be reported as-is.

## 2. The fix

Set the agent's Reynolds number input to

**reynolds_number = 5.0e6 × (that case's OpenVSP MAC)**

This makes Re on c_ref = 1.00 m exactly 5.0e6, and makes mu the same for every case.

| Case | reynolds_number input |
|---|---|
| C000 re-run | **4,956,570** |
| C004 re-run | **4,769,482** |

**Check after meshing:** `constant/thermophysicalProperties` should show **mu ≈ 2.4515e-5** for both cases. If the two values differ, stop and message me.

Everything else stays exactly as locked for C000: geometry, mesh settings, y+ target 70, wall functions, solver, Mach 0.3, and the CL-target scaling (0.4005 × 3.00 / S_vsp). Use the alphas from the first runs as starting points (C000 5.408 deg, C004 3.880 deg).

## 3. What I need back

The same package as before, saved as **`C000_ai_v2/`** and **`C004_ai_v2/`**. Keep the original C000_ai and C004_ai folders: the viscosity drift is a finding for the workflow-comparison section of the final report.
