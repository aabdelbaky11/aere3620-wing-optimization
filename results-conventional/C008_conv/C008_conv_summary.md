# C008 Taper .30 

- **Workflow lead:** Gabriel Cortes 
- **Tools:** Meshing and Physics solved through Star CCM+, Geometry created through SOLIDOWORKS.
- **Run date:** 11/6/2026

## Simulation Conditions

- **Domain:** The simulation domain is a half sphere with a 20 m radius and symmetry plane to reduce computational time.
- **Angle of Attack:** 5.145°
- **Lift Coefficient:**  0.4000218225017766
- **Drag Coefficient:**  0.0199494792246778
- **Wing Volume:**   0.250497 m^3  (SOLIDWORKS Mass Properties)

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

## Mesh Quality

| Mesh Parameter | Value |
|:---------------|------:|
| Cell Count | 4.241460e+05  |
| Maximum Skewness Angle | 8.398702e+01 |
| Minimum Cell Volume | 4.460089e-10 |
| Maximum Aspect Ratio |  |
| Minimum Aspect Ratio |  |
| Maximum Wall Y+ |  |
| Minimum Wall Y+ |  |

---

## Residual Convergence

| Monitor | Final Value |
|:--------|------------:|
| Y-momentum |  |
| X-momentum |  |
| Z-momentum |  |    
| Continuity |  |
| Sa_nut |  |   
| Energy |  |
