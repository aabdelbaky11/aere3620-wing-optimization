# CFD Simulation Results

- **Workflow lead:** Gabriel Cortes (Conventional Workflow Lead)
- **Tools:** Meshing and Physics solved through Star CCM+, geometry created through SOLIDOWORKS.
- **Run date:** 10/9/2026

## Simulation Conditions

- **Domain:** The simulation domain is a half sphere with a 20 m radius and symmetry plane to reduce computational time.
- **Angle of Attack:** 5.84°
- **Lift Coefficient:** 0.4006155
- **Drag Coefficient:** 0.0206204
- **Wing Volume:** 2.4688 m^3

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

---

## Residual Convergence

| Monitor | Final Value |
|:--------|------------:|
| Y-momentum | 2.107085 × 10⁻⁵ |
| X-momentum | 4.778652 × 10⁻⁵ |
| Z-momentum | 1.603164 × 10⁻⁵ |
| Continuity | 3.936199 × 10⁻⁵ |
| Sa_nut | 7.130536 × 10⁻⁴ |
| Energy | 2.461740 × 10⁻⁴ |

### Convergence Note

The residuals did not reach the required value of 10⁻⁶. Additional reductions could not be achieved without altering the fundamental physical or numerical parameters of the simulation. I did consult professor He about this issue and he informed me that these residuals are okay and indicate numerical convergence for the simulation. 
