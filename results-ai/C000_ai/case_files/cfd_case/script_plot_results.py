#!/usr/bin/env python

import argparse
import os
import subprocess

from mdo_agent_deck import (
    general_create_image_html,
    general_html_view,
    general_plot_function,
    general_plot_optimization_history,
    general_plot_residual,
    general_trame_view,
    wing_plot_flow_field,
    wing_plot_mesh,
    wing_plot_pressure_profile,
    wing_plot_spanwise_variable,
    wing_plot_wingbox_mesh,
    plot_fea_fields,
)


# These modes create a VTK render window and can hang on nodes without a usable
# graphics backend. Data-extraction and Matplotlib-only modes remain available.
VTK_RENDER_MODES = {
    "wing_plot_mesh",
    "wing_plot_wingbox_mesh",
    "plot_fea_fields",
    "wing_plot_flow_field",
}


def _skip_vtk_plots():
    """Return whether the environment requests VTK renderer plots be skipped.

    ``AGENT_DECK_SKIP_VTK_PLOT=1`` skips only modes in ``VTK_RENDER_MODES``;
    an unset variable defaults to ``0`` and preserves existing behavior.
    """
    value = os.environ.get("AGENT_DECK_SKIP_VTK_PLOT", "0").strip().lower()
    if value in {"1", "true", "yes", "on"}:
        return True
    if value in {"0", "false", "no", "off"}:
        return False
    raise ValueError(
        "AGENT_DECK_SKIP_VTK_PLOT must be one of: 0, 1, false, true, no, yes, off, on."
    )


def parse_args():
    parser = argparse.ArgumentParser(description="Thin mdo_agent_deck plotting wrapper for case-local wing plotting.")
    parser.add_argument("-mode", type=str, required=True)
    parser.add_argument("-input_files", type=str, nargs="+", default=None)
    parser.add_argument("-image_files", type=str, nargs="+", default=None)
    parser.add_argument("-html_filename", type=str, default="results.html")
    parser.add_argument("-port", type=int, default=8002)
    parser.add_argument("-case_dir", type=str, default=".")
    parser.add_argument("-camera_scale", type=float, default=1.0)
    parser.add_argument("-image_width", type=int, default=1920)
    parser.add_argument("-image_height", type=int, default=1150)
    parser.add_argument("-flow_field", type=str, default="p")
    parser.add_argument("-log_file", type=str, default="log_simulation.txt")
    parser.add_argument("-hist_file", type=str, default="OptView.hst")
    parser.add_argument("-optimizer_log", type=str, default="opt_Uno.txt")
    parser.add_argument("-start_time", type=int, default=0)
    parser.add_argument("-end_time", type=int, default=-1)
    parser.add_argument("-tail_fraction", type=float, default=1.0)
    parser.add_argument("-start_time_cfd", type=int, default=0)
    parser.add_argument("-end_time_cfd", type=int, default=-1)
    parser.add_argument("-start_time_adjoint", type=int, default=0)
    parser.add_argument("-end_time_adjoint", type=int, default=-1)
    parser.add_argument("-time_step", type=int, default=-1)
    parser.add_argument("-wing_span", type=float, default=1.0)
    parser.add_argument("-spanwise_chords", type=float, nargs="+", default=[1.0, 1.0, 1.0])
    parser.add_argument("-spanwise_x", type=float, nargs="+", default=[0.0, 0.0, 0.0])
    parser.add_argument("-spanwise_fractions", type=float, nargs="+", default=None)
    parser.add_argument("-mesh_file", type=str, nargs="+", default=["VTK/boundary.vtp"])
    parser.add_argument("-reference_pressure", type=float, default=None)
    parser.add_argument("-pressure_coefficient_scale", type=float, default=None)
    parser.add_argument("-var_ref", type=float, default=None)
    parser.add_argument("-var_scaling", type=float, default=None)
    parser.add_argument("-field_label", type=str, default=None)
    parser.add_argument("-var_lower", type=float, default=None)
    parser.add_argument("-var_upper", type=float, default=None)
    parser.add_argument("-colormap", type=str, default="coolwarm")
    parser.add_argument("-geometry_file", type=str, default="wing.stl")
    parser.add_argument("-vtp_file", type=str, nargs="+", default=["VTK/boundary.vtp"])
    parser.add_argument("-angle_of_attack", type=float, nargs="+", default=None)
    parser.add_argument("-n_slices", type=int, default=20)
    parser.add_argument("-fea_field", type=str, default=None)
    parser.add_argument("-wingbox_output_file", type=str, default="wingbox_mesh_view.png")
    parser.add_argument("-wingbox_vtk_file", type=str, default="scenario0_000.vtk")
    parser.add_argument("-wingbox_surface_file", type=str, default="")
    parser.add_argument("-wingbox_title", type=str, default="Wingbox FEA mesh with wing surface")
    parser.add_argument("-wingbox_jig_shape", type=int, default=0)
    parser.add_argument("-wingbox_show_wing_surface", type=int, default=1)
    parser.add_argument("-wingbox_show_edges", type=int, default=0)
    parser.add_argument("-fea_field_label", type=str, default="")
    parser.add_argument("-fea_output_suffix", type=str, default="")
    parser.add_argument("-opacity", type=float, default=0.5)
    return parser.parse_args()


def _run_shell(command, case_dir):
    completed = subprocess.run(["bash", "-lc", command], cwd=case_dir, text=True, capture_output=True)
    if completed.returncode != 0:
        raise RuntimeError(completed.stderr.strip() or completed.stdout.strip() or command)


def main():
    args = parse_args()
    # Exit successfully before VTK can create an EGL/X11 render window.
    if args.mode in VTK_RENDER_MODES and _skip_vtk_plots():
        print(f"Skipping VTK plot mode '{args.mode}': AGENT_DECK_SKIP_VTK_PLOT=1")
        return
    mesh_files = args.mesh_file

    if args.mode == "wing_plot_mesh":
        return wing_plot_mesh(
            case_dir=args.case_dir,
            mesh_file=mesh_files[0],
            geometry_file=args.geometry_file,
            camera_scale=args.camera_scale,
            image_width=args.image_width,
            image_height=args.image_height,
        )
    if args.mode == "general_plot_residual":
        return general_plot_residual(
            case_dir=args.case_dir,
            log_file=args.log_file,
            start_time_cfd=args.start_time_cfd,
            end_time_cfd=args.end_time_cfd,
            start_time_adjoint=args.start_time_adjoint,
            end_time_adjoint=args.end_time_adjoint,
        )
    if args.mode == "general_plot_function":
        return general_plot_function(
            case_dir=args.case_dir,
            log_file=args.log_file,
            start_time=args.start_time,
            end_time=args.end_time,
            tail_fraction=args.tail_fraction,
        )
    if args.mode == "general_plot_optimization_history":
        return general_plot_optimization_history(
            case_dir=args.case_dir,
            hist_file=args.hist_file,
            optimizer_log=args.optimizer_log,
        )
    if args.mode == "wing_plot_flow_field":
        return wing_plot_flow_field(
            case_dir=args.case_dir,
            flow_field=args.flow_field,
            time_step=args.time_step,
            camera_scale=args.camera_scale,
            colormap=args.colormap,
            image_width=args.image_width,
            image_height=args.image_height,
            surface_file=mesh_files,
            geometry_file=args.geometry_file,
            var_ref=args.var_ref,
            var_scaling=args.var_scaling,
            field_label=args.field_label,
            var_lower=args.var_lower,
            var_upper=args.var_upper,
        )
    if args.mode == "wing_plot_pressure_profile":
        return wing_plot_pressure_profile(
            case_dir=args.case_dir,
            time_step=args.time_step,
            wing_span=args.wing_span,
            mesh_file=mesh_files,
            reference_pressure=args.reference_pressure,
            pressure_coefficient_scale=args.pressure_coefficient_scale,
            spanwise_chords=args.spanwise_chords,
            spanwise_x=args.spanwise_x,
            spanwise_fractions=args.spanwise_fractions,
            var_lower=args.var_lower,
            var_upper=args.var_upper,
        )
    if args.mode == "wing_plot_wingbox_mesh":
        return wing_plot_wingbox_mesh(
            case_dir=args.case_dir,
            vtk_file=args.wingbox_vtk_file,
            wing_surface_file=args.wingbox_surface_file,
            output_file=args.wingbox_output_file,
            title=args.wingbox_title,
            jig_shape=bool(args.wingbox_jig_shape),
            show_wing_surface=bool(args.wingbox_show_wing_surface),
            show_edges=bool(args.wingbox_show_edges),
            camera_scale=args.camera_scale,
            image_width=args.image_width,
            image_height=args.image_height,
        )
    if args.mode == "plot_fea_fields":
        return plot_fea_fields(
            case_dir=args.case_dir,
            vtk_file=mesh_files[0],
            field_name=args.fea_field,
            field_label=args.fea_field_label,
            camera_scale=args.camera_scale,
            opacity=args.opacity,
            image_width=args.image_width,
            image_height=args.image_height,
            var_lower=args.var_lower,
            var_upper=args.var_upper,
            geometry_file=args.geometry_file,
            output_suffix=args.fea_output_suffix,
        )
    if args.mode == "wing_plot_spanwise_variable":
        return wing_plot_spanwise_variable(
            case_dir=args.case_dir,
            vtp_file=args.vtp_file,
            n_slices=args.n_slices,
            angle_of_attack_deg=args.angle_of_attack,
        )
    if args.mode == "trame_view":
        return general_trame_view(
            input_files=args.input_files,
            port=args.port,
        )
    if args.mode == "html_view":
        return general_html_view(
            root_dir=args.case_dir,
            port=args.port,
        )
    if args.mode == "html_gallery":
        return general_create_image_html(
            case_dir=args.case_dir,
            image_files=args.image_files,
            html_filename=args.html_filename,
        )

    raise ValueError(
        "Unsupported mode. Expected one of: "
        "wing_plot_mesh, wing_plot_wingbox_mesh, plot_fea_fields, general_plot_residual, general_plot_function, "
        "general_plot_optimization_history, "
        "wing_plot_flow_field, wing_plot_pressure_profile, wing_plot_spanwise_variable, "
        "trame_view, html_view, html_gallery."
    )


if __name__ == "__main__":
    main()
