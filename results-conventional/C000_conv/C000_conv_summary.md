# CFD Simulation Results

## Simulation Conditions

- **Domain Radius:** 20 m
- **Angle of Attack:** 5.84°
- **Lift Coefficient:** 0.4006155
- **Drag Coefficient:** 0.0206204

> **Geometry Note:** The required angle of attack changed significantly after implementing a more accurate and refined airfoil geometry.

---

## Pressure Results

- **Pressure Coefficients are plotted across the wing**

---

## Mesh Quality

| Mesh Parameter | Value |
|:---------------|------:|
| Cell Count | 439,710 |
| Maximum Skewness Angle | 78.10109° |
| Minimum Cell Volume | 3.376389 × 10⁻⁹ m³ |
| Maximum Aspect Ratio | 1.000000 |
| Minimum Aspect Ratio | 0.07667843 |
| Maximum Wall Y+ |  |

---

## Residual and Drag Convergence

| Monitor | Final Value |
|:--------|------------:|
| Residual 1 | 2.107085 × 10⁻⁵ |
| Residual 2 | 4.778652 × 10⁻⁵ |
| Residual 3 | 1.603164 × 10⁻⁵ |
| Residual 4 | 3.936199 × 10⁻⁵ |
| Residual 5 | 7.130536 × 10⁻⁴ |
| Residual 6 | 2.461740 × 10⁻⁴ |

### Convergence Note

The residuals did not reach the required value of 10⁻⁶. Additional reductions could not be achieved without altering the fundamental physical or numerical parameters of the simulation. I did consult professor He about this issue and he informed me that these residuals are okay and indicate numerical convergence for the simulation. 
