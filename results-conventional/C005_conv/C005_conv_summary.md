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
| Cell Count | 4.269660e+05 |
| Maximum Skewness Angle | 8.397823e+01 |
| Minimum Cell Volume | 7.279439e-11 |
| Maximum Aspect Ratio | 1.000000e+00 |
| Minimum Aspect Ratio | 4.999585e-02 |
| Maximum Wall Y+ | 105 |
| Minimum Wall Y+ | 29.4 |

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
