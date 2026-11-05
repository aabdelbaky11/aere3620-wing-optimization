% run_week8.m
% AerE 3620 Project - Design Lead, Week 8 (report week ending 11/6)
% New CFD in: C007_ai (taper 0.35 re-sized), C008_ai (taper 0.30 re-sized)
%             and C005_conv (first conventional design case).
% This script:
%   (1) checks C007_ai, C008_ai and C005_conv against Table 1
%   (2) compares the week-7 predictions with the new CFD
%   (3) recalibrates llScreen on all five fixed-viscosity AI points and
%       measures how well the model's chord-scaling (volume) lever held up
%   (4) runs the quadratic line search on taper with three CFD-based
%       points on the re-sized family -> next AI case (C009)
%   (5) compares the two workflows on the identical C005 wing
%   (6) issues C008 to the conventional workflow: prediction + start alpha
%
% Requires: llScreen.m, checkDesign.m, wingVolume.m, vspVolume.m,
%           lineSearchQuad.m

clear; clc; close all;

%% ---------------- CFD results on file -----------------------------------
% All CL/CD on A_ref = 3.00 m^2, Re_cref = 5.0e6 (fixed viscosity).
RE_FIX = 5.0e6;

%           alpha     CL         CD          V_tool
AI0   = [   5.41482,  0.400507,  0.020052,   0.246898 ];  % C000_ai_v2
AI4   = [   3.88906,  0.40053,   0.019308,   0.262578 ];  % C004_ai_v2
AI5   = [   4.03904,  0.40045,   0.019234,   0.263592 ];  % C005_ai
AI7   = [   4.10938,  0.40052,   0.019117,   0.254287 ];  % C007_ai  (new)
AI8   = [   4.21572,  0.40051,   0.019087,   0.254221 ];  % C008_ai  (new)
CV0   = [   5.840,    0.4006155, 0.0206204,  0.24688  ];  % C000_conv
CV5   = [   4.970,    0.4000489, 0.0201390,  0.25948  ];  % C005_conv (new, SOLIDWORKS volume)

% planforms (NACA 2415 root / 2412 tip family)
P0 = struct('p_root','NACA 0012','p_tip','NACA 0012','cr',1.000,'ct',1.000,'twist_tip',0);
P4 = struct('p_root','NACA 2415','p_tip','NACA 2412','cr',1.266,'ct',0.570,'twist_tip',0);
P5 = struct('p_root','NACA 2415','p_tip','NACA 2412','cr',1.337,'ct',0.468,'twist_tip',0);
P7 = P5;  P7.cr = 1.313;  P7.ct = 0.460;
P8 = P5;  P8.cr = 1.348;  P8.ct = 0.404;

V_bl_ai = AI0(4);   CD_bl_ai = AI0(3);
V_bl_cv = CV0(4);   CD_bl_cv = CV0(3);

imp = @(CD, CDbl) (CDbl - CD) / CDbl * 100;

%% ---------------- (1) constraint checks ----------------------------------
d = struct('name','C007_ai','cr',P7.cr,'ct',P7.ct,'tc_root',0.15,'tc_tip',0.12, ...
           'sweep',0,'twist_tip',0,'alpha',AI7(1),'CL',AI7(2),'CD',AI7(3),'V',AI7(4));
c7 = checkDesign(d, V_bl_ai, CD_bl_ai);

d.name = 'C008_ai';  d.cr = P8.cr;  d.ct = P8.ct;
d.alpha = AI8(1);  d.CL = AI8(2);  d.CD = AI8(3);  d.V = AI8(4);
c8 = checkDesign(d, V_bl_ai, CD_bl_ai);

d.name = 'C005_conv';  d.cr = P5.cr;  d.ct = P5.ct;
d.alpha = CV5(1);  d.CL = CV5(2);  d.CD = CV5(3);  d.V = CV5(4);
c5cv = checkDesign(d, V_bl_cv, CD_bl_cv);

% SOLIDWORKS volume vs the straight-loft formula the request was sized with
Vw5 = wingVolume(P5.cr, P5.ct, 0.15, 0.12, 3.00);
fprintf(' C005_conv volume: SOLIDWORKS %.5f vs wingVolume %.5f m^3 (%+.3f%%)\n\n', ...
        CV5(4), Vw5, (CV5(4)/Vw5 - 1)*100);

%% ---------------- (2) week-7 predictions vs CFD --------------------------
% Numbers printed by run_week7.m and written into the requests.
fprintf('==========================================================================\n');
fprintf(' WEEK-7 PREDICTIONS vs CFD\n');
fprintf('==========================================================================\n');
fprintf(' %-10s %7s %10s %10s %9s\n', 'case', 'lambda', 'predicted', 'CFD', 'miss');
pr = [4.85 5.09 4.08];
cf = [c7.improvement c8.improvement c5cv.improvement];
nm = {'C007_ai','C008_ai','C005_conv'};  la = [0.35 0.30 0.35];
for k = 1:3
    fprintf(' %-10s %7.2f %+9.2f%% %+9.2f%% %+8.2f\n', nm{k}, la(k), pr(k), cf(k), cf(k) - pr(k));
end
fprintf('--------------------------------------------------------------------------\n');
fprintf(' AI misses are small and one-sided (model ~0.2-0.3 points optimistic).\n');
fprintf(' The conventional miss is 1.75 points - see section (5).\n\n');

%% ---------------- (3) recalibration on all fixed-viscosity AI points -----
rows = {AI0, AI4, AI5, AI7, AI8};  Pl = {P0, P4, P5, P7, P8};
nmk  = {'C000_v2','C004_v2','C005','C007','C008'};
lamk = [1.00 0.45 0.35 0.35 0.30];
n = numel(rows);
fk = zeros(1,n);  CDik = fk;  CD0k = fk;  Sk = fk;
fprintf('==========================================================================\n');
fprintf(' llScreen CALIBRATION, fixed-viscosity AI points  (CD = CDi_LL + f*CD0_LL)\n');
fprintf('==========================================================================\n');
fprintf(' %-8s %7s %7s %9s %9s %9s %8s\n', 'case', 'lambda', 'S[m2]', 'CDi_LL', 'CD0_LL', 'CD_cfd', 'f');
for k = 1:n
    r = llScreen(Pl{k}, RE_FIX);
    CDik(k) = r.CDi * (rows{k}(2)/0.4)^2;
    CD0k(k) = r.CD0;  Sk(k) = r.S;
    fk(k)   = (rows{k}(3) - CDik(k)) / CD0k(k);
    fprintf(' %-8s %7.2f %7.4f %9.6f %9.6f %9.6f %8.4f\n', nmk{k}, lamk(k), Sk(k), CDik(k), CD0k(k), rows{k}(3), fk(k));
end
fprintf('--------------------------------------------------------------------------\n');

% Chord-scaling (volume) lever: C005 -> C007 is the same planform shape,
% 1.8% smaller chords. Week 7 assumed f stays fixed when only size changes.
model = @(p, f, CL) getfield(llScreen(p, RE_FIX), 'CDi')*(CL/0.4)^2 + f*getfield(llScreen(p, RE_FIX), 'CD0');
dCD_model = model(P7, fk(3), 0.4005) - model(P5, fk(3), 0.4005);
dCD_cfd   = AI7(3) - AI5(3);
K_SCALE   = dCD_cfd / dCD_model;
fprintf(' C005 -> C007 (shrink only): model dCD %+.6f, CFD dCD %+.6f\n', dCD_model, dCD_cfd);
fprintf('   -> the volume lever delivers %.0f%% of what the model says (K_SCALE = %.3f)\n', K_SCALE*100, K_SCALE);
fprintf('   -> f at taper 0.35 rose %+.2f%% when the wing shrank\n', (fk(4)/fk(3) - 1)*100);
fprintf(' C007 -> C008 (taper only, same volume): f changes %+.2f%%\n\n', (fk(5)/fk(4) - 1)*100);

% Updated f(lambda) for the re-sized family: linear through C007 and C008
f_rs = @(lam) fk(4) + (fk(5) - fk(4)) * (0.35 - lam) / 0.05;

%% ---------------- (4) line search on taper, re-sized family ---------------
% Three points at ~+3% tool volume:
%   0.45 : C004_v2 moved to re-sized chords (cr 1.246 / ct 0.561), using the
%          model's chord-scaling shift corrected by K_SCALE measured above
%   0.35 : C007 CFD
%   0.30 : C008 CFD
P4r = P4;  P4r.cr = 1.246;  P4r.ct = 0.561;
CD45 = AI4(3) + K_SCALE * (model(P4r, fk(2), 0.4005) - model(P4, fk(2), 0.4005));

lamLS = [0.45 0.35 0.30];
CDLS  = [CD45 AI7(3) AI8(3)];
XLO   = 0.20/1.40;      % tip chord >= 0.2 m at cr ~ 1.40 m
[lm, Cm, info] = lineSearchQuad(lamLS, CDLS, XLO, 1.0);
aqv = @(a, x) a(1) + a(2)*x + a(3)*x.^2;     % parabola value

fprintf('==========================================================================\n');
fprintf(' QUADRATIC LINE SEARCH ON TAPER  (AI workflow, re-sized family, ~+3%% volume)\n');
fprintf('==========================================================================\n');
fprintf(' lambda 0.45 : C004_v2 moved to re-sized chords  CD %.6f  (%+.2f%%)\n', CD45, imp(CD45, CD_bl_ai));
fprintf(' lambda 0.35 : C007 CFD                          CD %.6f  (%+.2f%%)\n', AI7(3), c7.improvement);
fprintf(' lambda 0.30 : C008 CFD                          CD %.6f  (%+.2f%%)\n', AI8(3), c8.improvement);
fprintf(' gains per step: 0.45->0.35 %.2f points, 0.35->0.30 %.2f points\n', ...
        c7.improvement - imp(CD45, CD_bl_ai), c8.improvement - c7.improvement);
fprintf('--------------------------------------------------------------------------\n');
fprintf(' parabola convex: %d   bracketed: %d\n', info.convex, info.bracketed);
fprintf(' parabola minimum: lambda* = %.3f   predicted CD %.6f  (%+.3f%%, extrapolated)\n', lm, Cm, imp(Cm, CD_bl_ai));

% Not bracketed: the parabola minimum is an EXTRAPOLATION well past the
% data, and a 3-point parabola this flat is unreliable that far out.
% Phase I (Lecture 11): expand, but limit the step to the last step size.
STEP  = lamLS(2) - lamLS(3);                 % 0.05
lam9  = max(lm, lamLS(3) - STEP);            % -> 0.25
fprintf(' minimum NOT bracketed and lambda* is %.2f past the last CFD point:\n', lamLS(3) - lm);
fprintf(' expand by one step only -> next trial lambda = %.2f\n', lam9);

% size it like C007/C008 (>= +1% volume in both workflows) and check with the
% model anchored on C008 (f extrapolated along the C007 -> C008 trend)
fa = @(c) vspVolume(c, lam9*c, 'NACA 2415', 'NACA 2412') - 1.01*V_bl_ai;
fc = @(c) wingVolume(c, lam9*c, 0.15, 0.12, 3.00)       - 1.01*V_bl_cv;
cr9 = max(fzero(fa, [0.5 3.0]), fzero(fc, [0.5 3.0]));
P9 = P5;  P9.cr = round(cr9*1000)/1000;  P9.ct = round(lam9*P9.cr*1000)/1000;
CD9m = AI8(3) + model(P9, f_rs(lam9), 0.4005) - model(P8, fk(5), 0.4005);
CD9q = aqv(info.a, lam9);
fprintf(' at lambda %.2f: parabola CD %.6f (%+.2f%%), model CD %.6f (%+.2f%%)\n', ...
        lam9, CD9q, imp(CD9q, CD_bl_ai), CD9m, imp(CD9m, CD_bl_ai));
fprintf(' expected gain over C008: %.2f to %.2f points -> 5%% is unlikely on taper\n', ...
        min(imp(CD9q,CD_bl_ai), imp(CD9m,CD_bl_ai)) - c8.improvement, ...
        max(imp(CD9q,CD_bl_ai), imp(CD9m,CD_bl_ai)) - c8.improvement);
fprintf(' alone. C009 brackets the minimum (or shows the trend has flattened).\n');
fprintf('--------------------------------------------------------------------------\n');
r9 = llScreen(P9, RE_FIX);  r8 = llScreen(P8, RE_FIX);
k_ai = AI0(1) / llScreen(P0, RE_FIX).alpha;
a9 = AI8(1) + (r9.alpha - r8.alpha) * k_ai;
fprintf(' C009: lambda %.2f   cr %.3f m   ct %.3f m\n', P9.ct/P9.cr, P9.cr, P9.ct);
fprintf('       V_AItool ~ %.4f m^3 (%+.2f%%)   V_conv %+.2f%%\n', ...
        1.0194*vspVolume(P9.cr, P9.ct, 'NACA 2415', 'NACA 2412'), ...
        (1.0194*vspVolume(P9.cr, P9.ct, 'NACA 2415', 'NACA 2412')/V_bl_ai - 1)*100, ...
        (wingVolume(P9.cr, P9.ct, 0.15, 0.12, 3.00)/V_bl_cv - 1)*100);
fprintf('       S = %.4f m^2   start alpha AI %.2f deg\n', r9.S, a9);
fprintf('==========================================================================\n\n');

%% ---------------- (5) workflow comparison on the identical C005 wing ------
dCD_ai = CD_bl_ai - AI5(3);
dCD_cv = CD_bl_cv - CV5(3);
R_CV   = dCD_cv / dCD_ai;
fprintf('==========================================================================\n');
fprintf(' WORKFLOW COMPARISON, C005 (identical geometry)\n');
fprintf('==========================================================================\n');
fprintf(' %-22s %12s %12s\n', '', 'AI', 'Conv');
fprintf(' %-22s %12.6f %12.6f\n', 'CD_bl (C000)', CD_bl_ai, CD_bl_cv);
fprintf(' %-22s %12.6f %12.6f\n', 'CD (C005)', AI5(3), CV5(3));
fprintf(' %-22s %12.6f %12.6f\n', 'drag drop dCD', dCD_ai, dCD_cv);
fprintf(' %-22s %+11.2f%% %+11.2f%%\n', 'improvement', imp(AI5(3),CD_bl_ai), c5cv.improvement);
fprintf(' %-22s %12.3f %12.3f\n', 'alpha C000 [deg]', AI0(1), CV0(1));
fprintf(' %-22s %12.3f %12.3f\n', 'alpha C005 [deg]', AI5(1), CV5(1));
fprintf(' %-22s %+12.3f %+12.3f\n', 'alpha shift [deg]', AI5(1)-AI0(1), CV5(1)-CV0(1));
fprintf('--------------------------------------------------------------------------\n');
fprintf(' Conv sees %.0f%% of the AI drag drop and %.0f%% of the AI alpha shift.\n', ...
        R_CV*100, (CV5(1)-CV0(1))/(AI5(1)-AI0(1))*100);
fprintf(' Volume matches the request to 0.02%%, so chords and thickness are right.\n');
fprintf(' The smaller alpha shift suggests the camber is doing less in the conv\n');
fprintf(' model. Possible causes: section shape in SOLIDWORKS (camber line, 2%% at\n');
fprintf(' 0.4c), or the coarser conv convergence. Ask Gabriel to confirm.\n');
fprintf(' Conv C005 also has max y+ 105 (spec 30-100) and ~4-5 order residual drop.\n');
fprintf('==========================================================================\n\n');

%% ---------------- (6) C008 to the conventional workflow ------------------
% Two ways to carry the AI result over to conventional CFD:
%   ratio     : conv gets R_CV of the AI drag drop (C005 behaviour holds)
%   increment : conv C005 drop + the AI's extra drop from C005 -> C008
dAI8   = CD_bl_ai - AI8(3);
CD8_r  = CD_bl_cv - R_CV * dAI8;
CD8_i  = CV5(3) - (AI5(3) - AI8(3));
a8cv   = AI8(1) + (CV5(1) - AI5(1));       % conv-AI alpha offset measured on C005
V8cv   = wingVolume(P8.cr, P8.ct, 0.15, 0.12, 3.00);
CD3pct = 0.97 * CD_bl_cv;

fprintf('==========================================================================\n');
fprintf(' C008 FOR THE CONVENTIONAL WORKFLOW  (same geometry the AI workflow ran)\n');
fprintf('==========================================================================\n');
fprintf(' volume (wingVolume, straight loft) %.6f m^3  -> %+.2f%% over V_bl(conv)\n', V8cv, (V8cv/V_bl_cv - 1)*100);
fprintf(' predicted CD, ratio method     %.6f  -> %+.2f%%\n', CD8_r, imp(CD8_r, CD_bl_cv));
fprintf(' predicted CD, increment method %.6f  -> %+.2f%%\n', CD8_i, imp(CD8_i, CD_bl_cv));
fprintf(' 3%% bonus line (both workflows):  CD <= %.6f\n', CD3pct);
fprintf(' starting alpha: %.2f deg, then %.2f deg, then trimAlpha\n', a8cv, a8cv + 0.5);
fprintf('--------------------------------------------------------------------------\n');
fprintf(' Bonus table: AI is at 4.81%% -> +3 now. Conv >= 3%% -> +5.\n');
fprintf(' AI >= 5%% would only give +4, so C008_conv is the priority run.\n');
fprintf('==========================================================================\n');

%% ---------------- Plot ---------------------------------------------------
lf = linspace(0.20, 0.50, 61);
aq = info.a;
figure('Color','w', 'Position', [100 100 760 720]);
plot(lf, imp(aqv(aq, lf), CD_bl_ai), 'k-', 'LineWidth', 1.5);  hold on;
plot([0.45 0.35 0.30], [imp(AI4(3),CD_bl_ai) imp(AI5(3),CD_bl_ai) NaN], 'ks', 'MarkerSize', 7);
plot([0.35 0.30], [c7.improvement c8.improvement], 'ks', 'MarkerFaceColor', 'k', 'MarkerSize', 8);
plot(0.45, imp(CD45, CD_bl_ai), 'ko', 'MarkerSize', 7);
plot(lam9, imp(CD9q, CD_bl_ai), 'kp', 'MarkerFaceColor', [0.6 0.6 0.6], 'MarkerSize', 11);
plot(0.35, c5cv.improvement, 'd', 'Color', [0.85 0.33 0.10], 'MarkerFaceColor', [0.85 0.33 0.10], 'MarkerSize', 8);
plot([0.30 0.30], [imp(CD8_r,CD_bl_cv) imp(CD8_i,CD_bl_cv)], '-', 'Color', [0.85 0.33 0.10], 'LineWidth', 3);
plot([0.20 0.50], [3 3], 'r:',  'LineWidth', 1.2);
plot([0.20 0.50], [5 5], 'b-.', 'LineWidth', 1.2);
text(0.205, 3.12, '3% bonus', 'Color', 'r', 'HorizontalAlignment', 'right');
text(0.205, 5.12, '5% bonus', 'Color', 'b', 'HorizontalAlignment', 'right');
grid on; box on;
set(gca, 'XDir', 'reverse');
xlabel('taper ratio \lambda = c_{tip}/c_{root}');
ylabel('CD reduction vs own C000  [%]');
legend({'AI parabola through re-sized points', 'AI CFD, oversized (C004\_v2, C005)', ...
        'AI CFD, re-sized (C007, C008)', 'C004\_v2 moved to re-sized chords', ...
        'next trial C009 (parabola)', 'Conv CFD (C005\_conv)', 'Conv C008 prediction range'}, ...
        'Location', 'southoutside');
ylim([1.5 5.5]);  xlim([0.20 0.50]);
title('Week 8: taper line search and workflow comparison');

exportgraphics(gcf, 'screening_week8.png', 'Resolution', 200);
