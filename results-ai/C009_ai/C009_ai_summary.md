# C009_ai — Taper 0.25, Re-sized (Line Search Step 4, AI Workflow, fixed viscosity)

- **Workflow lead:** Kade Wilson (AI Workflow Lead)
- **Request:** `requests/request_C009_taper025.md`
- **Agent cases:** mesh `wing_mesh_0012`, CFD `wing_cfd_0010`
- **Run date:** 2026-11-05/06
- **Status:** **completed**. The agent's analysis review passed.
- **Geometry:** NACA 2415 root, NACA 2412 tip, c_root 1.383 m, c_tip 0.346 m (taper 0.25), b/2 3.00 m, sweep 0°, twist 0°.

## 1. Results (A_ref = 3.00 m²; tool S_vsp = 2.5935 m², values × 2.5935/3.00)

| Quantity | **C009** (taper 0.25) | C008 (taper 0.30) | C007 (taper 0.35) | C000_v2 (baseline) |
|---|---|---|---|---|
| α | **4.341°** (4.34119°) | 4.216° | 4.109° | 5.415° |
| **CL** | **0.40053** (≥ 0.4 ✓) | 0.40051 | 0.40052 | 0.40051 |
| **CD** | **0.019074** | 0.019087 | 0.019117 | 0.020052 |
| **Design improvement vs C000_v2** | **4.88 %** | 4.81 % | 4.66 % | — |
| Screening prediction (run_week8.m) | 4.92–4.95 % | 5.09 % | 4.85 % | — |
| μ | 2.45151e-5 ✓ | 2.45154e-5 | 2.45152e-5 | 2.45149e-5 |
| Wing volume (tool volume_val) | 0.254220 m³ (+2.97 % ✓) | 0.254221 m³ | 0.254287 m³ | 0.246898 m³ |

**Improvement:** (0.020052 − 0.019074) / 0.020052 = **4.88 %**. This is the best AI-workflow design so far, but only 0.07 points better than C008. The prediction (4.92–4.95 %) was close; the over-prediction shrank to 0.04–0.07 points.

**Line search:** CD is still falling at taper 0.25, so the minimum is **not bracketed**, but the gains per step are now 0.15 (0.35 → 0.30) and 0.07 points (0.30 → 0.25). A parabola through the three re-sized CFD points (0.35 / 0.30 / 0.25) puts the minimum at taper ≈ 0.234 with CD ≈ 0.019073 (4.88 %): the drag curve is essentially flat here, and further taper reduction gains < 0.01 points.

**Constraints:** CL ≥ 0.4 ✓. V ≥ V_bl ✓ (tool volume 0.254220 vs 0.246898; request expected ≈ 0.2541).

**Fixed-viscosity Re:**
- Input `reynolds_number` = 4,800,290, from an estimated MAC of 0.9600581 m. The tool's actual MAC is 0.9600666 m (error 0.001 %).
- μ = 2.451513e-5 in `thermophysicalProperties`, which matches C000_v2.

## 2. Mesh (locked settings)

| Cells | Max skewness | Max non-orthogonality | Avg non-orthogonality | Max aspect ratio | Severe non-orth faces |
|---|---|---|---|---|---|
| **396,848** ✓ | 1.620 | 62.72° | 11.10° | 241.0 | 0 |

- **Far field:** a 10 m march (`farfield_scale` 7.231 = 10 / c_root).
- **Root plane:** `symmetry` patch.

## 3. y+ and convergence

- **y+:** min 8.83, max 83.33, average 42.17.
- **Residual drop (orders):** p 6.50, U0 9.21, U1 8.70, U2 8.24, he 8.89, nuTilda 8.39. All are ≥ 6 ✓.
- **Converged-tail std:** CD 3.5e-7, CL 1.4e-8. No NaN/Inf.
- **CL search:** α 4.28° → 4.29° → 4.341°, 4 primal runs, 146 iterations total.

## 4. Run notes

- Before the CFD, the mesh geometry's volume was checked in OpenVSP against C008 (≈ 0.2546 m³ tool-equivalent), so the case passed the volume gate before solver time was spent. The tool's final volume_val confirms it.
- The agent generated the mesh and the CFD case. The unchanged agent run script was then executed in its own Docker container (`c009_cfd`), so MCP reconnects cannot kill the solve.
- The laptop slept overnight during the solve; the container resumed on wake and finished normally (about 3 h of solve time over 12 h wall-clock). No iterations were repeated or altered.
- The agent's analyze step produced the metrics and plots.

## 5. Files

Same layout as the earlier packages: metrics JSON, `plots/`, `plot_data/`, `case_files/` (including `thermophysicalProperties`) and `workflow_logs/`.
