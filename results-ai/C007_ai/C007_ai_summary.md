# C007_ai — C005 Re-sized to +3% Volume, Taper 0.35 (AI Workflow, fixed viscosity)

- **Workflow lead:** Kade Wilson (AI Workflow Lead)
- **Request:** `requests/request_C007_resized035.md` (replaces C006)
- **Agent cases:** mesh `wing_mesh_0010`, CFD `wing_cfd_0008`
- **Run date:** 2026-10-29
- **Status:** **completed**. The agent's analysis review passed.
- **Geometry:** NACA 2415 root, NACA 2412 tip, c_root 1.313 m, c_tip 0.460 m (taper 0.35), b/2 3.00 m, sweep 0°, twist 0°.

## 1. Results (A_ref = 3.00 m²; tool S_vsp = 2.6595 m², values × 2.6595/3.00)

| Quantity | **C007** | C005 (taper 0.35, full size) | C004_v2 (taper 0.45) | C000_v2 (baseline) |
|---|---|---|---|---|
| α | **4.109°** (4.10938°) | 4.039° | 3.889° | 5.415° |
| **CL** | **0.40052** (≥ 0.4 ✓) | 0.40045 | 0.40053 | 0.40051 |
| **CD** | **0.019117** | 0.019234 | 0.019308 | 0.020052 |
| **Design improvement vs C000_v2** | **4.66 %** | 4.08 % | 3.71 % | — |
| Screening prediction (run_week7.m) | 4.85 % | 4.59 % | — | — |
| μ | 2.45152e-5 ✓ | 2.45153e-5 | 2.45149e-5 | 2.45149e-5 |
| Wing volume (tool volume_val) | 0.254287 m³ (+2.99 % ✓) | 0.263592 m³ | 0.262578 m³ | 0.246898 m³ |

**Improvement:** (0.020052 − 0.019117) / 0.020052 = **4.66 %**. Removing most of C005's volume margin gained another 0.58 points. The screening model over-predicted by 0.19 points.

**Constraints:** CL ≥ 0.4 ✓. V ≥ V_bl ✓ (tool volume 0.254287 vs 0.246898; it also matches the request's expected ≈ 0.2543).

**Fixed-viscosity Re:**
- Input `reynolds_number` from an estimated MAC; the tool's actual MAC is 0.9468973 m (estimate error 0.001 %).
- μ = 2.451515e-5 in `thermophysicalProperties`, which matches C000_v2.

## 2. Mesh (locked settings)

| Cells | Max skewness | Max non-orthogonality | Avg non-orthogonality | Max aspect ratio | Severe non-orth faces |
|---|---|---|---|---|---|
| **396,848** ✓ | 1.678 | 63.05° | 10.59° | 236.4 | 0 |

- **Far field:** a 10 m march (`farfield_scale` = 10 / c_root).
- **Root plane:** `symmetry` patch.

## 3. y+ and convergence

- **y+:** min 8.21, max 82.10, average 42.50.
- **Residual drop (orders):** p 6.76, U0 9.46, U1 8.78, U2 8.52, he 9.12, nuTilda 8.61. All are ≥ 6 ✓.
- **Converged-tail std:** CD 1.1e-8, CL 1.8e-8. No NaN/Inf.
- **CL search:** α 4.12° → 4.13° → 4.109°, 4 primal runs, 140 iterations total.

## 4. Run notes

- Before the CFD, the mesh geometry's volume was checked in OpenVSP against C000 and C005 (+2.85 % raw), so the case passed the request's volume gate before solver time was spent. The tool's final volume_val confirms it.
- The agent generated the mesh and the CFD case. The unchanged agent run script was then executed in its own Docker container (`c007_cfd`), so MCP reconnects cannot kill the solve. Post-processing completed normally.
- The agent's analyze step produced the metrics and plots.

## 5. Files

Same layout as the earlier packages: metrics JSON, `plots/`, `plot_data/`, `case_files/` (including `thermophysicalProperties`) and `workflow_logs/`.
