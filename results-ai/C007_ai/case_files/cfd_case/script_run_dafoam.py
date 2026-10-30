#!/usr/bin/env python

# =============================================================================
# Imports
# =============================================================================
import os
import argparse
import json
import numpy as np
from mpi4py import MPI
import openmdao.api as om
from mphys.core import MPhysVariables, Multipoint
from dafoam.mphys import DAFoamBuilder, OptFuncs, DAFoamLinearConstraint, DAFoamVSPVolume
from mdo_agent_deck.base import MultiPointObjective
from mphys.scenarios import ScenarioAerodynamic
from pygeo.mphys import OM_DVGEOCOMP

parser = argparse.ArgumentParser()
parser.add_argument("-optimizer", help="optimizer to use", type=str, default="Uno")
parser.add_argument("-task", help="type of run to do", type=str, default="run_model")
parser.add_argument("-angle_of_attack", help="angle of attack", type=float, default=3.0)
parser.add_argument(
    "-fixed_lift_coeff",
    help="Automatically vary the angle of attack to compute drag at the prescribed lift coefficient. Set it to -1.0 to disable.",
    type=float,
    default=-1.0,
)
parser.add_argument("-mach_number", help="mach number", type=float, default=0.2)
parser.add_argument("-solver_name", help="Resolved solver name passed by the calling skill.", type=str, required=True)
parser.add_argument(
    "-turbulence_model",
    help="OpenFOAM RANS turbulence model. Supported values are `SpalartAllmaras` (SA) and `kOmegaSST` (SST).",
    type=str,
    default="SpalartAllmaras",
)
parser.add_argument("-max_adj_iters", help="The max GMRES iterations for the adjoint solve", type=int, default=1000)
parser.add_argument("-pc_fill_level", help="The ILU fill level for the adjoint preconditioner", type=int, default=1)
parser.add_argument("-max_flow_iters", help="The max flow iterations", type=int, default=10000)
parser.add_argument("-reynolds_number", help="Reynolds number", type=float, default=5e6)
parser.add_argument(
    "-lift_constraint", help="The lift constraint", type=float, nargs="+", default=[0.5]
)
parser.add_argument(
    "-multipoint_weight",
    help="The weights for multipoint optimization",
    type=float,
    nargs="+",
    default=[1.0],
)
parser.add_argument("-max_opt_iters", help="Maximum optimization iterations", type=int, default=50)
parser.add_argument(
    "-n_ego_doe_pts",
    help="Number of initial DOE points used by the EGO optimizer",
    type=int,
    default=20,
)
parser.add_argument(
    "-n_multi_start",
    help="Number of multi-start points for the EGO internal EI optimization",
    type=int,
    default=20,
)
parser.add_argument(
    "-ei_tol",
    help="EGO internal expected improvmeent (EI) optimization tolerance.",
    type=float,
    default=1.0e-4,
)
parser.add_argument(
    "-ego_seed",
    help="Random seed used by the EGO optimizer DOE and infill sampling.",
    type=int,
    default=0,
)
parser.add_argument(
    "-ego_tol",
    help="Objective variation tolerance for the EGO optimization.",
    type=float,
    default=1.0e-3,
)
parser.add_argument(
    "-ego_cstr_tol",
    help="Constraint tolerance used by EGO and its lift-trim searches.",
    type=float,
    default=1.0e-3,
)
parser.add_argument(
    "-primal_func_std_tol",
    help="Primal function standard deviation tolerance",
    type=float,
    default=1e-4,
)
parser.add_argument(
    "-primal_func_slope_tol",
    help="Primal function slope tolerance",
    type=float,
    default=1e-6,
)
parser.add_argument(
    "-reference_area",
    help="Reference area for normalizing the drag and lift",
    type=float,
    default=None,
)
parser.add_argument(
    "-reference_length",
    help="Reference length for normalizing the moment",
    type=float,
    default=None,
)
parser.add_argument(
    "-moment_center",
    help="Moment reference center `[x y z]` used for aerodynamic moments.",
    type=float,
    nargs=3,
    default=[0.0, 0.0, 0.0],
)
parser.add_argument(
    "-profile_fit_coeff_count",
    help="The number of CST coefficients. 6 means we have 6 coefficients for the upper surface and 6 coefficients for the lower surface",
    type=int,
    default=6,
)
parser.add_argument(
    "-cst_coeffs",
    help="The CST coefficients for sectional airfoil along the span, starting from the root section",
    type=float,
    nargs="+",
    default=None,
)
parser.add_argument(
    "-twists",
    help="Spanwise twist angles in degrees, starting from the root + 1 section, the size of twists is nSpanwiseSeciton - 1",
    type=float,
    nargs="+",
    default=None,
)
parser.add_argument(
    "-spans",
    help="N-1 sectional HALF-WING SPAN lengths in meters, one per span segment ordered wing root to tip.",
    type=float,
    nargs="+",
    default=None,
)
parser.add_argument(
    "-sweeps",
    help="Spanwise sweeps, starting from the root + 1 section, the size of sweeps is nSpanwiseSeciton - 1",
    type=float,
    nargs="+",
    default=None,
)
parser.add_argument(
    "-dihedrals",
    help="Spanwise dihedrals in degrees, starting from the root + 1 section, the size of dihedrals is nSpanwiseSeciton - 1",
    type=float,
    nargs="+",
    default=None,
)
parser.add_argument(
    "-chords",
    help="Spanwise chords, starting from the root section, the size of chords is nSpanwiseSeciton",
    type=float,
    nargs="+",
    default=None,
)
parser.add_argument(
    "-le_radius_constraint", help="LE radius constraint lower bound (-1 to disable)", type=float, default=1.0
)
parser.add_argument(
    "-thickness_constraint", help="Thickness constraint lower bound (-1 to disable)", type=float, default=0.5
)
parser.add_argument("-volume_constraint", help="Volume constraint lower bound (-1 to disable)", type=float, default=1.0)
parser.add_argument(
    "-active_design_vars",
    help="Design variable groups the optimizer may change: cst_coeffs, twists, spans, sweeps, dihedrals, chords.",
    type=str,
    nargs="+",
    default=["cst_coeffs", "twists"],
)
parser.add_argument(
    "-initialize_from",
    help="Warm-start source case name. When set, the field staged into 0/ is kept instead of resetting to the uniform freestream.",
    type=str,
    default=None,
)
args = parser.parse_args()

# read the EGO dv bounds
with open("advanced_parameters.json", "r", encoding="utf-8") as handle:
    ego_dv_bounds = json.load(handle)["run-aero-optimization"]["ego_dv_bounds"]["value"]

# =============================================================================
# Input Parameters
# =============================================================================

# Clean up previous run results
if MPI.COMM_WORLD.rank == 0:
    os.system("rm -rf postProcessing")
    os.system("rm -rf processor* 0.00* ")
    os.system("rm -rf *.bin *.info *.jpeg *.png reports *.hst")
    os.system("rm -rf {1..9}*")
    # Update the copied controlDict before the primal run so the iteration cap is reproducible.
    os.system(f"sed -i 's/^endTime.*/endTime         {int(args.max_flow_iters)};/' system/controlDict")
    os.system(f"sed -i 's/^writeInterval.*/writeInterval   {int(args.max_flow_iters)};/' system/controlDict")

n_sections = len(args.chords)

T0 = 300.0

A0 = args.reference_area
L0 = args.reference_length
moment_center = [float(value) for value in args.moment_center]
R = 287.0
k = 1.4
C = float(np.sqrt(k * R * T0))
U0 = args.mach_number * C
aoa0 = args.angle_of_attack
Ux = float(U0 * np.cos(np.radians(aoa0)))
Uz = float(U0 * np.sin(np.radians(aoa0)))

nu = U0 * L0 / args.reynolds_number
TURBULENCE_INTENSITY = 0.01
EDDY_VISCOSITY_RATIO = 10.0
nuTilda0 = EDDY_VISCOSITY_RATIO * nu
k0 = 1.5 * (U0 * TURBULENCE_INTENSITY) ** 2
omega0 = k0 / (EDDY_VISCOSITY_RATIO * nu)

if args.turbulence_model not in ("SpalartAllmaras", "kOmegaSST"):
    raise ValueError(
        "Unsupported turbulence_model. Supported values are `SpalartAllmaras` (SA) and `kOmegaSST` (SST)."
    )

solverName = args.solver_name

if solverName == "DASimpleFoam":
    transonicPC = 0
    p0 = 0.0
    rho0 = 1.0
    p_norm = U0 * U0 / 2.0
elif solverName == "DARhoSimpleFoam":
    transonicPC = 0
    p0 = 101325.0
    rho0 = p0 / R / T0
    p_norm = p0
elif solverName == "DARhoSimpleCFoam":
    transonicPC = 1
    p0 = 101325.0
    rho0 = p0 / R / T0
    p_norm = p0
elif solverName == "DAHisaFoam":
    p0 = 101325.0
    rho0 = p0 / R / T0
    p_norm = p0
    transonicPC = 1  # this is actually not used in hisa
else:
    raise ValueError(f"Unsupported solverName `{solverName}`")

mu = nu * rho0

nMultipoints = len(args.lift_constraint)
time_op = "average" if args.task == "run_model" else "final"

IC = {"U": [Ux, 0.0, Uz], "p": p0, "T": T0, "nuTilda": nuTilda0, "k": k0, "omega": omega0}

if solverName == "DAHisaFoam":
    BC = {
        "charFarFieldBC": [Ux, 0.0, Uz, p0, T0],
        "thermo:mu": mu,
        "nuTilda0": {"variable": "nuTilda", "patches": ["inout"], "value": [nuTilda0]},
        "k0": {"variable": "k", "patches": ["inout"], "value": [k0]},
        "omega0": {"variable": "omega", "patches": ["inout"], "value": [omega0]},
        "useWallFunction": True,
    }
elif solverName == "DASimpleFoam":
    BC = {
        "U0": {"variable": "U", "patches": ["inout"], "value": [Ux, 0.0, Uz]},
        "p0": {"variable": "p", "patches": ["inout"], "value": [p0]},
        "nuTilda0": {"variable": "nuTilda", "patches": ["inout"], "value": [nuTilda0]},
        "k0": {"variable": "k", "patches": ["inout"], "value": [k0]},
        "omega0": {"variable": "omega", "patches": ["inout"], "value": [omega0]},
        "transport:nu": nu,
        "useWallFunction": True,
    }
else:
    BC = {
        "U0": {"variable": "U", "patches": ["inout"], "value": [Ux, 0.0, Uz]},
        "p0": {"variable": "p", "patches": ["inout"], "value": [p0]},
        "T0": {"variable": "T", "patches": ["inout"], "value": [T0]},
        "nuTilda0": {"variable": "nuTilda", "patches": ["inout"], "value": [nuTilda0]},
        "k0": {"variable": "k", "patches": ["inout"], "value": [k0]},
        "omega0": {"variable": "omega", "patches": ["inout"], "value": [omega0]},
        "thermo:mu": mu,
        "useWallFunction": True,
    }


warm_start = args.initialize_from is not None

# Input parameters for DAFoam
daOptions = {
    "designSurfaces": ["wing"],
    "solverName": solverName,
    "transonicPCOption": transonicPC,
    "primalMinResTol": 1.0e-7,
    "primalMinResTolDiff": 1e3,
    "primalFuncStdTol": {
        "stdTol": args.primal_func_std_tol,
        "slopeTol": args.primal_func_slope_tol,
        "funcNames": ["CD", "CL"],
        "nStepsFrac": 0.2,
    },
    "writeSurfForces": {"active": True, "patchNames": ["wing"]},
    "primalMinIters": 100,
    "printInterval": 10,
    # Warm starts keep the staged 0/ field; cold starts reset to the uniform freestream IC.
    "primalInitCondition": {} if warm_start else IC,
    "primalBC": BC,
    "function": {
        "CD": {
            "type": "force",
            "source": "patchToFace",
            "patches": ["wing"],
            "directionMode": "parallelToFlow",
            "patchVelocityInputName": "patchV",
            "scale": 1.0 / (0.5 * U0 * U0 * A0 * rho0),
            "timeOp": time_op,
            "nStepsFrac": 0.2,
        },
        "CL": {
            "type": "force",
            "source": "patchToFace",
            "patches": ["wing"],
            "directionMode": "normalToFlow",
            "patchVelocityInputName": "patchV",
            "scale": 1.0 / (0.5 * U0 * U0 * A0 * rho0),
            "timeOp": time_op,
            "nStepsFrac": 0.2,
        },
        "CM": {
            "type": "moment",
            "source": "patchToFace",
            "patches": ["wing"],
            "axis": [0.0, 1.0, 0.0],
            # Use the OpenVSP CG-based reference point passed from the wing skill.
            "center": moment_center,
            "scale": 1.0 / (0.5 * U0 * U0 * A0 * rho0 * L0),
            "timeOp": time_op,
            "nStepsFrac": 0.2,
        },
    },
    "adjStateOrdering": "cell",
    "adjEqnOption": {
        "gmresRelTol": 1.0e-4,
        "pcFillLevel": args.pc_fill_level,
        "jacMatReOrdering": "natural",
        "gmresMaxIters": args.max_adj_iters,
        "gmresRestart": args.max_adj_iters,
    },
    "normalizeStates": {
        "U": U0,
        "p": p_norm,
        "T": T0,
        "nuTilda": nuTilda0 * 10.0,
        "k": k0 * 10.0,
        "omega": omega0 * 0.1,
        "phi": 1.0,
    },
    "inputInfo": {
        "aero_vol_coords": {"type": "volCoord", "components": ["solver", "function"]},
        "patchV": {
            "type": "patchVelocity",
            "patches": ["inout"],
            "flowAxis": "x",
            "normalAxis": "z",
            "components": ["solver", "function"],
        },
    },
    "checkMeshThreshold": {
        "maxNonOrth": 80.0,
        "maxSkewness": 6.0,
        "maxAspectRatio": 10000.0,
    },
}
# Mesh deformation setup
meshOptions = {
    "gridFile": os.getcwd(),
    "fileType": "OpenFOAM",
    # point and normal for the symmetry plane
    "symmetryPlanes": [
        [[0.0, 0.0, 0.0], [0.0, 1.0, 0.0]],
    ],
}


# Top class to setup the optimization problem
class Top(Multipoint):
    def setup(self):

        # create the builder to initialize the DASolvers
        dafoam_builder = DAFoamBuilder(daOptions, meshOptions, scenario="aerodynamic")
        dafoam_builder.initialize(self.comm)

        # add the design variable component to keep the top level design variables
        self.add_subsystem("dvs", om.IndepVarComp(), promotes=["*"])

        # add the mesh component
        self.add_subsystem("mesh", dafoam_builder.get_mesh_coordinate_subsystem())

        # add the geometry component (FFD)
        # Set the VSP projection tolerance to 2% of the reference length rather than a fixed value.
        projTol = 0.02 * L0
        self.add_subsystem("geometry", OM_DVGEOCOMP(file="wing.vsp3", type="vsp", options={"projTol": projTol}), promotes=["*"])

        # add a scenario (flow condition) for optimization, we pass the builder
        # to the scenario to actually run the flow and adjoint
        for i in range(nMultipoints):
            self.mphys_add_scenario(
                f"scenario{i}", ScenarioAerodynamic(aero_builder=dafoam_builder)
            )

        # need to manually connect the x_aero0 between the mesh and geometry components
        # here x_aero0 means the surface coordinates of structurally undeformed mesh
        self.connect("mesh.x_aero0", "x_aero0_geometry_input")
        # Connect the shared geometry coordinates to every flight-condition scenario.
        for i in range(nMultipoints):
            self.connect("x_aero0_geometry_output", f"scenario{i}.x_aero")

        # thickness constraint
        varA = []
        varB = []
        for i in range(n_sections):
            for j in range(args.profile_fit_coeff_count):
                varA.append(f"Wing:UpperCoeff_{i}:Au_{j}")
                varB.append(f"Wing:LowerCoeff_{i}:Al_{j}")
        self.add_subsystem(
            "thickness",
            DAFoamLinearConstraint(varA=varA, coeffA=1.0, varB=varB, coeffB=-1.0, size=1, output_name="thickness_val"),
            promotes=["*"],
        )

        # LE C1 continuity constraint
        varA = []
        varB = []
        for i in range(n_sections):
            varA.append(f"Wing:UpperCoeff_{i}:Au_0")
            varB.append(f"Wing:LowerCoeff_{i}:Al_0")
        self.add_subsystem(
            "le_c1",
            DAFoamLinearConstraint(varA=varA, coeffA=1.0, varB=varB, coeffB=1.0, size=1, output_name="le_c1_val"),
            promotes=["*"],
        )

        # add volume constraint
        vsp_vars = []
        for i in range(n_sections):
            for j in range(args.profile_fit_coeff_count):
                vsp_vars.append(f"Wing:UpperCoeff_{i}:Au_{j}")
                vsp_vars.append(f"Wing:LowerCoeff_{i}:Al_{j}")
        for i in range(1, n_sections):
            vsp_vars.append(f"Wing:XSec_{i}:Twist")
            vsp_vars.append(f"Wing:XSec_{i}:Span")
            vsp_vars.append(f"Wing:XSec_{i}:Sweep")
            vsp_vars.append(f"Wing:XSec_{i}:Dihedral")
            vsp_vars.append(f"Wing:XSec_{i}:Tip_Chord")
        vsp_vars.append("Wing:XSec_1:Root_Chord")
        self.add_subsystem(
            "volume",
            DAFoamVSPVolume(
                vsp_file="wing.vsp3",
                vsp_vars=vsp_vars,
                slice_dir="y",
                n_slices=10,
                output_name="volume_val",
                step=1e-5,
                relativeStep=False,
            ),
            promotes=["*"],
        )

        # Combine scalar drag coefficients from every scenario into one weighted objective.
        self.add_subsystem(
            "multipoint",
            MultiPointObjective(
                n_points=nMultipoints,
                weights=args.multipoint_weight,
            ),
        )

    def configure(self):

        active_dvs = set(args.active_design_vars)

        # get the surface coordinates from the mesh component
        points = self.mesh.mphys_get_surface_mesh()

        # add pointset to the geometry component
        self.geometry.nom_add_discipline_coords(MPhysVariables.Aerodynamics.Surface.Geometry, points)

        # add sectional airfoil shape var
        CST = args.cst_coeffs
        for i in range(n_sections):
            for j in range(args.profile_fit_coeff_count):
                self.geometry.nom_addVSPVariable("Wing", f"UpperCoeff_{i}", f"Au_{j}", scaledStep=False, dh=1e-5)
                self.geometry.nom_addVSPVariable("Wing", f"LowerCoeff_{i}", f"Al_{j}", scaledStep=False, dh=1e-5)
                self.dvs.add_output(f"Wing:UpperCoeff_{i}:Au_{j}", val=CST[2 * i * args.profile_fit_coeff_count + j])
                self.dvs.add_output(f"Wing:LowerCoeff_{i}:Al_{j}", val=CST[(2 * i + 1) * args.profile_fit_coeff_count + j])
                if "cst_coeffs" in active_dvs:
                    self.add_design_var(f"Wing:UpperCoeff_{i}:Au_{j}", lower=ego_dv_bounds["CSTCoeffs"][0], upper=ego_dv_bounds["CSTCoeffs"][1], scaler=2.0)
                    self.add_design_var(f"Wing:LowerCoeff_{i}:Al_{j}", lower=ego_dv_bounds["CSTCoeffs"][0], upper=ego_dv_bounds["CSTCoeffs"][1], scaler=2.0)

        # add sectional twist var
        for i in range(1, n_sections):
            self.geometry.nom_addVSPVariable("Wing", f"XSec_{i}", "Twist", scaledStep=False, dh=1e-5)
            self.dvs.add_output(f"Wing:XSec_{i}:Twist", val=args.twists[i - 1])
            if "twists" in active_dvs:
                self.add_design_var(f"Wing:XSec_{i}:Twist", lower=ego_dv_bounds["Twist"][0], upper=ego_dv_bounds["Twist"][1], scaler=0.1)

        # add sectional span var
        for i in range(1, n_sections):
            self.geometry.nom_addVSPVariable("Wing", f"XSec_{i}", "Span", scaledStep=False, dh=1e-5)
            self.dvs.add_output(f"Wing:XSec_{i}:Span", val=args.spans[i - 1])
            if "spans" in active_dvs:
                self.add_design_var(f"Wing:XSec_{i}:Span", lower=ego_dv_bounds["Span"][0], upper=ego_dv_bounds["Span"][1], scaler=0.1)

        # add sectional sweep var
        for i in range(1, n_sections):
            self.geometry.nom_addVSPVariable("Wing", f"XSec_{i}", "Sweep", scaledStep=False, dh=1e-5)
            self.dvs.add_output(f"Wing:XSec_{i}:Sweep", val=args.sweeps[i - 1])
            if "sweeps" in active_dvs:
                self.add_design_var(f"Wing:XSec_{i}:Sweep", lower=ego_dv_bounds["Sweep"][0], upper=ego_dv_bounds["Sweep"][1], scaler=0.1)

        # add sectional dihedral var
        for i in range(1, n_sections):
            self.geometry.nom_addVSPVariable("Wing", f"XSec_{i}", "Dihedral", scaledStep=False, dh=1e-5)
            self.dvs.add_output(f"Wing:XSec_{i}:Dihedral", val=args.dihedrals[i - 1])
            if "dihedrals" in active_dvs:
                self.add_design_var(f"Wing:XSec_{i}:Dihedral", lower=ego_dv_bounds["Dihedral"][0], upper=ego_dv_bounds["Dihedral"][1], scaler=0.1)

        # add sectional chord var
        self.geometry.nom_addVSPVariable("Wing", "XSec_1", "Root_Chord", scaledStep=False, dh=1e-5)
        self.dvs.add_output("Wing:XSec_1:Root_Chord", val=args.chords[0])
        if "chords" in active_dvs:
            self.add_design_var("Wing:XSec_1:Root_Chord", lower=ego_dv_bounds["Chord"][0], upper=ego_dv_bounds["Chord"][1], scaler=0.2)
        for i in range(1, n_sections):
            self.geometry.nom_addVSPVariable("Wing", f"XSec_{i}", "Tip_Chord", scaledStep=False, dh=1e-5)
            self.dvs.add_output(f"Wing:XSec_{i}:Tip_Chord", val=args.chords[i])
            if "chords" in active_dvs:
                self.add_design_var(f"Wing:XSec_{i}:Tip_Chord", lower=ego_dv_bounds["Chord"][0], upper=ego_dv_bounds["Chord"][1], scaler=0.2)

        for i in range(nMultipoints):
            self.dvs.add_output(f"patchV{i}", val=np.array([U0, aoa0]))
            self.connect(f"patchV{i}", f"scenario{i}.patchV")
            self.add_design_var(
                f"patchV{i}", lower=[U0, ego_dv_bounds["AoA"][0]], upper=[U0, ego_dv_bounds["AoA"][1]], scaler=0.1
            )

        # Add the weighted drag objective and one lift constraint for every point.
        self.add_objective("multipoint.obj", scaler=50.0)
        for i in range(nMultipoints):
            self.connect(f"scenario{i}.aero_post.CD", f"multipoint.obj_point_{i}")
            self.add_constraint(
                f"scenario{i}.aero_post.CL", lower=args.lift_constraint[i], scaler=2.0
            )

        # volume constraint
        if args.volume_constraint > 0:
            self.add_constraint("volume_val", lower=args.volume_constraint, scaler=1.0)

        # CST-only constraints have zero derivatives when shape variables are frozen.
        # Thickness constraint
        if "cst_coeffs" in active_dvs and args.thickness_constraint >= 0:
            for i in range(n_sections):
                for j in range(1, args.profile_fit_coeff_count):
                    indexI = i * args.profile_fit_coeff_count + j
                    cst_upper = CST[2 * i * args.profile_fit_coeff_count + j]
                    cst_lower = CST[(2 * i + 1) * args.profile_fit_coeff_count + j]
                    self.add_constraint(
                        f"thickness_val_{indexI}",
                        lower=args.thickness_constraint * (cst_upper - cst_lower),
                        scaler=1.0,
                        linear=True,
                    )

        # LE radius constraint
        if "cst_coeffs" in active_dvs and args.le_radius_constraint > 0:
            for i in range(n_sections):
                indexI = i * args.profile_fit_coeff_count
                cst_upper = CST[2 * i * args.profile_fit_coeff_count]
                cst_lower = CST[(2 * i + 1) * args.profile_fit_coeff_count]
                self.add_constraint(
                    f"thickness_val_{indexI}",
                    lower=args.le_radius_constraint * (cst_upper - cst_lower),
                    scaler=1.0,
                    linear=True,
                )

        # LE C1 continuity is meaningful only while CST is active.
        if "cst_coeffs" in active_dvs:
            for i in range(n_sections):
                self.add_constraint(f"le_c1_val_{i}", equals=0.0, scaler=1.0, linear=True)


# OpenMDAO setup
prob = om.Problem()
prob.model = Top()
prob.setup(mode="rev")

# initialize the optimization function
optFuncs = OptFuncs(daOptions, prob)

# use pyoptsparse to setup optimization
prob.driver = om.pyOptSparseDriver()
prob.driver.options["optimizer"] = args.optimizer
# options for optimizers
if args.optimizer == "SNOPT":
    prob.driver.opt_settings = {
        "Major feasibility tolerance": 1.0e-4,
        "Major optimality tolerance": 1.0e-4,
        "Minor feasibility tolerance": 1.0e-4,
        "Verify level": -1,
        "Function precision": 1.0e-5,
        "Major iterations limit": args.max_opt_iters,
        "Nonderivative linesearch": None,
        "Print file": "opt_SNOPT_print.txt",
        "Summary file": "opt_SNOPT_summary.txt",
    }
elif args.optimizer == "Uno":
    prob.driver.opt_settings = {
        "preset": "filtersqp",
        "globalization_mechanism": "LS",
        "LS_backtracking_ratio": 0.25,
        "LS_min_step_length": 0.001,
        "globalization_strategy": "merit_function",
        "hessian_model": "LBFGS",
        "max_iterations": args.max_opt_iters,
        "primal_tolerance": 1e-4,
        "loose_primal_tolerance": 1e-3,
        "dual_tolerance": 1e-4,
        "loose_dual_tolerance": 1e-3,
        "quasi_newton_memory_size": 50,
        "logger": "INFO",
        "logger_stream": "opt_Uno.txt",
    }
elif args.optimizer == "SLSQP":
    prob.driver.opt_settings = {
        "ACC": 1.0e-6,
        "MAXIT": args.max_opt_iters,
        "IFILE": "opt_SLSQP.txt",
    }
else:
    print("optimizer arg not valid!")
    exit(1)

prob.driver.options["debug_print"] = ["nl_cons", "objs", "desvars"]
prob.driver.options["print_opt_prob"] = True
prob.driver.hist_file = "OptView.hst"

if __name__ == "__main__":
    # Keep case construction importable by the dedicated EGO wrapper.
    if args.task == "run_driver":
        # solve CL
        lift_names = [f"scenario{i}.aero_post.CL" for i in range(nMultipoints)]
        patch_v_names = [f"patchV{i}" for i in range(nMultipoints)]
        optFuncs.findFeasibleDesign(
            lift_names,
            patch_v_names,
            targets=args.lift_constraint,
            designVarsComp=[1] * nMultipoints,
            epsFD=[1e-2] * nMultipoints,
            tol=1e-3,
        )
        # run the optimization
        prob.run_driver()
        if MPI.COMM_WORLD.rank == 0:
            # Write the final OpenVSP design before marking the optimization complete.
            prob.model.geometry.nom_getDVGeo().writeVSPFile("wing_opt.vsp3")
    elif args.task == "run_model":
        # Adjust only the angle-of-attack component of patchV when fixed-lift evaluation is enabled.
        if args.fixed_lift_coeff > 0.0:
            optFuncs.findFeasibleDesign(
                ["scenario0.aero_post.CL"],
                ["patchV0"],
                targets=[args.fixed_lift_coeff],
                designVarsComp=[1],
                epsFD=[1e-2],
                tol=1e-3,
            )
        # Run the final primal at either the requested angle of attack or the feasible fixed-lift condition.
        prob.run_model()
    elif args.task == "compute_totals":
        # just run the primal and adjoint once
        prob.run_model()
        totals = prob.compute_totals()
        if MPI.COMM_WORLD.rank == 0:
            print(totals)
    elif args.task == "check_totals":
        # verify the total derivatives against the finite-difference
        prob.run_model()
        prob.check_totals(compact_print=False, step=1e-3, form="central", step_calc="abs")
    else:
        print("task arg not found!")
        exit(1)
