# C005_ai — C004 Airfoils, Taper 0.35 (AI Workflow, fixed viscosity)

- **Workflow lead:** Kade Wilson (AI Workflow Lead)
- **Request:** `requests/request_C005_taper035.md`
- **Agent cases:** mesh `wing_mesh_0007`, CFD `wing_cfd_0007`
- **Run date:** 2026-10-23
- **Status:** **completed**. The agent's analysis review passed.
- **Geometry:** NACA 2415 root, NACA 2412 tip, c_root 1.337 m, c_tip 0.468 m (taper 0.35), b/2 3.00 m, sweep 0°, twist 0°.

## 1. Results (A_ref = 3.00 m²; tool S_vsp = 2.7075 m², values × 2.7075/3.00)

| Quantity | **C005** | C004_v2 (taper 0.45) | C000_v2 (baseline) |
|---|---|---|---|
| α | **4.039°** (4.03904°) | 3.889° | 5.415° |
| **CL** | **0.40045** (≥ 0.4 ✓) | 0.40053 | 0.40051 |
| **CD** | **0.019234** | 0.019308 | 0.020052 |
| **Design improvement vs C000_v2** | **4.08 %** | 3.71 % | — |
| Screening prediction (run_week4.m) | 4.59 % | — | — |
| μ | 2.45153e-5 ✓ | 2.45149e-5 | 2.45149e-5 |
| Wing volume (OpenVSP) | 0.263592 m³ (+6.76 % ✓) | 0.262578 m³ | 0.246898 m³ |

**Improvement:** (0.020052 − 0.019234) / 0.020052 = **4.08 %**. Lowering the taper from 0.45 to 0.35 gained another 0.37 points over C004_v2.

**Fixed-viscosity Re:**
- Input `reynolds_number` = 4,820,345, from an estimated MAC of 0.96407 m.
- The tool's actual MAC is 0.9640836 m, an error of 0.0015 %.
- μ = 2.45153e-5, which is 0.002 % from the C000_v2 value.

## 2. Mesh (locked settings)

| Cells | Max skewness | Max non-orthogonality | Max aspect ratio | Min cell volume |
|---|---|---|---|---|
| **396,848** ✓ | 1.682 | 63.06° | 232.2 | 5.74e-12 m³ |

- **Far field:** a 10 m march (`farfield_scale` 7.479). The bounding box is x −10.0 → 11.33 m, y 0 → 13.01 m, z −10.05 → +10.10 m.
- **Root plane:** `symmetry` patch.

## 3. y+ and convergence

- **y+:** min 8.21, max 83.22, average 43.18.
- **Residual drop (orders):** p 6.60, U0 9.32, U1 8.90, U2 8.47, he 9.09, nuTilda 8.42. All are ≥ 6 ✓.
- **Converged-tail std:** CD 5.9e-9, CL 1.2e-8.
- **CL search:** α 3.9° → 4.039°.

## 4. Run notes

- The agent generated the mesh and the CFD case. The unchanged agent run script was then executed in its own Docker container, so MCP reconnects cannot kill the solve. An MCP restart did happen mid-run and had no effect.
- The agent's analyze step produced the metrics and plots.

## 5. Files

Same layout as the earlier packages: metrics JSON, `plots/`, `plot_data/`, `case_files/` (including `thermophysicalProperties`) and `workflow_logs/`.
