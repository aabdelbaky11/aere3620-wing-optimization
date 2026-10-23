# C004_ai_v2 — Thick Root + Taper 0.45, Re-run at Fixed Viscosity (AI Workflow)

- **Workflow lead:** Kade Wilson (AI Workflow Lead)
- **Request:** `requests/request_C000_C004_rerun_fixedmu.md`
- **Agent cases:** mesh `wing_mesh_0006`, CFD `wing_cfd_0006`
- **Run date:** 2026-10-22/23
- **Status:** **completed**. The agent's analysis review passed.
- **Original run:** `results-ai/C004_ai/` is kept unchanged for the workflow comparison.
- **Geometry:** identical to C004 — NACA 2415 root, NACA 2412 tip, c_root 1.266 m, c_tip 0.570 m, b/2 3.00 m, sweep 0°, twist 0°.

## 1. Results — the validated AI-workflow improvement

All values are on A_ref = 3.00 m². The tool normalizes by S_vsp = 2.754 m², so its values are multiplied by 2.754/3.00.

| Quantity | **C004_ai_v2** | C000_ai_v2 (baseline) | C004_ai (original μ) |
|---|---|---|---|
| α | **3.889°** (3.88906°) | 5.415° | 3.880° |
| **CL** | **0.40053** (≥ 0.4 ✓) | 0.40051 | 0.40031 |
| **CD** | **0.019308** | 0.020052 | 0.019210 |
| **Design improvement** | **3.71 %** | — | 4.00 % (vs C000_ai, invalid: μ drift) |
| μ (thermophysicalProperties) | 2.451491e-5 ✓ | 2.451491e-5 ✓ | 2.3385e-5 |
| Wing volume (OpenVSP) | 0.262578 m³ (+6.35 % vs V_bl ✓) | 0.246898 m³ | 0.262578 m³ |

**How the improvement is computed:** (0.020052 − 0.019308) / 0.020052 = **3.71 %**.

**Constraints:**
- CL ≥ 0.4 ✓.
- V ≥ V_bl ✓, with both the OpenVSP volume and the Design Lead's wingVolume.m (+2.0 %).

**Effect of the viscosity fix:** fixing μ removed 0.29 points from C004's improvement (4.00 % → 3.71 %). That is in line with the Design Lead's estimate of about 0.3 points.

## 2. Mesh (identical to C004_ai)

| Cells | Max skewness | Max non-orthogonality | Max aspect ratio |
|---|---|---|---|
| **396,848** ✓ | 1.711 | 63.28° | 229.4 |

- **Far field:** a 10 m march (`farfield_scale` 7.899).
- **Root plane:** `symmetry` patch.
- **Re change:** only the CFD skill's Re was changed (`reynolds_number` = 4,769,482 = 5e6 × MAC 0.9538963). The mesh prerequisite stays at 5e6.

## 3. y+ and convergence

- **y+:** min 7.53, max 81.49, average 43.37.
- **Residual drop (orders):** p 6.96, U0 9.44, U1 8.53, U2 8.34, he 8.95, nuTilda 8.88. All are ≥ 6 ✓.
- **Converged-tail std:** CD 4.0e-7, CL 5.5e-8.

## 4. Run notes

- The CFD was moved out of the agent's MCP container into its own Docker container, using the unchanged agent-generated run script.
- The solve converged. Then Docker Desktop's x86 emulation failed and the post-processing commands stopped with "Exec format error".
- After a Docker Desktop restart, the remaining lines of the agent's run script were re-run: `reconstructPar`, `foamToVTK` and the completion marker. The agent's analyze step then passed.
- No CFD iterations were repeated or altered.

## 5. Files

- `C004_ai_v2_cfd_metrics.json`: on the tool's planform area; see §1.
- `C004_ai_v2_mesh_metrics.json`.
- `plots/`.
- `plot_data/`.
- `case_files/`: includes `constant/thermophysicalProperties` with μ.
- `workflow_logs/`.
