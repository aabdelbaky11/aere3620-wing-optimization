import argparse
import os

from mdo_agent_deck import generate_wing_fea_mesh

parser = argparse.ArgumentParser()
parser.add_argument("-wing_igs", help="name of the wing surface file", type=str, default="wing_pygeo.iges")
parser.add_argument("-n_ribs", help="number of ribs in the spanwise direction", type=int, default=10)
parser.add_argument("-n_spars", help="number of spars in the chordwise direction", type=int, default=2)
parser.add_argument("-total_elements_target", help="requested total number of shell elements", type=int, default=3000)
parser.add_argument("-wingbox_span", help="fraction of the modeled HALF-WING SPAN covered by the wingbox", type=float, default=0.95)
parser.add_argument("-wingbox_chord_start", help="wingbox front spar position as fraction of local chord", type=float, default=0.20)
parser.add_argument("-wingbox_chord_end", help="wingbox rear spar position as fraction of local chord", type=float, default=0.80)
args = parser.parse_args()

case_dir = os.path.dirname(os.path.abspath(__file__))
wing_stl = os.path.join(case_dir, "wing.stl")

generate_wing_fea_mesh(
    wing_stl=wing_stl,
    n_ribs=args.n_ribs,
    n_spars=args.n_spars,
    total_elements_target=args.total_elements_target,
    wingbox_span=args.wingbox_span,
    wingbox_chord_start=args.wingbox_chord_start,
    wingbox_chord_end=args.wingbox_chord_end,
    output_bdf=os.path.join(case_dir, "wingbox.bdf"),
    output_dat=os.path.join(case_dir, "wingbox.dat"),
    shell_thickness=0.01,
)
