#!/usr/bin/env python

# =============================================================================
# Imports
# =============================================================================
import os
import argparse
import numpy as np
from mpi4py import MPI
import openmdao.api as om
from mphys.core import MPhysVariables, Multipoint
from dafoam.mphys import (
    DAFoamBuilder,
    OptFuncs,
    DAFoamLinearConstraint,
    DAFoamVSPVolume,
)
from mdo_agent_deck.base import MultiPointObjective
from tacs.mphys import TacsBuilder
from funtofem.mphys import MeldBuilder
from mphys.scenarios import ScenarioAeroStructural
from pygeo.mphys import OM_DVGEOCOMP
from tacs import TACS, elements, constitutive, functions

parser = argparse.ArgumentParser()
parser.add_argument("-optimizer", help="optimizer to use", type=str, default="Uno")
parser.add_argument("-task", help="type of run to do", type=str, default="run_model")
parser.add_argument(
    "-struct_material", help="type of structural material", type=str, default="aluminum"
)
parser.add_argument(
    "-ref_half_mass",
    help="Half-aircraft mass (airframe, fuel, etc) in kg excluding the modeled half-wingbox mass, which TACS adds separately",
    type=float,
    default=10000.0,
)
parser.add_argument(
    "-struct_panel_thickness",
    help="thickness of structural shells/panels in meters",
    type=float,
    default=0.01,
)
# Stiffener lengths are supplied directly in meters by the calling skills.
parser.add_argument(
    "-stiffener_pitch",
    help="Stiffener spacing in meters, transverse to the stiffeners",
    type=float,
    default=0.2,
)
parser.add_argument(
    "-stiffener_height",
    help="Initial stiffener height in meters",
    type=float,
    default=0.02,
)
parser.add_argument(
    "-stiffener_thickness",
    help="Initial stiffener thickness in meters",
    type=float,
    default=0.005,
)
parser.add_argument(
    "-stiffener_flange_fraction",
    help="Dimensionless ratio of stiffener flange width to stiffener height",
    type=float,
    default=1.0,
)
parser.add_argument(
    "-struct_safety_factor",
    help="safety factor for structures",
    type=float,
    default=1.5,
)
parser.add_argument("-angle_of_attack", help="angle of attack", type=float, default=3.0)
parser.add_argument(
    "-fixed_force",
    help="Automatically vary the angle of attack to compute drag at the force balance lift=weight. 0: disable. 1: enable",
    type=int,
    default=0,
)
parser.add_argument(
    "-load_factor",
    help="Wing load factor for each optimization point. 1.5 means lift must be 1.5 times weight.",
    type=float,
    nargs="+",
    default=[1.0],
)
parser.add_argument(
    "-multipoint_weight",
    help="Objective weight for each load-factor optimization point.",
    type=float,
    nargs="+",
    default=[1.0],
)
parser.add_argument("-mach_number", help="mach number", type=float, default=0.2)
parser.add_argument(
    "-solver_name",
    help="Resolved solver name passed by the calling skill.",
    type=str,
    required=True,
)
parser.add_argument(
    "-turbulence_model",
    help="OpenFOAM RANS turbulence model. Supported values are `SpalartAllmaras` (SA) and `kOmegaSST` (SST).",
    type=str,
    default="SpalartAllmaras",
)
parser.add_argument("-reynolds_number", help="Reynolds number", type=float, default=5e6)
parser.add_argument(
    "-max_opt_iters", help="Maximum optimization iterations", type=int, default=50
)
parser.add_argument(
    "-max_adj_iters",
    help="The max GMRES iterations for the adjoint solve",
    type=int,
    default=1000,
)
parser.add_argument(
    "-pc_fill_level",
    help="The ILU fill level for the adjoint preconditioner",
    type=int,
    default=1,
)
parser.add_argument(
    "-primal_min_iters",
    help="Minimum number of primal iterations",
    type=int,
    default=200,
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
    "-nlbgs_rel_tol",
    help="Relative tolerance for the aerostructural NLBGS solver",
    type=float,
    default=1e-7,
)
parser.add_argument(
    "-nlbgs_abs_tol",
    help="Absolute tolerance for the aerostructural NLBGS solver",
    type=float,
    default=2.0,
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
    "-chords",
    help="airfoil chords for each spanwise section",
    nargs="+",
    type=float,
    default=[1.0, 1.0],
)
parser.add_argument(
    "-spans",
    help="N-1 sectional HALF-WING SPAN lengths in meters, one per span segment ordered wing root to tip.",
    nargs="+",
    type=float,
    default=[3.0],
)
parser.add_argument(
    "-sweeps",
    help="leading-edge sweep angles in degrees for each wing segment",
    nargs="+",
    type=float,
    default=[0.0],
)
parser.add_argument(
    "-dihedrals",
    help="dihedral angles in degrees for each wing segment",
    nargs="+",
    type=float,
    default=[0.0],
)
parser.add_argument(
    "-twists",
    help="twist angles in degrees for each non-root section",
    nargs="+",
    type=float,
    default=[0.0],
)
parser.add_argument(
    "-le_radius_constraint",
    help="LE radius constraint lower bound (-1 to disable)",
    type=float,
    default=1.0,
)
parser.add_argument(
    "-thickness_constraint",
    help="Thickness constraint lower bound (-1 to disable)",
    type=float,
    default=0.5,
)
parser.add_argument(
    "-volume_constraint",
    help="Volume constraint lower bound (-1 to disable)",
    type=float,
    default=1.0,
)
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

# A weighted drag objective requires one weight for every maneuver load case.
if len(args.load_factor) != len(args.multipoint_weight):
    raise ValueError(
        "`load_factor` and `multipoint_weight` must have the same number of entries; "
        f"received {len(args.load_factor)} and {len(args.multipoint_weight)}."
    )

# =============================================================================
# Input Parameters
# =============================================================================

# Clean up previous run results
if MPI.COMM_WORLD.rank == 0:
    os.system("rm -rf postProcessing")
    os.system("rm -rf processor* 0.00* ")
    os.system("rm -rf *.bin *.info *.jpeg *.png reports *.hst")
    os.system("rm -rf {1..9}*")

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

n_sections = len(args.chords)
nMultipoints = len(args.load_factor)
time_op = "average" if args.task == "run_model" else "final"

IC = {
    "U": [Ux, 0.0, Uz],
    "p": p0,
    "T": T0,
    "nuTilda": nuTilda0,
    "k": k0,
    "omega": omega0,
}

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
        "nStepsFrac": 0.5,
    },
    "primalMinIters": args.primal_min_iters,
    "printInterval": 10,
    "writeSurfForces": {"active": True, "patchNames": ["wing"]},
    # Warm starts keep the staged 0/ field; cold starts reset to the uniform freestream IC.
    "primalInitCondition": {} if args.initialize_from is not None else IC,
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
        "gmresRelTol": 1.0e-2,  # set relative tolerance for block Gauss-Seidel adjoint
        "pcFillLevel": args.pc_fill_level,
        "jacMatReOrdering": "natural",
        "gmresMaxIters": args.max_adj_iters,
        "gmresRestart": args.max_adj_iters,
        "useNonZeroInitGuess": True,
        "dynAdjustTol": True,
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
    "outputInfo": {
        "f_aero": {
            "type": "forceCouplingOutput",
            "patches": ["wing"],
            "components": ["forceCoupling"],
            "pRef": p0,
        },
    },
    "checkMeshThreshold": {
        "maxNonOrth": 80.0,
        "maxSkewness": 10.0,
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


# ********* TACS setup *********
if args.struct_material == "aluminum":
    struct_rho = 2780.0  # density, kg/m^3
    struct_E = 73.1e9  # elastic modulus, Pa
    struct_nu = 0.33  # poisson's ratio
    struct_kcorr = 5.0 / 6.0  # shear correction factor
    struct_ys = 324.0e6  # yield stress, Pa
else:
    print("struct_material arg not supported!")
    exit(1)


t0 = args.struct_panel_thickness  # m
tMin = 0.002  # m
tMax = 0.05  # m
gravity = 9.81

# TACS Smeared-stiffener dimensions
# The bdf meshes ribs, spars, and skins only; reinforcement stiffeners are analytically modelled (smeared).
stiffenerPitch = args.stiffener_pitch  # m
stiffenerHeight = args.stiffener_height  # m
stiffenerThickness = args.stiffener_thickness  # m
flangeFraction = args.stiffener_flange_fraction  # flange width / stiffener height
panelDVStart = {}


def element_callback(dvNum, compID, compDescript, elemDescripts, specialDVs, **kwargs):
    prop = constitutive.MaterialProperties(
        rho=struct_rho, E=struct_E, nu=struct_nu, ys=struct_ys
    )
    # A single isotropic ply represents metal, not a composite layup.
    # In the supplied TACS source, its default modified Tsai-Wu criterion
    # reduces to von Mises for isotropic MaterialProperties.
    ply = constitutive.OrthotropicPly(1.0, prop)
    angles = np.array([0.0], dtype=TACS.dtype)
    fractions = np.array([1.0], dtype=TACS.dtype)
    panelDVStart[compID] = dvNum
    con = constitutive.BladeStiffenedShellConstitutive(
        panelPly=ply,
        stiffenerPly=ply,
        kcorr=struct_kcorr,
        panelLength=0.5,
        panelLengthNum=dvNum,
        stiffenerPitch=stiffenerPitch,
        panelThick=t0,
        panelThickNum=dvNum + 1,
        panelPlyAngles=angles,
        panelPlyFracs=fractions,
        stiffenerHeight=stiffenerHeight,
        stiffenerHeightNum=dvNum + 2,
        stiffenerThick=stiffenerThickness,
        stiffenerThickNum=dvNum + 3,
        stiffenerPlyAngles=angles,
        stiffenerPlyFracs=fractions,
        flangeFraction=flangeFraction,
    )
    con.setPanelThicknessBounds(tMin, tMax)
    con.setStiffenerThicknessBounds(tMin, tMax)
    # Minimum flange width 25.4 mm; maximum prevents overlap at fixed
    # pitch. These are preliminary benchmark sizing rules.
    con.setStiffenerHeightBounds(
        max(0.018, 0.0254 / flangeFraction), stiffenerPitch / flangeFraction
    )
    con.setKSWeight(50.0)
    con.setFailureModes(
        includePanelMaterialFailure=True,
        includeStiffenerMaterialFailure=True,
        includeLocalBuckling=True,
        includeGlobalBuckling=True,
        includeStiffenerColumnBuckling=True,
        # The BladeStiffenedShellConstitutive built-in empirical crippling formula is for composites.
        # A metallic crippling allowable is not supplied in this case.
        includeStiffenerCrippling=False,
    )
    # wingbox axes: X chordwise, Y spanwise, Z vertical.
    # Skin reinforcement runs spanwise; rib/spar reinforcement vertically.
    refAxis = np.array([0.0, 1.0, 0.0] if "SKIN" in compDescript else [0.0, 0.0, 1.0])
    transform = elements.ShellRefAxisTransform(refAxis)
    # scaling factors for: panel length, panel thickness, stiffener height, and stiffener thickness DV.
    scales = [1.0, 100.0, 10.0, 100.0]

    # The current wingbox contains CQUAD4 shells only.
    return [elements.Quad4Shell(transform, con) for _ in elemDescripts], scales


def panel_length_constraint(fea_assembler):
    """Return geometry-to-DV length equalities for the stiffened panels."""
    constraint = fea_assembler.createPanelLengthConstraint("PanelLengthCon")
    # Use TACS's built-in panel-length calculation and sensitivities.
    constraint.addConstraint("PanelLength", compIDs=sorted(panelDVStart), dvIndex=0)
    return constraint


def initial_design_vars(struct_builder):
    """Return TACS's mixed DV vector with panel lengths set from the BDF mesh."""
    dvs = struct_builder.get_initial_dvs()
    constraint = panel_length_constraint(struct_builder.get_fea_assembler())
    values = {}
    constraint.evalConstraints(values)
    # TACS's residual is geometric length minus the original length DV.
    # Project initial lengths so run_model also uses physical bay lengths.
    for compID, residual in zip(
        sorted(panelDVStart), values["PanelLengthCon_PanelLength"]
    ):
        dvs[panelDVStart[compID]] += np.real(residual)
    return dvs


def constraint_setup(scenario_name, fea_assembler, constraints):
    """Append panel-length equalities and stiffener sizing constraints."""
    panelIDs = sorted(panelDVStart)
    constraints.append(panel_length_constraint(fea_assembler))

    # h/ts in [5, 30]; stiffener thickness <= 15 times panel thickness.
    sizing = fea_assembler.createDVConstraint("SizingCon")
    sizing.addConstraint(
        "aspectMin",
        compIDs=panelIDs,
        dvIndices=[2, 3],
        dvWeights=[1.0, -5.0],
        lower=0.0,
    )
    sizing.addConstraint(
        "aspectMax",
        compIDs=panelIDs,
        dvIndices=[2, 3],
        dvWeights=[1.0, -30.0],
        upper=0.0,
    )
    sizing.addConstraint(
        "flangeThicknessMax",
        compIDs=panelIDs,
        dvIndices=[1, 3],
        dvWeights=[-15.0, 1.0],
        upper=0.0,
    )
    constraints.append(sizing)


def problem_setup(scenario_name, fea_assembler, problem):
    # Add TACS Functions
    # Only include mass from elements that belong to pytacs components (i.e. skip concentrated masses)
    problem.addFunction("mass", functions.StructuralMass)
    problem.addFunction(
        "ks_failure",
        functions.KSFailure,
        safetyFactor=args.struct_safety_factor,
        ksWeight=50.0,
    )

    # Select the maneuver inertial load that belongs to this coupled scenario.
    scenario_index = int(scenario_name.removeprefix("scenario"))
    # For an n-g pull-up, the aircraft-frame effective acceleration is -n*g
    # in the vertical direction.
    g = np.array([0.0, 0.0, -gravity * args.load_factor[scenario_index]])  # m/s^2
    problem.addInertialLoad(g)


# ********* TACS setup done *********


# Top class to setup the optimization problem
class Top(Multipoint):
    def setup(self):

        # create the builder to initialize the DASolvers
        aero_builder = DAFoamBuilder(daOptions, meshOptions, scenario="aerostructural")
        aero_builder.initialize(self.comm)

        # add the aerodynamic mesh component
        self.add_subsystem("mesh_aero", aero_builder.get_mesh_coordinate_subsystem())

        # create the builder to initialize TACS
        struct_builder = TacsBuilder(
            mesh_file="wingbox.bdf",
            element_callback=element_callback,
            problem_setup=problem_setup,
            constraint_setup=constraint_setup,
            coupling_loads=["f_aero_struct"],
        )
        struct_builder.initialize(self.comm)

        # add the structure mesh component
        self.add_subsystem(
            "mesh_struct", struct_builder.get_mesh_coordinate_subsystem()
        )

        # load and displacement transfer builder (meld), isym sets the symmetry plan axis (j)
        xfer_builder = MeldBuilder(
            aero_builder, struct_builder, isym=1, check_partials=True
        )
        xfer_builder.initialize(self.comm)

        # add the design variable component to keep the top level design variables
        dvs = self.add_subsystem("dvs", om.IndepVarComp(), promotes=["*"])

        # Keep the aero-struct geometry parameterization on the same VSP model used by the aero path.
        projTol = 0.02 * L0
        self.add_subsystem(
            "geometry",
            OM_DVGEOCOMP(file="wing.vsp3", type="vsp", options={"projTol": projTol}),
            promotes=["*"],
        )

        # Use the CLI tolerances so the skill can control NLBGS convergence settings per case.
        # primal and adjoint solution options, i.e., nonlinear block Gauss-Seidel for aerostructural analysis
        # and linear block Gauss-Seidel for the coupled adjoint
        nonlinear_solver = om.NonlinearBlockGS(
            maxiter=10,
            iprint=2,
            use_aitken=True,
            rtol=args.nlbgs_rel_tol,
            atol=args.nlbgs_abs_tol,
        )
        linear_solver = om.LinearBlockGS(
            maxiter=5, iprint=2, use_aitken=True, rtol=1e-4, atol=1e-5
        )
        # Add one coupled aero-structural scenario for each maneuver load condition.
        for i in range(nMultipoints):
            self.mphys_add_scenario(
                f"scenario{i}",
                ScenarioAeroStructural(
                    aero_builder=aero_builder,
                    struct_builder=struct_builder,
                    ldxfer_builder=xfer_builder,
                ),
                nonlinear_solver,
                linear_solver,
            )
            # All points share the same geometry but retain independent coupled states.
            self.connect("x_aero0_geometry_output", f"scenario{i}.x_aero0")
            self.connect("x_struct0_geometry_output", f"scenario{i}.x_struct0")

        # add the structural thickness DVs
        # Each bay has length, panel thickness, stiffener height/thickness DVs.
        # Initialize length from its mesh boundary before the first analysis.
        dvs.add_output("dv_struct", initial_design_vars(struct_builder))
        for i in range(nMultipoints):
            self.connect("dv_struct", f"scenario{i}.dv_struct")
        lower, upper = struct_builder.get_dv_bounds()
        self.add_design_var(
            "dv_struct",
            lower=lower,
            upper=upper,
            scaler=struct_builder.get_dv_scalers(),
        )

        # more manual connection
        self.connect("mesh_aero.x_aero0", "x_aero0_geometry_input")
        self.connect("mesh_struct.x_struct0_mesh", "x_struct0_geometry_input")

        # thickness constraint
        varA = []
        varB = []
        for i in range(n_sections):
            for j in range(args.profile_fit_coeff_count):
                varA.append(f"Wing:UpperCoeff_{i}:Au_{j}")
                varB.append(f"Wing:LowerCoeff_{i}:Al_{j}")
        self.add_subsystem(
            "thickness",
            DAFoamLinearConstraint(
                varA=varA,
                coeffA=1.0,
                varB=varB,
                coeffB=-1.0,
                size=1,
                output_name="thickness_val",
            ),
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
            DAFoamLinearConstraint(
                varA=varA,
                coeffA=1.0,
                varB=varB,
                coeffB=1.0,
                size=1,
                output_name="le_c1_val",
            ),
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

        # Balance each half-wing lift against its maneuver-weight requirement.
        for i in range(nMultipoints):
            self.add_subsystem(
                f"force_balance{i}",
                om.ExecComp(
                    "val=(CL*0.5*U0*U0*A0*rho0-lf*(wing_mass+ref_half_mass)*g)/1000.0", # unit of imbalance is kN
                    U0={"val": U0, "constant": True},
                    A0={"val": A0, "constant": True},
                    rho0={"val": rho0, "constant": True},
                    g={"val": gravity, "constant": True},
                    ref_half_mass={"val": args.ref_half_mass, "constant": True},
                    lf={"val": args.load_factor[i], "constant": True},
                ),
            )
            self.connect(f"scenario{i}.aero_post.CL", f"force_balance{i}.CL")
            self.connect(f"scenario{i}.mass", f"force_balance{i}.wing_mass")

        # Combine point drag coefficients into the weighted multipoint objective.
        self.add_subsystem(
            "multipoint",
            MultiPointObjective(
                n_points=nMultipoints,
                weights=args.multipoint_weight,
            ),
        )

    def configure(self):

        active_dvs = set(args.active_design_vars)

        # call this to configure the coupling solver
        super().configure()

        # get the surface coordinates from the mesh component
        points = self.mesh_aero.mphys_get_surface_mesh()

        # add pointset for both aero and struct
        self.geometry.nom_add_discipline_coords(
            MPhysVariables.Aerodynamics.Surface.Geometry, points
        )
        self.geometry.nom_add_discipline_coords(MPhysVariables.Structures.Geometry)

        # add sectional airfoil shape var
        CST = args.cst_coeffs
        for i in range(n_sections):
            for j in range(args.profile_fit_coeff_count):
                self.geometry.nom_addVSPVariable(
                    "Wing", f"UpperCoeff_{i}", f"Au_{j}", scaledStep=False, dh=1e-5
                )
                self.geometry.nom_addVSPVariable(
                    "Wing", f"LowerCoeff_{i}", f"Al_{j}", scaledStep=False, dh=1e-5
                )
                self.dvs.add_output(
                    f"Wing:UpperCoeff_{i}:Au_{j}",
                    val=CST[2 * i * args.profile_fit_coeff_count + j],
                )
                self.dvs.add_output(
                    f"Wing:LowerCoeff_{i}:Al_{j}",
                    val=CST[(2 * i + 1) * args.profile_fit_coeff_count + j],
                )
                if "cst_coeffs" in active_dvs:
                    self.add_design_var(
                        f"Wing:UpperCoeff_{i}:Au_{j}",
                        lower=-0.5,
                        upper=0.5,
                        scaler=2.0,
                    )
                    self.add_design_var(
                        f"Wing:LowerCoeff_{i}:Al_{j}",
                        lower=-0.5,
                        upper=0.5,
                        scaler=2.0,
                    )

        # add sectional twist var
        for i in range(1, n_sections):
            self.geometry.nom_addVSPVariable(
                "Wing", f"XSec_{i}", "Twist", scaledStep=False, dh=1e-5
            )
            self.dvs.add_output(f"Wing:XSec_{i}:Twist", val=args.twists[i - 1])
            if "twists" in active_dvs:
                self.add_design_var(
                    f"Wing:XSec_{i}:Twist", lower=-5.0, upper=5.0, scaler=0.1
                )

        # add sectional span var
        for i in range(1, n_sections):
            self.geometry.nom_addVSPVariable(
                "Wing", f"XSec_{i}", "Span", scaledStep=False, dh=1e-5
            )
            self.dvs.add_output(f"Wing:XSec_{i}:Span", val=args.spans[i - 1])
            if "spans" in active_dvs:
                self.add_design_var(
                    f"Wing:XSec_{i}:Span", lower=0.01, upper=10.0, scaler=0.1
                )

        # add sectional sweep var
        for i in range(1, n_sections):
            self.geometry.nom_addVSPVariable(
                "Wing", f"XSec_{i}", "Sweep", scaledStep=False, dh=1e-5
            )
            self.dvs.add_output(f"Wing:XSec_{i}:Sweep", val=args.sweeps[i - 1])
            if "sweeps" in active_dvs:
                self.add_design_var(
                    f"Wing:XSec_{i}:Sweep", lower=-10.0, upper=10.0, scaler=0.1
                )

        # add sectional dihedral var
        for i in range(1, n_sections):
            self.geometry.nom_addVSPVariable(
                "Wing", f"XSec_{i}", "Dihedral", scaledStep=False, dh=1e-5
            )
            self.dvs.add_output(f"Wing:XSec_{i}:Dihedral", val=args.dihedrals[i - 1])
            if "dihedrals" in active_dvs:
                self.add_design_var(
                    f"Wing:XSec_{i}:Dihedral", lower=0, upper=5.0, scaler=0.1
                )

        # add sectional chord var
        self.geometry.nom_addVSPVariable(
            "Wing", "XSec_1", "Root_Chord", scaledStep=False, dh=1e-5
        )
        self.dvs.add_output("Wing:XSec_1:Root_Chord", val=args.chords[0])
        if "chords" in active_dvs:
            self.add_design_var(
                "Wing:XSec_1:Root_Chord", lower=0.01, upper=5.0, scaler=0.2
            )
        for i in range(1, n_sections):
            self.geometry.nom_addVSPVariable(
                "Wing", f"XSec_{i}", "Tip_Chord", scaledStep=False, dh=1e-5
            )
            self.dvs.add_output(f"Wing:XSec_{i}:Tip_Chord", val=args.chords[i])
            if "chords" in active_dvs:
                self.add_design_var(
                    f"Wing:XSec_{i}:Tip_Chord", lower=0.01, upper=5.0, scaler=0.2
                )

        # Each point trims its own AoA while all points share the structural DVs.
        for i in range(nMultipoints):
            self.dvs.add_output(f"patchV{i}", val=np.array([U0, aoa0]))
            self.connect(f"patchV{i}", f"scenario{i}.patchV")
            self.add_design_var(
                f"patchV{i}", lower=[U0, 0.0], upper=[U0, 10.0], scaler=0.1
            )

        # Add the weighted drag objective and force/failure constraints for every point.
        self.add_objective("multipoint.obj", scaler=50.0)
        for i in range(nMultipoints):
            self.connect(f"scenario{i}.aero_post.CD", f"multipoint.obj_point_{i}")
            self.add_constraint(f"force_balance{i}.val", equals=0.0, scaler=1.0)
            self.add_constraint(f"scenario{i}.ks_failure", lower=0.0, upper=1.0, scaler=1.0)

        # Length equalities track VSP geometry; stiffener sizing stays linear.
        # IMPORTANT, multipoint needs to link the panelLength to ONLY the first scenario becasue all
        # scenarios share the same geometry
        for system in self.scenario0.struct_post.constraints.system_iter():
            constraint = system.constr
            is_linear = constraint.isLinear
            bounds = {}
            constraint.getConstraintBounds(bounds)
            for name in constraint.getConstraintKeys():
                lower, upper = bounds[f"{system.name}_{name}"]
                path = f"scenario0.{system.name}.{name}"
                if np.all(lower == upper):
                    self.add_constraint(path, equals=lower, linear=is_linear)
                else:
                    self.add_constraint(
                        path, lower=lower, upper=upper, linear=is_linear
                    )

        # volume constraint
        if args.volume_constraint > 0:
            self.add_constraint("volume_val", lower=args.volume_constraint, scaler=1.0)

        # thickness constraint
        if args.thickness_constraint >= 0:
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
        if args.le_radius_constraint > 0:
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
        # LE C1 continuous
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

if args.task == "run_driver":
    # Trim every maneuver point before the optimizer changes the shared geometry.
    force_balance_names = [f"force_balance{i}.val" for i in range(nMultipoints)]
    patch_v_names = [f"patchV{i}" for i in range(nMultipoints)]
    optFuncs.findFeasibleDesign(
        force_balance_names + ["scenario0.ks_failure"],
        patch_v_names + ["dv_struct"],
        targets=[0.0] * nMultipoints + [1.0],
        designVarsComp=[1] * nMultipoints + ["1:4:-1"],
        designVarsBound=[[0.0, 10.0]] * nMultipoints + [[tMin, tMax]],
        epsFD=[1e-2] * nMultipoints + [1e-4],
        tol=0.01,
        maxIter=5,
    )
    # Record modeled half-wingbox mass after lift trimming and before optimization.
    mass_initial = prob.get_val("scenario0.mass").item()
    if MPI.COMM_WORLD.rank == 0:
        print(f"AERO_STRUCT_MASS_INITIAL_KG: {mass_initial:.16e}", flush=True)
    # run the optimization
    prob.run_driver()
    # Record the mass at the state returned by the optimization driver.
    mass_final = prob.get_val("scenario0.mass").item()
    if MPI.COMM_WORLD.rank == 0:
        print(f"AERO_STRUCT_MASS_FINAL_KG: {mass_final:.16e}", flush=True)
        # Write the final OpenVSP design before marking the optimization complete.
        prob.model.geometry.nom_getDVGeo().writeVSPFile("wing_opt.vsp3")
elif args.task == "run_model":
    # Adjust the angle of attack independently for every coupled fixed-force condition.
    if args.fixed_force == 1:
        optFuncs.findFeasibleDesign(
            [f"force_balance{i}.val" for i in range(nMultipoints)],
            [f"patchV{i}" for i in range(nMultipoints)],
            targets=[0.0] * nMultipoints,
            designVarsComp=[1] * nMultipoints,
            epsFD=[1e-2] * nMultipoints,
            tol=0.01,
            maxIter=5,
        )
    # Run the final coupled primal at either the requested angle of attack or the feasible fixed-lift condition.
    prob.run_model()
    # Retrieve final structural outputs on all ranks; only rank zero writes the analysis markers.
    ks_failure = prob.get_val("scenario0.ks_failure").item()
    wing_mass = prob.get_val("scenario0.mass").item()
    if MPI.COMM_WORLD.rank == 0:
        print(f"AERO_STRUCT_KS_FAILURE: {ks_failure:.16e}", flush=True)
        print(f"AERO_STRUCT_MASS_KG: {wing_mass:.16e}", flush=True)
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
