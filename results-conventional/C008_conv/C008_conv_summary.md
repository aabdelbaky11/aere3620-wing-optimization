# C008 Taper .30 

- **Workflow lead:** Gabriel Cortes 
- **Tools:** Meshing and Physics solved through Star CCM+, Geometry created through SOLIDOWORKS.
- **Run date:** 11/6/2026
- **Request:** `requests/request_C008_conv.md`

## Simulation Conditions

- **Domain:** The simulation domain is a half sphere with a 20 m radius and symmetry plane to reduce computational time.
- **Angle of Attack:** 5.145°
- **Lift Coefficient:**  0.4000218225017766
- **Drag Coefficient:**  0.0199494792246778
- **Wing Volume:**   0.250497 m^3  (SOLIDWORKS Mass Properties)

---

## Finding alpha for CL = 0.4

I ran C008 initially at the requested alpha1 of 5.15 degrees, this landed CL at .400312. 
I then ran C008 at a slightly smaller alpha2 of 5.145 degrees, and CL landed at .40002.

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
| Maximum Aspect Ratio | 1.000000e+00 |
| Minimum Aspect Ratio | 5.520679e-02 |
| Maximum Wall Y+ | 95.3 |
| Minimum Wall Y+ | 30.2 |

---

## Residual Convergence

| Monitor | Final Value |
|:--------|------------:|
| Y-momentum | 1.862257e-05 |
| X-momentum | 5.218539e-05 |
| Z-momentum | 4.404891e-05 |    
| Continuity | 2.319940e-05 |
| Sa_nut | 2.633675e-04 |   
| Energy | 7.380518e-04 |
