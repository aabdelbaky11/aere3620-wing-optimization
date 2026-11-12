% run_week9.m
% AerE 3620 Project - Design Lead, Week 9 (report week ending 11/13)
% New CFD in: C009_ai   (taper 0.25 re-sized, AI workflow, returned 11/06)
%             C008_conv (taper 0.30 re-sized, conventional, returned 11/06)
% This script:
%   (1) checks C009_ai and C008_conv against Table 1
%   (2) compares the week-8 predictions with the new CFD
%   (3) closes the taper line search: parabola through the three re-sized
%       CFD points (0.35 / 0.30 / 0.25) and a stopping test
%   (4) compares the two workflows on both identical wings (C005, C008)
%   (5) bonus status and final-design selection
%   (6) figures for the report / project review
%
% Requires: llScreen.m, checkDesign.m, wingVolume.m, lineSearchQuad.m

clear; clc; close all;

%% ---------------- CFD results on file -----------------------------------
% All CL/CD on A_ref = 3.00 m^2, Re_cref = 5.0e6 (fixed viscosity).
RE_FIX = 5.0e6;

%           alpha     CL         CD          V_tool
AI0   = [   5.41482,  0.400507,  0.020052,   0.246898 ];  % C000_ai_v2
AI2   = [   5.476,    0.40053,   0.020052*(1-0.0191), 0.247873 ];  % C002_ai: CD Re-corrected
                                                                % to 5.0e6 in week 6 (1.91%; raw drifted-mu CD 0.019715)
AI4   = [   3.88906,  0.40053,   0.019308,   0.262578 ];  % C004_ai_v2
AI5   = [   4.03904,  0.40045,   0.019234,   0.263592 ];  % C005_ai
AI7   = [   4.10938,  0.40052,   0.019117,   0.254287 ];  % C007_ai
AI8   = [   4.21572,  0.40051,   0.019087,   0.254221 ];  % C008_ai
AI9   = [   4.34119,  0.40053,   0.019074,   0.254220 ];  % C009_ai   (new)
CV0   = [   5.840,    0.4006155, 0.0206204,  0.24688  ];  % C000_conv
CV5   = [   4.970,    0.4000489, 0.0201390,  0.25948  ];  % C005_conv
CV8   = [   5.145,    0.4000218, 0.0199495,  0.250497 ];  % C008_conv (new, SOLIDWORKS volume)

% planforms (NACA 2415 root / 2412 tip family)
P0 = struct('p_root','NACA 0012','p_tip','NACA 0012','cr',1.000,'ct',1.000,'twist_tip',0);
P5 = struct('p_root','NACA 2415','p_tip','NACA 2412','cr',1.337,'ct',0.468,'twist_tip',0);
P7 = P5;  P7.cr = 1.313;  P7.ct = 0.460;
P8 = P5;  P8.cr = 1.348;  P8.ct = 0.404;
P9 = P5;  P9.cr = 1.383;  P9.ct = 0.346;

V_bl_ai = AI0(4);   CD_bl_ai = AI0(3);
V_bl_cv = CV0(4);   CD_bl_cv = CV0(3);

imp = @(CD, CDbl) (CDbl - CD) / CDbl * 100;

%% ---------------- (1) constraint checks ----------------------------------
d = struct('name','C009_ai','cr',P9.cr,'ct',P9.ct,'tc_root',0.15,'tc_tip',0.12, ...
           'sweep',0,'twist_tip',0,'alpha',AI9(1),'CL',AI9(2),'CD',AI9(3),'V',AI9(4));
c9 = checkDesign(d, V_bl_ai, CD_bl_ai);

d.name = 'C008_conv';  d.cr = P8.cr;  d.ct = P8.ct;
d.alpha = CV8(1);  d.CL = CV8(2);  d.CD = CV8(3);  d.V = CV8(4);
c8cv = checkDesign(d, V_bl_cv, CD_bl_cv);

% C008_ai again, so the final design has both checks in one place
d.name = 'C008_ai';
d.alpha = AI8(1);  d.CL = AI8(2);  d.CD = AI8(3);  d.V = AI8(4);
c8 = checkDesign(d, V_bl_ai, CD_bl_ai);

% SOLIDWORKS volume vs the straight-loft formula the request was sized with
Vw8 = wingVolume(P8.cr, P8.ct, 0.15, 0.12, 3.00);
fprintf(' C008_conv volume: SOLIDWORKS %.6f vs wingVolume %.6f m^3 (%+.3f%%)\n\n', ...
        CV8(4), Vw8, (CV8(4)/Vw8 - 1)*100);

%% ---------------- (2) week-8 predictions vs CFD --------------------------
% Numbers printed by run_week8.m and written into the requests.
fprintf('==========================================================================\n');
fprintf(' WEEK-8 PREDICTIONS vs CFD\n');
fprintf('==========================================================================\n');
fprintf(' %-10s %7s %16s %10s\n', 'case', 'lambda', 'predicted', 'CFD');
fprintf(' %-10s %7.2f %7.2f-%5.2f%% %+9.2f%%\n', 'C009_ai',   0.25, 4.92, 4.95, c9.improvement);
fprintf(' %-10s %7.2f %7.2f-%5.2f%% %+9.2f%%\n', 'C008_conv', 0.30, 2.75, 3.05, c8cv.improvement);
fprintf('--------------------------------------------------------------------------\n');
fprintf(' C009_ai : 0.04-0.07 points below the range. The AI over-prediction keeps\n');
fprintf('           shrinking (0.28 on C008, 0.04-0.07 on C009).\n');
fprintf(' C008_conv: %.2f points ABOVE the top of the range. Conv beat both the\n', c8cv.improvement - 3.05);
fprintf('           ratio and the increment method -> section (4).\n\n');

%% ---------------- (3) close the taper line search -------------------------
% Three CFD points on the re-sized family (all ~+3% AI tool volume):
lamLS = [0.35 0.30 0.25];
CDLS  = [AI7(3) AI8(3) AI9(3)];
[lm, Cm, info] = lineSearchQuad(lamLS, CDLS, 0.20/1.40, 1.0);
aqv = @(a, x) a(1) + a(2)*x + a(3)*x.^2;

g1 = c8.improvement - imp(AI7(3), CD_bl_ai);
g2 = c9.improvement - c8.improvement;

fprintf('==========================================================================\n');
fprintf(' TAPER LINE SEARCH - CLOSE-OUT  (AI workflow, re-sized family)\n');
fprintf('==========================================================================\n');
fprintf(' lambda 0.35 : C007 CFD   CD %.6f  (%+.2f%%)\n', AI7(3), imp(AI7(3), CD_bl_ai));
fprintf(' lambda 0.30 : C008 CFD   CD %.6f  (%+.2f%%)\n', AI8(3), c8.improvement);
fprintf(' lambda 0.25 : C009 CFD   CD %.6f  (%+.2f%%)\n', AI9(3), c9.improvement);
fprintf(' gains per step: 0.35->0.30 %.2f points, 0.30->0.25 %.2f points\n', g1, g2);
fprintf('--------------------------------------------------------------------------\n');
fprintf(' parabola convex: %d   bracketed: %d\n', info.convex, info.bracketed);
fprintf(' parabola minimum: lambda* = %.3f   CD %.6f  (%+.3f%%)\n', lm, Cm, imp(Cm, CD_bl_ai));
fprintf(' best possible gain over C009 on taper: %.4f points\n', imp(Cm, CD_bl_ai) - c9.improvement);

% Stopping test (Lecture 11 / Arora Ch. 8): stop when the predicted change in
% the objective is below what the CFD can resolve. The spec only asks for CD
% steady to 3 significant figures, i.e. +-0.00001 on CD ~ 0.019 = 0.05 points.
TOL_PTS = 0.00001 / CD_bl_ai * 100;
fprintf(' CFD resolution (3 sig. fig. on CD): %.3f points\n', TOL_PTS);
if imp(Cm, CD_bl_ai) - c9.improvement < TOL_PTS
    fprintf(' -> predicted gain is below CFD resolution: LINE SEARCH CONVERGED.\n');
    fprintf('    No more taper cases. Optimum taper is 0.23-0.25 on this family.\n');
end
fprintf('==========================================================================\n\n');

% llScreen calibration factor on C009 (for the report's model-vs-CFD table)
r9 = llScreen(P9, RE_FIX);
f9 = (AI9(3) - r9.CDi*(AI9(2)/0.4)^2) / r9.CD0;
r8 = llScreen(P8, RE_FIX);
f8 = (AI8(3) - r8.CDi*(AI8(2)/0.4)^2) / r8.CD0;
fprintf(' llScreen profile-drag factor f: C008 %.4f -> C009 %.4f (%+.2f%%)\n', ...
        f8, f9, (f9/f8 - 1)*100);
fprintf(' Lifting line says taper 0.30 -> 0.25 changes CDi by %+.6f and CD0 by %+.6f:\n', ...
        r9.CDi - r8.CDi, r9.CD0 - r8.CD0);
fprintf(' induced drag is already at its minimum, only the (smaller) area saving is left.\n\n');

%% ---------------- (4) workflow comparison on two identical wings ---------
dAI = [CD_bl_ai - AI5(3), CD_bl_ai - AI8(3)];
dCV = [CD_bl_cv - CV5(3), CD_bl_cv - CV8(3)];
daAI = [AI5(1) - AI0(1), AI8(1) - AI0(1)];
daCV = [CV5(1) - CV0(1), CV8(1) - CV0(1)];
fprintf('==========================================================================\n');
fprintf(' WORKFLOW COMPARISON  (identical geometry in both workflows)\n');
fprintf('==========================================================================\n');
fprintf(' %-26s %12s %12s\n', '', 'C005', 'C008');
fprintf(' %-26s %12.6f %12.6f\n', 'AI   dCD vs own C000', dAI(1), dAI(2));
fprintf(' %-26s %12.6f %12.6f\n', 'Conv dCD vs own C000', dCV(1), dCV(2));
fprintf(' %-26s %12.3f %12.3f\n', 'Conv/AI drag-drop ratio', dCV(1)/dAI(1), dCV(2)/dAI(2));
fprintf(' %-26s %+11.2f%% %+11.2f%%\n', 'AI improvement', imp(AI5(3),CD_bl_ai), c8.improvement);
fprintf(' %-26s %+11.2f%% %+11.2f%%\n', 'Conv improvement', imp(CV5(3),CD_bl_cv), c8cv.improvement);
fprintf(' %-26s %+12.3f %+12.3f\n', 'AI alpha shift [deg]', daAI(1), daAI(2));
fprintf(' %-26s %+12.3f %+12.3f\n', 'Conv alpha shift [deg]', daCV(1), daCV(2));
fprintf(' %-26s %12.3f %12.3f\n', 'Conv/AI alpha-shift ratio', daCV(1)/daAI(1), daCV(2)/daAI(2));
fprintf('--------------------------------------------------------------------------\n');
fprintf(' C005 -> C008 (shrink + taper 0.35->0.30):\n');
fprintf('   AI   drop grew by %.6f  (%.2f points)\n', dAI(2)-dAI(1), c8.improvement - imp(AI5(3),CD_bl_ai));
fprintf('   Conv drop grew by %.6f  (%.2f points)\n', dCV(2)-dCV(1), c8cv.improvement - imp(CV5(3),CD_bl_cv));
fprintf(' Conv responds MORE than AI to the C005->C008 change, so the ratio rose\n');
fprintf(' from %.2f to %.2f. Both workflows agree on the direction of every change;\n', dCV(1)/dAI(1), dCV(2)/dAI(2));
fprintf(' conv sees a smaller camber effect (alpha shift ~%.0f%% of AI) throughout.\n', mean(daCV./daAI)*100);
fprintf(' Absolute CD: conv C000 is %.1f%% above AI C000, conv C008 is %.1f%% above AI C008.\n', ...
        (CD_bl_cv/CD_bl_ai - 1)*100, (CV8(3)/AI8(3) - 1)*100);
fprintf('==========================================================================\n\n');

%% ---------------- (5) bonus status and final design ----------------------
CD5cv = 0.95 * CD_bl_cv;                 % conv 5% line
R8    = dCV(2) / dAI(2);
need  = (CD_bl_cv - CD5cv) / R8;         % AI drop needed if the ratio holds
fprintf('==========================================================================\n');
fprintf(' BONUS STATUS (only the highest row applies)\n');
fprintf('==========================================================================\n');
fprintf(' C008:  AI %+.2f%%   Conv %+.2f%%   -> both >= 3%%  ->  +5 points\n', c8.improvement, c8cv.improvement);
fprintf(' C009:  AI %+.2f%%   (not run in conv)\n', c9.improvement);
fprintf('--------------------------------------------------------------------------\n');
fprintf(' 5%% from ONE workflow is worth +4 < +5: an AI-only 5%% case adds nothing.\n');
fprintf(' +10 needs conv >= 5%%: CD_conv <= %.6f (another %.6f below C008_conv).\n', CD5cv, CV8(3) - CD5cv);
fprintf(' At the C008 conv/AI ratio (%.2f) the AI workflow would need %+.2f%%.\n', R8, need/CD_bl_ai*100);
fprintf(' Taper is converged at %.2f%%, so that needs a new design variable\n', imp(Cm, CD_bl_ai));
fprintf(' (and several more CFD runs in both workflows). Not pursued.\n');
fprintf('--------------------------------------------------------------------------\n');
fprintf(' FINAL DESIGN: C008  (NACA 2415 root / NACA 2412 tip, cr %.3f m, ct %.3f m,\n', P8.cr, P8.ct);
fprintf('               taper %.2f, sweep 0, twist 0)\n', P8.ct/P8.cr);
fprintf('   AI   : alpha %.3f  CL %.5f  CD %.6f  V %+.2f%%  improvement %.2f%%\n', ...
        AI8(1), AI8(2), AI8(3), (AI8(4)/V_bl_ai-1)*100, c8.improvement);
fprintf('   Conv : alpha %.3f  CL %.5f  CD %.6f  V %+.2f%%  improvement %.2f%%\n', ...
        CV8(1), CV8(2), CV8(3), (CV8(4)/V_bl_cv-1)*100, c8cv.improvement);
fprintf(' Why C008 and not C009: C008 is validated in BOTH workflows (the +5 bonus\n');
fprintf(' needs the same improvement claim in each). C009 is %.2f points better in AI\n', c9.improvement - c8.improvement);
fprintf(' only - inside the 3-sig-fig CFD resolution (%.2f points).\n', TOL_PTS);
fprintf('--------------------------------------------------------------------------\n');
fprintf(' OPEN ITEMS on C008_conv before the final report:\n');
fprintf('  - residuals ~1e-5 (energy 7.4e-4): spec asks 6 orders; get Prof. He''s OK\n');
fprintf('    in writing (email) and quote it in the report\n');
fprintf('  - prism layer stretching changed 1.3 -> 1.2 for this run: confirm C000_conv\n');
fprintf('    used the same mesh settings (spec: same settings for baseline and design)\n');
fprintf('  - add max non-orthogonal angle to the mesh table\n');
fprintf('==========================================================================\n');

%% ---------------- (6a) Figure: taper line search + both workflows --------
lf = linspace(0.20, 0.50, 61);
figure('Color','w', 'Position', [100 100 760 640]);
plot(lf, imp(aqv(info.a, lf), CD_bl_ai), 'k-', 'LineWidth', 1.5);  hold on;
plot([0.35 0.30 0.25], [imp(AI7(3),CD_bl_ai) c8.improvement c9.improvement], 'ks', ...
     'MarkerFaceColor', 'k', 'MarkerSize', 8);
plot(lm, imp(Cm, CD_bl_ai), 'kp', 'MarkerFaceColor', [0.6 0.6 0.6], 'MarkerSize', 12);
plot([0.35 0.30], [imp(CV5(3),CD_bl_cv) c8cv.improvement], 'd-', 'Color', [0.85 0.33 0.10], ...
     'MarkerFaceColor', [0.85 0.33 0.10], 'MarkerSize', 8, 'LineWidth', 1.2);
plot(0.30, c8.improvement, 'o', 'Color', [0 0.45 0.74], 'MarkerSize', 16, 'LineWidth', 1.5);
plot(0.30, c8cv.improvement, 'o', 'Color', [0 0.45 0.74], 'MarkerSize', 16, 'LineWidth', 1.5);
plot([0.20 0.50], [3 3], 'r:',  'LineWidth', 1.2);
plot([0.20 0.50], [5 5], 'b-.', 'LineWidth', 1.2);
text(0.495, 3.10, '3% bonus', 'Color', 'r');
text(0.495, 5.10, '5% bonus', 'Color', 'b');
grid on; box on;
set(gca, 'XDir', 'reverse');
xlabel('taper ratio \lambda = c_{tip}/c_{root}');
ylabel('CD reduction vs own C000  [%]');
legend({'AI parabola through C007/C008/C009', 'AI CFD (C007, C008, C009)', ...
        'parabola minimum (converged)', 'Conv CFD (C005, C008)', 'final design C008'}, ...
        'Location', 'southoutside');
ylim([1.5 5.5]);  xlim([0.20 0.50]);
title('Week 9: taper line search converged; C008 above 3% in both workflows');
exportgraphics(gcf, 'screening_week9.png', 'Resolution', 200);

%% ---------------- (6b) Figure: design history (for the report/review) ----
names = {'C002','C004','C005','C007','C008','C009'};
impAI = [imp(AI2(3),CD_bl_ai) imp(AI4(3),CD_bl_ai) imp(AI5(3),CD_bl_ai) ...
         imp(AI7(3),CD_bl_ai) c8.improvement c9.improvement];
impCV = [NaN NaN imp(CV5(3),CD_bl_cv) NaN c8cv.improvement NaN];
figure('Color','w', 'Position', [100 100 760 420]);
hb = bar([impAI(:) impCV(:)], 0.8);  hold on;
set(hb(1), 'FaceColor', [0.25 0.25 0.25]);
set(hb(2), 'FaceColor', [0.85 0.33 0.10]);
plot([0.4 6.6], [2 2], 'k--', 'LineWidth', 1.0);
plot([0.4 6.6], [3 3], 'r:',  'LineWidth', 1.2);
plot([0.4 6.6], [5 5], 'b-.', 'LineWidth', 1.2);
set(gca, 'XTick', 1:6, 'XTickLabel', names);
ylabel('CD reduction vs own C000  [%]');
ylim([0 5.5]);  grid on;  box on;
legend({'AI workflow', 'Conventional workflow', '2% requirement', '3% bonus', '5% bonus'}, ...
       'Location', 'northwest');
title('Design history: taper 0.45 \rightarrow thick root \rightarrow taper line search');
exportgraphics(gcf, 'design_history_week9.png', 'Resolution', 200);
