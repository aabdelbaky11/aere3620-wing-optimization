# C008 Taper .30 

- **Workflow lead:** Gabriel Cortes 
- **Tools:** Meshing and Physics solved through Star CCM+, Geometry created through SOLIDOWORKS.
- **Run date:** 11/6/2026

## Simulation Conditions

- **Domain:** The simulation domain is a half sphere with a 20 m radius and symmetry plane to reduce computational time.
- **Angle of Attack:** 5.145°
- **Lift Coefficient:**  0.4000218225017766
- **Drag Coefficient:**  0.0199494792246778
- **Wing Volume:**  0. m^3  (SOLIDWORKS Mass Properties)

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
| Y-momentum | 1.883820e-05 |
| X-momentum | 5.394413e-05 |
| Z-momentum | 4.748741e-05 |    
| Continuity | 2.423281e-05 |
| Sa_nut | 3.105477e-04 |   
| Energy | 7.512714e-04 |
