# Final Report Outline: Group 18 Wing Optimization

About 10 pages, excluding appendices (spec section 3.5). Owners are in brackets: DL = Abdelrahman (Design Lead), AI = Kade, CV = Gabriel.

## 1. Introduction [DL]
- The problem from Table 1: minimize CD subject to CL >= 0.4 and V_opt >= V_bl, with b/2 = 3.00 m, M = 0.3 and Re = 5.0e6
- The baseline wing (rectangular NACA 0012, c = 1.00 m) and the two-workflow approach

## 2. Methods
### 2.1 Optimization method and process [DL]
- Screening model: lifting-line induced drag plus a strip estimate of profile drag (llScreen.m), recalibrated to CFD after each run
- Constraint handling: chords sized to hold the volume (solveRootChord.m, vspVolume.m) and every case checked with checkDesign.m
- Design levers: taper, which pushes the lift distribution toward elliptical, and a thick root, which keeps the volume with less wetted area. Washout was dropped.
- Quadratic line search on taper (Lecture 11), run to convergence
- Fairness fixes: viscosity held fixed in the AI tool, and wings re-sized to remove the excess volume margin
### 2.2 AI-agent CFD workflow [AI]
- Tool, prompts, meshing (396,848 cells), solver settings, CL trimming, troubleshooting
### 2.3 Conventional CFD workflow [CV]
- SOLIDWORKS geometry, STAR-CCM+ mesh (about 424k–439k cells), SA model, prism layers, alpha trim
- Residual levels and the instructor's approval (quote it with the date)

## 3. Results
### 3.1 Baseline analysis, both workflows [AI, CV]
- CD at CL = 0.4, mesh statistics, y+, residual and CD histories, Cp at root/mid/tip, surface Cp contours
### 3.2 Design history [DL]
- C002 → C004 → C005 → C007 → C008 → C009 (design_history_week9.png), with predicted vs CFD values
- Line search convergence (screening_week9.png)
### 3.3 Optimized design C008 [DL with AI, CV]
- CD, CL and V in both workflows: AI 4.81%, conventional 3.24%, all constraints met
- Overlaid baseline and optimized Cp at root/mid/tip; airfoil profiles at root and tip
- 3D views of the baseline and optimized wings; mesh statistics for C008

## 4. Workflow comparison [all, DL compiles]
- Setup process, effort and time for each workflow [AI, CV]
- Agreement: absolute CD differs by 2.8% (baseline) and 4.5% (C008). The conventional workflow shows 58–69% of the AI drag reduction and 40% vs 69% of the theoretical alpha shift (workflow_gap_week10.png).
- Possible causes and limitations: section camber/incidence, wall functions vs near-wall resolution, residual level

## 5. Summary [DL]
- Final design, improvement in each workflow, bonus tier (+5), lessons learned

## Appendices
- Repo link, design_log.csv, MATLAB scripts (design-log/), CFD case files (results-ai/, results-conventional/)
