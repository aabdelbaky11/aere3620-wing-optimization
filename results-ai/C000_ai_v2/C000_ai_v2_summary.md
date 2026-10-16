# C000_ai_v2 — Baseline Re-run at Fixed Viscosity (AI Workflow)

- **Workflow lead:** Kade Wilson (AI Workflow Lead)
- **Request:** `requests/request_C000_C004_rerun_fixedmu.md`
- **Agent cases:** mesh `wing_mesh_0005`, CFD `wing_cfd_0005`
- **Run date:** 2026-10-16
- **Status:** **completed**. The agent's analysis review passed.
- **Original run:** the first C000 run is kept unchanged in `results-ai/C000_ai/` for the workflow-comparison section.

## 1. What changed vs C000_ai

| | C000_ai (original) | **C000_ai_v2** |
|---|---|---|
| CFD `reynolds_number` input | 5.0e6 (applied on tool MAC 0.99131 m) | **4,956,570** = 5.0e6 × 0.9913141 |
| μ in `constant/thermophysicalProperties` | 2.4302e-5 | **2.451491e-5** ✓ (target 2.4515e-5) |
| Re based on c_ref = 1.00 m | 5.04e6 | **5.00e6** |
| Lift target | CL = 0.4 | **CL = 0.4005** (Design Lead rule 0.4005 × 3.00 / S_vsp; S_vsp = 3.00 m²) |
| Mesh | `wing_mesh_0001` | `wing_mesh_0005`, identical inputs and identical result |

**Only the CFD skill's Reynolds number was changed.** The mesh prerequisite kept reynolds_number = 5.0e6, so the first-cell height and the whole mesh are the same as the locked C000 mesh. Everything else is unchanged: geometry, y+ target 70, wall functions, solver, M = 0.3 and the far field.

## 2. Results (S_vsp = A_ref = 3.00 m², no conversion needed)

| Quantity | **C000_ai_v2** | C000_ai (original) |
|---|---|---|
| **α_bl** | **5.415°** (5.41482°) | 5.408° |
| **CL** | **0.40051** | 0.40001 |
| **CD_bl** | **0.020052** (0.02005210) | 0.020010 |
| CM | 0.07853 | 0.07842 |
| Wing volume (OpenVSP) | 0.246898 m³ | 0.246898 m³ |

CD_bl went up 0.21 % compared with the original. There are two causes:
- Re on c_ref dropped from 5.04e6 to 5.00e6, which raises skin friction.
- The lift target rose from 0.4000 to 0.4005, which adds a little induced drag.

**CD_bl = 0.020052 is the new AI-workflow baseline for every improvement percentage.**

## 3. Mesh

| Cells | Max skewness | Max non-orthogonality | Max aspect ratio | Min cell volume |
|---|---|---|---|---|
| **396,848** ✓ | 1.753 | 64.04° | 330.1 | 2.444e-11 m³ |

- **Far field:** a 10 m march, giving a bounding box of x −10.0 → 10.99 m, y 0 → 13.04 m, z ±10.04 m.
- **Root plane:** `symmetry` patch, half wing.

## 4. y+ and convergence

- **y+ on the wing:** min 5.27, max 90.19, average 46.31.
- **Residual drop (orders):** p 7.65, U0 9.41, U1 8.57, U2 8.27, he 8.75, nuTilda 9.40. All are at least 6 ✓.
- **Converged-tail CD std:** 6.9e-8.
- **CL search:** 4 primal runs, from 5.408° to 5.4148°.

## 5. Run notes

- The mesh finished on 10-15 at 22:44.
- The CFD first started inside the agent's MCP container and died when that container restarted (log kept as `case_files/cfd_case/log_simulation_attempt1_crashed.txt`).
- The **unchanged agent-generated run script** was relaunched in its own Docker container. The run was paused once, which has no effect on the solution.
- The agent's analyze step produced the metrics and plots.

## 6. Files

Same layout as `C000_ai`:
- `C000_ai_v2_cfd_metrics.json` and `C000_ai_v2_mesh_metrics.json`
- `plots/`: residual, CD/CL/CM histories, Cp contour, Cp at 10 / 50 / 90 % span, spanwise plots and mesh views
- `plot_data/`
- `case_files/`: includes `constant/thermophysicalProperties` with the μ value
- `workflow_logs/`: the prompt, the agent audit trail and the troubleshooting log
