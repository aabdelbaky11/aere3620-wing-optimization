# C008_ai — Taper 0.30, Re-sized to +3% Volume (AI Workflow, fixed viscosity)

- **Workflow lead:** Kade Wilson (AI Workflow Lead)
- **Request:** `requests/request_C008_resized030.md`
- **Agent cases:** mesh `wing_mesh_0011`, CFD `wing_cfd_0009`
- **Run date:** 2026-10-29/30
- **Status:** **completed**. The agent's analysis review passed.
- **Geometry:** NACA 2415 root, NACA 2412 tip, c_root 1.348 m, c_tip 0.404 m (taper 0.30), b/2 3.00 m, sweep 0°, twist 0°.

## 1. Results (A_ref = 3.00 m²; tool S_vsp = 2.628 m², values × 2.628/3.00)

| Quantity | **C008** (taper 0.30) | C007 (taper 0.35) | C005 (taper 0.35, full size) | C000_v2 (baseline) |
|---|---|---|---|---|
| α | **4.216°** (4.21572°) | 4.109° | 4.039° | 5.415° |
| **CL** | **0.40051** (≥ 0.4 ✓) | 0.40052 | 0.40045 | 0.40051 |
| **CD** | **0.019087** | 0.019117 | 0.019234 | 0.020052 |
| **Design improvement vs C000_v2** | **4.81 %** | 4.66 % | 4.08 % | — |
| Screening prediction | 5.09 % | 4.85 % | 4.59 % | — |
| μ | 2.45154e-5 ✓ | 2.45152e-5 | 2.45153e-5 | 2.45149e-5 |
| Wing volume (tool volume_val) | 0.254221 m³ (+2.97 % ✓) | 0.254287 m³ | 0.263592 m³ | 0.246898 m³ |

**Improvement:** (0.020052 − 0.019087) / 0.020052 = **4.81 %**. Lowering the taper from 0.35 to 0.30 at nearly the same volume gained 0.15 points over C007 (CD 0.16 % lower). The screening model over-predicted by 0.28 points, so the 5 % tier is not reached in CFD.

**Line-search data (re-sized family, ~+3 % volume):** taper 0.35 → CD 0.019117 (C007), taper 0.30 → CD 0.019087 (C008). The gain from lower taper is shrinking, consistent with a minimum near or below 0.30.

**Constraints:** CL ≥ 0.4 ✓. V ≥ V_bl ✓ (tool volume 0.254221 vs 0.246898; request expected ≈ 0.2542).

**Fixed-viscosity Re:**
- Input `reynolds_number` = 4,763,576, from an estimated MAC of 0.9527152 m. The tool's actual MAC is 0.9527331 m (error 0.002 %).
- μ = 2.451537e-5 in `thermophysicalProperties`, which matches C000_v2.

## 2. Mesh (locked settings)

| Cells | Max skewness | Max non-orthogonality | Avg non-orthogonality | Max aspect ratio | Severe non-orth faces |
|---|---|---|---|---|---|
| **396,848** ✓ | 1.669 | 62.90° | 10.84° | 238.6 | 0 |

- **Far field:** a 10 m march (`farfield_scale` 7.418 = 10 / c_root).
- **Root plane:** `symmetry` patch.

## 3. y+ and convergence

- **y+:** min 8.57, max 82.77, average 42.34.
- **Residual drop (orders):** p 6.87, U0 9.50, U1 8.81, U2 8.54, he 9.13, nuTilda 8.83. All are ≥ 6 ✓.
- **Converged-tail std:** CD 1.9e-7, CL 3.1e-8. No NaN/Inf.
- **CL search:** α 4.17° → 4.18° → 4.216°, 4 primal runs, 144 iterations total.

## 4. Run notes

- Before the CFD, the mesh geometry's volume was checked in OpenVSP against C000_v2 and C007 (≈ 0.2546 m³ tool-equivalent), so the case passed the volume gate before solver time was spent. The tool's final volume_val confirms it.
- The agent generated the mesh and the CFD case. The unchanged agent run script was then executed in its own Docker container (`c008_cfd`), so MCP reconnects cannot kill the solve. Post-processing completed normally.
- The agent's analyze step produced the metrics and plots.

## 5. Files

Same layout as the earlier packages: metrics JSON, `plots/`, `plot_data/`, `case_files/` (including `thermophysicalProperties`) and `workflow_logs/`.
