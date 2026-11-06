#!/usr/bin/env python

from mpi4py import MPI

# Importing the case constructs the same OpenMDAO problem on every MPI rank.
from script_run_dafoam import args, optFuncs, prob
from mdo_agent_deck.base import print_design_summary
from mdo_agent_deck.base.ego import ego_optimizer

# Build the per-condition feasibility inputs created by the multipoint runner.
n_points = len(args.lift_constraint)
lift_names = [f"scenario{i}.aero_post.CL" for i in range(n_points)]
patch_v_names = [f"patchV{i}" for i in range(n_points)]

optFuncs.findFeasibleDesign(
    lift_names,
    patch_v_names,
    targets=args.lift_constraint,
    designVarsComp=[1] * n_points,
    epsFD=[1e-2] * n_points,
    tol=args.ego_cstr_tol,
)
getattr(prob.model, f"scenario{n_points - 1}").coupling.solver.DASolver.renameSolution(1)
print_design_summary("baseline", prob, MPI.COMM_WORLD)

# Configure identical serial-EGO controls on every process; rank zero alone
# will use them for sampling, surrogate fitting, and infill optimization.
optimizer = ego_optimizer(
    prob,
    n_doe=args.n_ego_doe_pts,
    ego_n_iters=args.max_opt_iters,
    seed=args.ego_seed,
    n_multi_start=args.n_multi_start,
    cstr_tol=args.ego_cstr_tol,
    ei_tol=args.ei_tol,
    ego_tol=args.ego_tol,
)

# Enter the shared control flow so every expensive model call is collective.
optimizer.run()

optFuncs.findFeasibleDesign(
    lift_names,
    patch_v_names,
    targets=args.lift_constraint,
    designVarsComp=[1] * n_points,
    epsFD=[1e-2] * n_points,
    tol=args.ego_cstr_tol,
)
getattr(prob.model, f"scenario{n_points - 1}").coupling.solver.DASolver.renameSolution(2)
print_design_summary("optimized", prob, MPI.COMM_WORLD)

if MPI.COMM_WORLD.rank == 0:
    # Persist the optimized wing geometry just like the pyOptSparse driver path.
    prob.model.geometry.nom_getDVGeo().writeVSPFile("wing_opt.vsp3")
