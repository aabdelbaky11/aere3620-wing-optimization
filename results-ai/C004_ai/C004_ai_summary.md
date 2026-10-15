# C004_ai — Thick Root + Taper 0.45 Results Package (AI Workflow)

- **Workflow lead:** Kade Wilson (AI Workflow Lead)
- **Tool:** MDO Agent Deck v0.4.6 `wing` agent
- **Agent cases:** mesh `wing_mesh_0004`, CFD `wing_cfd_0004`
- **Run date:** 2026-10-14
- **Status:** **completed**. The agent's analysis review passed.
- **Geometry:** NACA 2415 root, NACA 2412 tip (OpenVSP lofts linearly between them), c_root 1.266 m, c_tip 0.570 m, b/2 3.00 m, sweep 0°, twist 0° (request C004).

## 1. Results (converted to A_ref = 3.00 m²)

| Quantity | **C004** | C002 | C000 (baseline) |
|---|---|---|---|
| **α** (CL target) | **3.880°** (3.88047°) | 5.476° | 5.408° |
| **CL** | **0.40031** (≥ 0.4 ✓) | 0.40053 | 0.40001 |
| **CD** | **0.019210** | 0.019715 | 0.020010 |
| **CD change vs C000** | **−4.00 %** | −1.47 % | — |
| Wing volume (OpenVSP) | **0.262578 m³** (+6.35 % vs C000 AI ✓) | 0.247873 m³ | 0.246898 m³ |

**Reference-area conversion:**
- The agent normalizes forces by the OpenVSP planform area, which is S = 2.754 m² for this planform.
- The solver reported CL = 0.436064 and CD = 0.0209264 on 2.754 m².
- Converted to A_ref = 3.00 m²: CL = 0.436064 × 2.754 / 3.00 = **0.40031**, and CD = 0.0209264 × 2.754 / 3.00 = **0.019210**.
- Design improvement vs C000 (AI workflow): (0.020010 − 0.019210) / 0.020010 = **4.00 %**.

**Volume note:**
- The AI tool's OpenVSP volume for C004 is 6.35 % above its C000 volume.
- The Design Lead's `wingVolume.m` gives +2.0 %. The difference comes from the two volume methods: OpenVSP lofts the 15 %→12 % section change, versus a linear t/c with K = 0.685.
- **Both methods satisfy V ≥ V_bl.**

## 2. Mesh (same locked settings as C000)

**Cell count: 396,848** (spec 360k–440k ✓)

| Quality metric (checkMesh "Mesh OK") | C004 | Agent pass limit |
|---|---|---|
| Max skewness | 1.711 | 4 |
| Max non-orthogonality | 63.28° | 70° |
| Max aspect ratio | 229.4 | 1000 |
| Min cell volume | 8.28e-12 m³ | — |

**Far field:** a 10.0 m march from the wing (`farfield_scale` 7.899 × c_root 1.266 m). The bounding box is x −10.0 → 11.26 m, y 0 → 13.02 m, z −10.04 → +10.09 m.

**Root plane:** `symmetry` patch, half wing.

## 3. y+ (final converged solution)

| min | max | average |
|---|---|---|
| 7.74 | 85.07 | 45.26 |

## 4. Convergence

| Residual drop (orders) | p 6.96 · U0 9.70 · U1 9.13 · U2 8.79 · he 9.40 · nuTilda 8.78 |
|---|---|

- Converged-tail CD std = 3.13e-8 and CL std = 9.4e-9.
- The CL search started from α = 3.53° (Design Lead's value) and converged at 3.880°.
- Plots: `plots/C004_ai_general_residual_cfd.png` and `plots/C004_ai_general_function_cd.png`.

## 5. Run notes

- After meshing, the agent launched the CFD inside its MCP server container. Those processes were stopped within seconds, and the **unchanged agent-generated run script** was relaunched in its own Docker container (`c004_cfd`). This protects the solve from MCP disconnects, which killed C001 and the first C002 attempt.
- The laptop slept from about 19:05 to 21:27. Sleep pauses the container without affecting the solution.
- The agent's analyze step produced the metrics and plots.

## 6. Files

- `C004_ai_cfd_metrics.json`, `C004_ai_mesh_metrics.json`: agent metrics on the tool's planform area; see §1.
- `plots/`: residual, CD/CL/CM histories, surface Cp and U contours, Cp vs x/c at 10 % / 50 % / 90 % span, spanwise plots, and mesh views.
- `plot_data/`: raw plot data.
- `case_files/`: dictionaries, scripts, inputs, run scripts, `wing.vsp3`, and logs.
- `workflow_logs/`: the agent prompt, the audit trail, and the prompt/troubleshooting log.
