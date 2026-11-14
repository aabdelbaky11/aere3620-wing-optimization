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

---

## Residual Convergence

| Monitor | Final Value |
|:--------|------------:|
| Y-momentum | 2.107085 × 10⁻⁵ |
| X-momentum | 4.778652 × 10⁻⁵ |
| Z-momentum | 3.936199 × 10⁻⁵ |    
| Continuity | 1.603164 × 10⁻⁵ |
| Sa_nut | 2.461740 × 10⁻⁴ |   
| Energy | 7.130536 × 10⁻⁴ |

> **Convergence Note:** The residuals did not reach the required value of 10⁻⁶. Additional reductions could not be achieved without altering the fundamental physical or numerical parameters of the simulation. I did consult professor He about this issue and he informed me that these residuals are okay and indicate numerical convergence for the simulation. 

