#!/usr/bin/env python

import argparse
import json
import os
import re

from mdo_agent_wing import WingGenerateCFDMesh
from mdo_agent_wing import WingGenerateFEAMesh
from mdo_agent_wing import WingRunAeroOptimization
from mdo_agent_wing import WingRunAeroStructOptimization
from mdo_agent_wing import WingRunAeroStructSimulation
from mdo_agent_wing import WingRunCFDSimulation
from mdo_agent_deck import copy_solver_files
from mdo_agent_deck import convert_vsp3_to_cst
from mdo_agent_deck import export_optimization_boundary_vtks
from mdo_agent_deck import export_optimization_structural_vtks
from mdo_agent_deck import extract_opt_hst_data
from mdo_agent_deck import read_opt_hst
from mdo_agent_deck import resolve_section_cst_coeffs
from mdo_agent_deck import stage_warm_start_field
from mdo_agent_deck import write_turbulence_model


def main():
    parser = argparse.ArgumentParser(
        description="Workflow helper commands for wing skill prepare/analyze phases."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    copy_parser = subparsers.add_parser("copy-solver-files")
    copy_parser.add_argument("--solver-name", required=True)

    prep_parser = subparsers.add_parser("prepare-wing-case")
    prep_parser.add_argument("--airfoil-profiles", nargs="+", required=True)
    prep_parser.add_argument("--profile-fit-coeff-count", required=True, type=int)
    prep_parser.add_argument("--solver-name", required=True)
    prep_parser.add_argument("--turbulence-model", default="SpalartAllmaras")
    prep_parser.add_argument("--case-dir", default=".")
    prep_parser.add_argument("--cst-coeffs", nargs="+", type=float, default=None)

    warm_start_parser = subparsers.add_parser("stage-warm-start")
    warm_start_parser.add_argument("--initialize-from", required=True)
    warm_start_parser.add_argument("--case-dir", default=".")

    mesh_parser = subparsers.add_parser("write-mesh-analysis")
    mesh_parser.add_argument("--log-file", required=True)
    mesh_parser.add_argument("--metrics-file", required=True)
    mesh_parser.add_argument("--analysis-file", required=True)

    fea_parser = subparsers.add_parser("write-fea-mesh-analysis")
    fea_parser.add_argument("--analysis-file", required=True)

    cfd_parser = subparsers.add_parser("write-cfd-analysis")
    cfd_parser.add_argument("--log-file", required=True)
    cfd_parser.add_argument("--output-file", required=True)

    aero_struct_parser = subparsers.add_parser("write-aero-struct-analysis")
    aero_struct_parser.add_argument("--log-file", required=True)
    aero_struct_parser.add_argument("--output-file", required=True)
    aero_struct_parser.add_argument("--script-file", default="script_run_dafoam_aero_struct.py")
    aero_struct_parser.add_argument("--nlbgs-rel-tol", type=float, default=None)
    aero_struct_parser.add_argument("--nlbgs-abs-tol", type=float, default=None)

    aero_struct_opt_parser = subparsers.add_parser("write-aero-struct-optimization-analysis")
    aero_struct_opt_parser.add_argument("--log-file", required=True)
    aero_struct_opt_parser.add_argument("--output-file", required=True)
    aero_struct_opt_parser.add_argument("--hist-file", default=None)
    aero_struct_opt_parser.add_argument("--scaling-report-file", default=None)
    aero_struct_opt_parser.add_argument("--profile-fit-coeff-count", type=int, default=6)
    aero_struct_opt_parser.add_argument("--n-sections", type=int, required=True)

    opt_parser = subparsers.add_parser("write-optimization-analysis")
    opt_parser.add_argument("--log-file", required=True)
    opt_parser.add_argument("--output-file", required=True)
    opt_parser.add_argument("--hist-file", default=None)
    opt_parser.add_argument("--scaling-report-file", default=None)
    opt_parser.add_argument("--profile-fit-coeff-count", type=int, default=6)
    opt_parser.add_argument("--n-sections", type=int, required=True)

    export_opt_vtk_parser = subparsers.add_parser("export-optimization-boundary-vtks")
    export_opt_vtk_parser.add_argument("--case-dir", default=".")

    export_struct_vtk_parser = subparsers.add_parser("export-optimization-structural-vtks")
    export_struct_vtk_parser.add_argument("--case-dir", default=".")

    args = parser.parse_args()

    if args.command == "copy-solver-files":
        copy_solver_files(".", args.solver_name)
        return
    if args.command == "prepare-wing-case":
        cst_coeffs = args.cst_coeffs
        if cst_coeffs is None:
            cst_coeffs = resolve_section_cst_coeffs(
                args.airfoil_profiles,
                int(args.profile_fit_coeff_count),
                args.case_dir,
            )
        convert_vsp3_to_cst(
            args.case_dir,
            int(args.profile_fit_coeff_count),
            "wing.vsp3",
            "Wing",
            xsec_indices=range(len(args.airfoil_profiles)),
        )
        copy_solver_files(args.case_dir, args.solver_name)
        write_turbulence_model(args.case_dir, args.turbulence_model)
        return
    if args.command == "stage-warm-start":
        # Stage the source field at run time so HPC batches can chain cases sequentially.
        case_dir = os.path.abspath(args.case_dir)
        record = stage_warm_start_field(args.initialize_from, os.path.dirname(case_dir), case_dir)
        with open(os.path.join(case_dir, "warmstart.json"), "w", encoding="utf-8") as handle:
            json.dump(record, handle, indent=2, sort_keys=True)
        return
    if args.command == "export-optimization-boundary-vtks":
        export_optimization_boundary_vtks(
            case_dir=args.case_dir,
            patches="(wing sym)",
            fields="(U p T rho nut forcePerS)",
        )
        return
    if args.command == "export-optimization-structural-vtks":
        export_optimization_structural_vtks(case_dir=args.case_dir)
        return

    if args.command == "write-mesh-analysis":
        skill = WingGenerateCFDMesh()
        metrics = skill.parse_mesh_log(args.log_file)
        with open(args.metrics_file, "w", encoding="utf-8", errors="ignore") as handle:
            json.dump(metrics, handle, indent=2, sort_keys=True)

        analysis = {
            "outputs": [],
            "plots": [],
        }
        for filename in [
            "constant/polyMesh",
            "VTK/boundary.vtp",
        ]:
            if os.path.exists(filename):
                analysis["outputs"].append(filename)
        if os.path.isdir("plots"):
            case_name = os.path.basename(os.getcwd())
            for plot_name in sorted(os.listdir("plots")):
                if plot_name.lower().endswith(".png"):
                    analysis["plots"].append(os.path.join(case_name, "plots", plot_name))
        with open(args.analysis_file, "w", encoding="utf-8", errors="ignore") as handle:
            json.dump(analysis, handle, indent=2, sort_keys=True)
        return

    if args.command == "write-fea-mesh-analysis":
        analysis = {
            "outputs": [],
            "plots": [],
        }
        for filename in ["wingbox.bdf", "wingbox.dat"]:
            if os.path.exists(filename):
                analysis["outputs"].append(filename)
        if os.path.isdir("plots"):
            case_name = os.path.basename(os.getcwd())
            for plot_name in sorted(os.listdir("plots")):
                if plot_name.lower().endswith(".png"):
                    analysis["plots"].append(os.path.join(case_name, "plots", plot_name))
        with open(args.analysis_file, "w", encoding="utf-8", errors="ignore") as handle:
            json.dump(analysis, handle, indent=2, sort_keys=True)
        return

    if args.command == "write-cfd-analysis":
        skill = WingRunCFDSimulation()
        metrics = skill.build_convergence_metrics(skill.parse_simulation_log(args.log_file))
    elif args.command == "write-aero-struct-analysis":
        skill = WingRunAeroStructSimulation()
        metrics = skill.build_aero_struct_metrics(
            skill.parse_aero_struct_log(args.log_file),
            script_file=args.script_file,
            nlbgs_rel_tol=args.nlbgs_rel_tol,
            nlbgs_abs_tol=args.nlbgs_abs_tol,
        )
    elif args.command == "write-aero-struct-optimization-analysis":
        skill = WingRunAeroStructOptimization()
        metrics = skill.parse_optimization_log(args.log_file)
        if args.hist_file and args.scaling_report_file:
            metrics.update(
                extract_wing_opt_hst_designs(
                    args.hist_file,
                    args.scaling_report_file,
                    args.profile_fit_coeff_count,
                    args.n_sections,
                )
            )
    else:
        skill = WingRunAeroOptimization()
        metrics = skill.parse_optimization_log(args.log_file)
        if args.hist_file and args.scaling_report_file:
            metrics.update(
                extract_wing_opt_hst_designs(
                    args.hist_file,
                    args.scaling_report_file,
                    args.profile_fit_coeff_count,
                    args.n_sections,
                )
            )

    # Surface, history, and pressure-profile plot companions are written under `plots/data`.
    metrics["plot_raw_data_dir"] = os.path.join(os.path.basename(os.getcwd()), "plots", "data")
    with open(args.output_file, "w", encoding="utf-8", errors="ignore") as handle:
        json.dump(metrics, handle, indent=2, sort_keys=True)


def extract_wing_opt_hst_designs(hist_file, scaling_report_file, profile_fit_coeff_count, n_sections):
    """Extract baseline and optimized physical wing designs from optimization history."""
    history = read_opt_hst(hist_file, scaling_report_file)
    if not history:
        return {}

    cst_names = [
        f"Wing:{surface}Coeff_{section}:{prefix}_{index}"
        for section in range(n_sections)
        for surface, prefix in (("Upper", "Au"), ("Lower", "Al"))
        for index in range(profile_fit_coeff_count)
    ]
    section_names = lambda variable: [
        f"Wing:XSec_{section}:{variable}"
        for section in range(1, n_sections)
    ]
    # Each multipoint scenario owns a patchV{i} design variable; retain its AoA separately.
    patch_v_names = sorted(
        (name for name in history[0]["design_variables"] if re.fullmatch(r"patchV\d+", name)),
        key=lambda name: int(name.removeprefix("patchV")),
    )
    variables = [
        {
            "key": f"angle_of_attack_{name.removeprefix('patchV')}",
            "source": "design_variables",
            "name": name,
            "index": 1,
        }
        for name in patch_v_names
    ] + [
        {"key": "cst_coeffs", "source": "design_variables", "names": cst_names},
        {"key": "twists", "source": "design_variables", "names": section_names("Twist")},
        {"key": "spans", "source": "design_variables", "names": section_names("Span")},
        {"key": "sweeps", "source": "design_variables", "names": section_names("Sweep")},
        {"key": "dihedrals", "source": "design_variables", "names": section_names("Dihedral")},
        {
            "key": "chords",
            "source": "design_variables",
            "names": ["Wing:XSec_1:Root_Chord"] + section_names("Tip_Chord"),
        },
    ]
    designs = extract_opt_hst_data(history, variables, record_indices=[0, -1])
    return {
        "baseline_design_variables": {key: value for key, value in designs[0].items() if key != "iteration"},
        "optimized_design_variables": {key: value for key, value in designs[1].items() if key != "iteration"},
    }


if __name__ == "__main__":
    main()
