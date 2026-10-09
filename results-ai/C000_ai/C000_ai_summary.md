# C000_ai — Baseline Results Package (AI Workflow)

- **Workflow lead:** Kade Wilson (AI Workflow Lead)
- **Tool:** MDO Agent Deck v0.4.6 `wing` agent (DAFoam/OpenFOAM in Docker), driven through Claude Code
- **Agent cases:** mesh `wing_mesh_0001`, CFD `wing_cfd_0001`
- **Run date:** 2026-10-01
- **Status:** **completed**. The agent's analysis review passed. This is the locked AI baseline.

## 1. Results

| Quantity | Value |
|---|---|
| **α_bl** (CL = 0.4) | **5.408°** (5.40752°, from the solver's final `DesignVars:` line) |
| **CL** | **0.400007** |
| **CD_bl** | **0.020010** (0.02001005) |
| CM | 0.07842 |
| Wing volume (OpenVSP, half wing) | 0.246898 m³ (MATLAB `wingVolume.m`: 0.2466 m³) |

α was found with the agent's built-in fixed-lift Newton search: DAFoam `findFeasibleDesign`, relative CL tolerance 1e-3, 4 primal runs starting from 5.4°.

## 2. Mesh

**Cell count: 396,848** (spec 360,000–440,000 ✓)

| Quality metric (OpenFOAM `checkMesh`: "Mesh OK") | Value | Agent pass limit |
|---|---|---|
| Max skewness | **1.753** | 4 |
| Max non-orthogonality | **64.04°** (average 9.75°, 0 severe faces) | 70° |
| Max aspect ratio | **330.1** | 1000 |
| Min cell volume | **2.444e-11 m³** | — |

**Topology:** all-hex O-type mesh, extruded from an OpenVSP surface. Rounded tip cap, 1% chord rounded trailing edge.

## 3. Far-field domain

- The wing surface is marched outward **10.0 m** (`farfield_scale` 10 × c_root 1.0 m).
- **Bounding box:** x = −10.00 → +10.99 m, y = 0 → 13.04 m, z = −10.04 → +10.04 m.
- That is **≈ 21.0 m × 13.0 m × 20.1 m**: about 20 m across in the chordwise and vertical directions, with the wing centered.

## 4. y+ (wall patch `wing`, final converged solution)

| min | max | average |
|---|---|---|
| **5.29** | **90.86** | **46.67** |

- **Target:** y_plus = 70, which sets the first-cell height from M, Re and the mean chord.
- **Near-wall treatment:** wall functions (`nutUSpaldingWallFunction`). Spalding's law is valid across the buffer and log layers.
- **Caveat:** the average and maximum are inside 30–100. The minimum is not. It is local, and where it occurs (likely near the leading edge stagnation point or the tip cap) has not yet been identified.

## 5. Boundary conditions — confirmations requested by the Design Lead

**Symmetry plane: YES.**
- The root plane y = 0 is patch `sym`, type **`symmetry`** (`constant/polyMesh/boundary`).
- The model is a half wing. Forces are integrated on patch `wing` only, so they are **one-semi-span** forces.
- The outer boundary is patch `inout` (far field).

**CL uses A_ref = 3.00 m²: YES for C000.**
- The solver command line passes `-reference_area=3.0` (`case_files/cfd_case/bash_run-cfd-simulation_run_001.sh`).
- So CL = L/(q·3.00) and CD = D/(q·3.00), with L normal and D parallel to the freestream.

**Important for later cases:**
- The agent always uses the **OpenVSP planform area** as the reference area. A user override is ignored.
- For C000 that equals 3.00 m² exactly.
- For C001/C002/C004 the planform area ≠ 3.00 m². The AI workflow therefore scales the lift target to 0.4005 × 3.00 / S_vsp and converts the reported CL and CD back to A_ref = 3.00 m².
- The reference *length* passed is the OpenVSP MAC (0.99131 m). It only affects CM, and Re slightly (see §7).

## 6. Convergence evidence

| Residual (first → last) | Drop (orders) |
|---|---|
| p | 7.67 |
| U0 / U1 / U2 | 9.48 / 8.65 / 8.34 |
| he (energy) | 8.84 |
| nuTilda | 9.43 |

- All exceed the required 6 orders.
- Converged-tail CD std = 4.75e-8 and CL std = 6.71e-8, so both are steady to about 6 significant digits.
- Plots: `plots/C000_ai_general_residual_cfd.png` and `plots/C000_ai_general_function_cd.png` (also `_cl`, `_cm`).
- The residual spikes in the history plot are the α updates of the CL = 0.4 search.

## 7. Solver / model settings (locked for all AI cases)

- **Solver:** DAFoam `DARhoSimpleFoam` (steady compressible RANS).
- **Turbulence model:** Spalart-Allmaras, with wall functions.
- **Inputs:** M = 0.30 and Re = 5.0e6.
- **Freestream:** the agent builds it from T0 = 300 K. That gives U = 104.16 m/s, ρ ≈ 1.177 kg/m³, p = 101325 Pa and q ≈ 6383 Pa.
  - M and Re match the spec. U and ρ differ slightly from the spec's 102 m/s and 1.20 kg/m³.
  - Coefficients depend only on M and Re, so they are unaffected.
- **Re length:** viscosity uses the OpenVSP MAC (0.9913 m), so Re based on c_ref = 1.00 m is ≈ 5.04e6.
- **Mesh settings:** mesh_cells = 360000 (actual ≈ 397k), y_plus = 70, farfield_scale = 10 × (1.0 / c_root), giving a 10 m march for every design.
- **Stopping:** primal_func_std_tol = 1e-6, max_flow_iters = 1500, 10 MPI ranks.
- **Exact prompt:** `workflow_logs/C000_ai_prompt_final.txt`.

## 8. α_bl is ~0.5° higher than the Conventional workflow and lifting line

**Observed:**
- AI lift-curve slope ≈ 0.4 / 5.408° = 0.0740 /deg.
- **Not tuned, per request §7.** Documented as a workflow-comparison finding.

**Checked and ruled out:**
- Symmetry plane is correct.
- A_ref = 3.00 m² is correct for C000.
- α is the freestream angle relative to the untwisted root chord. The mesh is built at zero incidence and α is applied through the inflow vector (Ux = U cos α, Uz = U sin α).

**Possible contributors (not yet tested):**
1. **Far field.** The far field is only ~10 chords from the wing. With a fixed-velocity outer boundary, a close far field reduces circulation and lift slope.
2. **Trailing edge.** The rounded 1%-chord blunt TE plus wall-function boundary layer reduces effective lift near the TE.
3. **Lifting line.** Lifting line uses an inviscid 2D slope, so it over-predicts slope relative to RANS.

**Suggested check (Design Lead's call):**
- Re-run C000 with a larger far field to see how much of the 0.5° it explains.
- Compare domain size and shape with the Conventional Lead's STAR-CCM+ setup.

## 9. Files in this package

- `C000_ai_cfd_metrics.json`, `C000_ai_mesh_metrics.json`: the agent's analysis metrics.
- `plots/`: residual, CD/CL/CM histories, surface Cp and U contours, Cp vs x/c at 10% / 50% / 90% span (root / mid / tip), spanwise lift/chord/thickness/twist, and mesh views.
- `plot_data/`: raw data behind each plot. Cp `.dat` columns are x/c, z/c, Cp.
- `case_files/mesh_case`, `case_files/cfd_case`: OpenFOAM `system/` and `constant/` dictionaries, agent scripts, `case_info.json`, `advanced_parameters.json`, the generated run scripts, `wing.vsp3`, and the mesh and solver logs.
  - The full mesh (~100 MB) and VTK output (~70 MB) are not committed. They regenerate from these files and the prompt.
- `workflow_logs/`: the agent prompt(s), the agent audit trail (`agent_workflow.json`), and the AI Workflow Lead's prompt and troubleshooting log.

**Cp stations:** "root", "mid-span" and "tip" are 10%, 50% and 90% of the semi-span. These can be regenerated at other stations without re-running the CFD.
