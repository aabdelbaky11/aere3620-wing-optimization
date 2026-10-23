# C000 Conventional Baseline Rerun

- **Workflow lead:** Gabriel Cortes 
- **Tools:** Meshing and Physics solved through Star CCM+, Geometry created through SOLIDOWORKS.
- **Run date:** 10/9/2026

Disregard all information from the previous baseline simulation. It was a mistake on my part to use the Siemens built in CAD desktop. I will use SOLIDWORKS from now on to prevent geometry issues.

## Simulation Conditions

- **Domain:** The simulation domain is a half sphere with a 20 m radius and symmetry plane to reduce computational time.
- **Angle of Attack:** 5.840°
- **Lift Coefficient:** 0.4006155
- **Drag Coefficient:** 0.0206204
- **Wing Volume:** .24688 m^3  (SOLIDWORKS Mass Properties)

> **Geometry Note:** The required angle of attack changed significantly after implementing a more accurate and refined airfoil geometry, specifically near the leading edge.

---

## Physics

- **Solver:** Reynolds-Average Navier-Stokes (RANS)
- **Flow Solver:** Segregated
- **Equation of State:** Ideal Gas
- **Energy Solver:** Segregated Fluid Enthalpy
- **Time:** Steady
- **Turbulence Model:** Spalart-Allmars

---

## Pressure

- The unnaturally high pressure coefficients stemmed from an incorrect unit conversion occurring in the pressure field function.
- The poor airfoil geometry was still causing unphysical pressure gradients near the leading edge of the wing, so different geometry was created in SOLIDWORKS and imported into STAR CCM+.  
  
---

## Mesh Quality

| Mesh Parameter | Value |
|:---------------|------:|
| Cell Count | 439,710 |
| Maximum Skewness Angle | 78.10109° |
| Minimum Cell Volume | 3.376389 × 10⁻⁹ m³ |
| Maximum Aspect Ratio | 1.000000 |
| Minimum Aspect Ratio | 0.07667843 |
| Maximum Wall Y+ | 96.4 |
| Minimum Wall Y+ | 31 |

> **Cell Count Note:** This value is very close to the upper limit. This was done intentionally to increase fidelity and attempt to lower residual convergence. This value will be monitored closely in the following iterations to ensure is does not cross the upper bound.
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
