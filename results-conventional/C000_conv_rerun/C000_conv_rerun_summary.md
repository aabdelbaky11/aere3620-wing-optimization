# C000 Conventional Baseline Rerun

- **Workflow lead:** Gabriel Cortes 
- **Tools:** Meshing and Physics solved through Star CCM+, Geometry created through SOLIDOWORKS.
- **Run date:** 11/13/2026

## Simulation Conditions

- **Domain:** The simulation domain is a half sphere with a 20 m radius and symmetry plane to reduce computational time.
- **Angle of Attack:** 5.840°
- **Lift Coefficient:** 0.4002621280206307
- **Drag Coefficient:** 0.020616811734479785
- **Wing Volume:** .24688 m^3  (SOLIDWORKS Mass Properties)

---

## Physics

- **Solver:** Reynolds-Average Navier-Stokes (RANS)
- **Flow Solver:** Segregated
- **Equation of State:** Ideal Gas
- **Energy Solver:** Segregated Fluid Enthalpy
- **Time:** Steady
- **Turbulence Model:** Spalart-Allmars

---

## Mesh Quality

| Mesh Parameter | Value |
|:---------------|------:|
| Cell Count | 4.393690e+05 |
| Maximum Skewness Angle | 8.000345e+01 |
| Minimum Cell Volume | 3.376389e-09 m³ |
| Maximum Aspect Ratio | 1.000000e+00 |
| Minimum Aspect Ratio | 7.667843e-02 |
| Maximum Wall Y+ | 96.1 |
| Minimum Wall Y+ | 31.3 |

> **Prism Layer Stretching:** This simulation was rerun with a Prism Layer Stretching of 1.2, instead of the previous 1.3. This is seen in the slight changes in Max Skewness and Wall Y+.
---

## Residual Convergence

| Monitor | Final Value |
|:--------|------------:|
| Y-momentum | 1.586465e-05 |
| X-momentum | 4.747554e-05 |
| Z-momentum | 3.878001e-05 |    
| Continuity | 2.032425e-05 |
| Sa_nut | 2.322427e-04 |   
| Energy | 6.756482e-04 |
