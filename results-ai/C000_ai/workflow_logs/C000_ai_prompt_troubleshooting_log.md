# AI Workflow Lead — Agent Prompt & Troubleshooting Log (Team 18)

The spec requires the AI Workflow Lead to "record the agent prompts and troubleshooting."

The AI client is Claude Code (desktop app). It is connected to the MDO Agent Deck MCP server, which runs in Docker (`dafoam/agent:latest`). The work dir is `mdo_agent_work/results`.

Raw Claude Code transcripts (`~/.claude/projects/...jsonl`) contain personal account info. Do NOT commit them to the team repo. Export the relevant excerpts instead.

---

## 2026-09-17 — Week 1 practice run
- **Prompt (summary):** generate a CFD mesh for the NACA 2412 airfoil with 20k cells and y+ 3.
- **Agent path:** airfoil / generate-cfd-mesh, scenario single-skill-single-run. The run took 153 s.
- **Result:** 20,792 cells, max non-orthogonality 42.2, max skewness 0.39, max aspect ratio 505.
- **Lesson:** Mach was not specified, so the tool silently used its default of M = 0.2. **Every setting must be named explicitly in the prompt.**

## 2026-09-25 — Project/tool study and C000 preparation
- **Tool study:**
  - Inventoried the tool's 14 agent/skill pairs. The `wing` agent chain for this project is generate-cfd-mesh → run-cfd-simulation.
  - Mapped every spec requirement to agent inputs and advanced parameters.
  - Found tool defaults that conflict with the spec: Mach 0.2, 200k cells, 1 CPU core, far field 20 × root chord, and a loose convergence stop (primal_func_std_tol 0.04).
  - Confirmed that the tool normalizes by the OpenVSP planform area rather than A_ref.
- **Problem:** the Claude Code client could not connect to the `mdo_agent_deck` MCP server.
  - Error: `connection timed out after 30000ms`.
  - The Docker container did start.
- **Diagnosis:**
  - `docker info` reports Architecture aarch64. The laptop has a Snapdragon X Elite (ARM64) processor.
  - The `dafoam/agent` image is x86-64, so every process runs under QEMU emulation (`/usr/bin/qemu-x86_64`).
  - Measured server startup is 31.5–36.2 s: about 1.5 s container start, 4.4 s `loadDAFoam.sh`, and 27 s of Python imports (openmdao alone is 18.5 s).
  - The startup exceeds Claude Code's 30 s default.
- **Fix:**
  - Set `MCP_TIMEOUT=120000` in `~/.claude/settings.json` (`env` block) and as a Windows user environment variable.
  - Restarted the app and reconnected the server.
- **Consequence to track:** CFD will also run under emulation and be much slower than on an x86 PC. Time every run.
- **Locked settings:** see `C000_ai_locked_settings.md`.
- **C000 prompt sent to the agent:** see `C000_ai_prompt.txt`.

## C000 run log (fill in as it progresses)
| Time | Event | Notes |
|---|---|---|
| 2026-09-25 ~16:40 CDT | Reconnected mdo_agent_deck via /mcp after setting MCP_TIMEOUT. It connected successfully. | Timeout fix confirmed |
| 16:45 CDT | Prompt sent (C000_ai_prompt.txt). must_call_first → get_skill_input_info → get_skill_advanced_parameters → verify_workflow returned `format_verified`, with a one-to-one prompt/payload review passed → run_workflow | workflow_id `wf-single-skill-with-prereq-single-run-20260925T214514Z` |
| 16:45 CDT | Mesh case `wing_mesh_0000` started (detached). The first pass returned `monitor_timeout` after 266 s, which is normal for long runs. | At 16:49 the OpenVSP geometry (wing.vsp3/.xyz/.stl) was written and the volume mesh was in progress |
| ~17:00 CDT | Mesh finished and review_analyze passed: 445,880 cells, max non-orth 63.8, max skew 1.76, max AR 383, min vol 1.66e-11. Bounding box x −10.0…11.0, y 0…13.05, z ±10.04 m. | **Cell count is 1.3% over the 440k limit** (tool overshoot +11.5% vs the 400k request). Remesh with mesh_cells ≈ 360000 for the reported case |
| ~17:00 CDT | CFD case `wing_cfd_0000` started (fixed_lift_coeff 0.4, 10 cores) | Treated as a pilot run (timing and convergence) |
| | CFD finished (α_bl, C_L, C_D, residual drop) | |

## 2026-10-01 — C000 pilot review and corrected rerun
- **Pilot `wing_cfd_0000`** (445,880-cell mesh): at α = 5.0°, CL = 0.3707 and CD = 0.01848. Pressure residual fell 1.0 → 1.66e-7 (about 6.8 orders; 6 orders reached at iteration 400). y+ min/max/mean = 4.0 / 65.8 / 33.5.
- **Why it took 58 h wall time:**
  1. The laptop slept for 48 h at iteration 50. Wall time was 173,036 s while CPU time was only 71 s.
  2. The p residual plateaued at 1.66e-7, just above the hard-coded stop of 1e-7. With primal_func_std_tol = 1e-8, the force-based stop could never trigger, so the run kept iterating past convergence until Docker stopped (09-28 03:22).
- **Actual compute rate:** about 5–8 s per iteration while awake.
- **Fixes:**
  - Turned on the app's keep-awake.
  - primal_func_std_tol 1e-8 → 1e-6 (CD/CL steady to 5+ digits), max_flow_iters 10000 → 1500.
  - mesh_cells 400000 → 360000 (the tool overshoots by ~11.5%; target ~401k).
  - y_plus 50 → 70 (the pilot's achieved y+ was ~0.67× the target; this moves the distribution into 30–100).
  - Starting AoA 5.4° (from the pilot's linear estimate).
- **15:53 CDT:** the agent ran a new workflow, `wf-single-skill-with-prereq-single-run-20261001T205311Z`. Its mesh case `wing_mesh_0001` started and returned monitor_timeout (normal).
- **~16:10 CDT:** `wing_mesh_0001` passed the agent's mesh review: **396,848 cells** (inside 360k–440k), max non-orthogonality 64.0, max skewness 1.75, max aspect ratio 330, min volume 2.44e-11 m³. The CFD case `wing_cfd_0001` (CL = 0.4 trim, starting at 5.4°) started.
- **Evening 10-01:** workflow **completed**. review_analyze **pass**.
  - α_bl = 5.4075° (last `DesignVars:` line). CL = 0.400007, CD = 0.020010, CM = 0.07842.
  - Wing volume (OpenVSP) = 0.246898 m³.
  - Residual drop (orders): U0 9.48, U1 8.65, U2 8.34, he 8.84, nuTilda 9.43, p 7.67. All are ≥ 6.
  - CD std 4.75e-8, CL std 6.71e-8.
  - y+ min/max/mean = 5.29 / 90.86 / 46.67.
  - The Newton search used 3 primal solves (α 5.4 → 5.4075). Total ≈ 900 iterations.

## 2026-10-05 — C001 (camber only)
- **Prompt:** `C001_ai_prompt.txt`. Same locked settings as C000, with three changes:
  - Lift target scaled to 0.3966: tool area S_vsp = 3.030 m², so 0.4005 × 3/3.030. The 0.0005 margin covers the 0.1% trim tolerance.
  - farfield_scale 9.901 keeps a 10 m march distance.
  - Starting α 2.77°, the Design Lead's lifting-line estimate.
- **First attempt:** verify_workflow passed format, but I stopped before running. The user's message ("run C001 and C002") did not name explicit values, which the agent's one-to-one prompt review requires. I wrote explicit prompt files, and the user pasted the C001 prompt.
- **Launch:** workflow `wf-single-skill-with-prereq-single-run-20261006T013814Z` started. Mesh case `wing_mesh_0002` is running; first pass returned monitor_timeout (normal).
