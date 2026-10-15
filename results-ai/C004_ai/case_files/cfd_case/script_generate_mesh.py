#!/usr/bin/env python

import argparse

from mdo_agent_deck import extrude_volume_mesh, generate_wing_surface_mesh


parser = argparse.ArgumentParser(description="Generate a wing surface and volume mesh.")
parser.add_argument("-airfoil_profiles", type=str, nargs="+", default=["naca0012", "naca0012"])
parser.add_argument("-chords", type=float, nargs="+", default=[1.0, 1.0])
parser.add_argument(
    "-spans",
    help="N-1 sectional HALF-WING SPAN lengths in meters, one per span segment ordered wing root to tip.",
    type=float,
    nargs="+",
    default=[3.0],
)
parser.add_argument("-sweeps", type=float, nargs="+", default=[0.0])
parser.add_argument("-dihedrals", type=float, nargs="+", default=[0.0])
parser.add_argument("-twists", type=float, nargs="+", default=[0.0])
parser.add_argument("-surf_mesh_cells", type=int, default=4000)
parser.add_argument("-blunt_te", type=float, default=0.01)
parser.add_argument("-trailing_edge_shape", type=str, default="rounded")
parser.add_argument("-tip_cluster", type=float, default=0.1)
parser.add_argument("-le_cluster", type=float, default=0.1)
parser.add_argument("-te_cluster", type=float, default=0.1)
parser.add_argument("-farfield_scale", type=float, default=20.0)
parser.add_argument("-n_layers", type=int, default=50)
parser.add_argument("-d0", type=float, default=None)
parser.add_argument("-y_plus", type=float, default=50.0)
parser.add_argument("-mach_number", type=float, default=0.2)
parser.add_argument("-reynolds_number", type=float, default=5e6)
parser.add_argument("-diffusion_sweeps", type=int, default=10)
parser.add_argument("-neighbor_rings", type=int, default=10)
parser.add_argument("-diffuse_start", type=float, default=None)
parser.add_argument("-sym_axis", type=str, default="y")
parser.add_argument("-sym_decay", type=float, default=None)
args = parser.parse_args()

d0 = args.d0 if args.d0 is not None and args.d0 >= 0.0 else None
sym_decay = args.sym_decay if args.sym_decay is not None and args.sym_decay >= 0.0 else None
ref_chord = sum(float(chord) for chord in args.chords) / len(args.chords)
# Route the surface stage through the shared mdo_agent_mesh wing.vsp3 template workflow.
generate_wing_surface_mesh(
    airfoil_profiles=args.airfoil_profiles,
    chords=args.chords,
    spans=args.spans,
    sweeps=args.sweeps,
    dihedrals=args.dihedrals,
    twists=args.twists,
    surf_mesh_cells=args.surf_mesh_cells,
    blunt_te=args.blunt_te,
    trailing_edge_shape=args.trailing_edge_shape,
    tip_cluster=args.tip_cluster,
    le_cluster=args.le_cluster,
    te_cluster=args.te_cluster,
    output_dir=".",
)

extrude_volume_mesh(
    input="wing.xyz",
    out_dir="constant/polyMesh",
    L=float(args.farfield_scale) * float(args.chords[0]),
    d0=d0,
    y_plus=args.y_plus,
    mach_number=args.mach_number,
    reynolds_number=args.reynolds_number,
    ref_chord=ref_chord,
    N=args.n_layers,
    diffusion_sweeps=args.diffusion_sweeps,
    neighbor_rings=args.neighbor_rings,
    diffuse_start=args.diffuse_start,
    sym_axis=args.sym_axis,
    sym_decay=sym_decay,
    quiet=False,
)
