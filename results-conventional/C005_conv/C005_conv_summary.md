# C005 Taper .35 

- **Workflow lead:** Gabriel Cortes 
- **Tools:** Meshing and Physics solved through Star CCM+, Geometry created through SOLIDOWORKS.
- **Run date:** 11/1/2026

## Simulation Conditions

- **Domain:** The simulation domain is a half sphere with a 20 m radius and symmetry plane to reduce computational time.
- **Angle of Attack:** 4.970°
- **Lift Coefficient:**  0.40004886812828294
- **Drag Coefficient:**  0.020139032850248473
- **Wing Volume:**  0.25948 m^3  (SOLIDWORKS Mass Properties)

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
| Cell Count |  |
| Maximum Skewness Angle |  |
| Minimum Cell Volume |  |
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
