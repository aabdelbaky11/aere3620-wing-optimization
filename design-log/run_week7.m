% run_week7.m
% AerE 3620 Project - Design Lead, Week 7 (report week ending 10/30)
% New CFD in: C004_ai_v2 (fixed viscosity) and C005_ai (taper 0.35).
% C000_conv confirmed (V = 0.24688 m^3, Prof. He accepted the convergence).
% This script:
%   (1) checks C004_ai_v2, C005_ai and C000_conv against Table 1
%   (2) compares the week-6 screening prediction with the new CFD
%   (3) recalibrates llScreen on the three fixed-viscosity AI points and
%       finds WHERE the model misses (induced vs profile drag)
%   (4) re-predicts the re-sized taper family (+1% volume) with the
%       corrected model -> C007 (lambda 0.35) and C008 (lambda 0.30)
%   (5) sets up the CFD line search on taper for the re-sized family
%   (6) issues C005 to the conventional workflow: prediction + start alpha
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
CV0   = [   5.840,    0.4006155, 0.0206204,  0.24688  ];  % C000_conv (SOLIDWORKS volume, confirmed 10/23)

% planforms (NACA 2415 root / 2412 tip family)
P0 = struct('p_root','NACA 0012','p_tip','NACA 0012','cr',1.000,'ct',1.000,'twist_tip',0);
P4 = struct('p_root','NACA 2415','p_tip','NACA 2412','cr',1.266,'ct',0.570,'twist_tip',0);
P5 = struct('p_root','NACA 2415','p_tip','NACA 2412','cr',1.337,'ct',0.468,'twist_tip',0);

V_bl_ai = AI0(4);   CD_bl_ai = AI0(3);
V_bl_cv = CV0(4);   CD_bl_cv = CV0(3);

imp = @(CD, CDbl) (CDbl - CD) / CDbl * 100;

%% ---------------- (1) constraint checks ----------------------------------
d = struct('name','C004_ai_v2','cr',P4.cr,'ct',P4.ct,'tc_root',0.15,'tc_tip',0.12, ...
           'sweep',0,'twist_tip',0,'alpha',AI4(1),'CL',AI4(2),'CD',AI4(3),'V',AI4(4));
c4 = checkDesign(d, V_bl_ai, CD_bl_ai);

d.name = 'C005_ai';  d.cr = P5.cr;  d.ct = P5.ct;
d.alpha = AI5(1);  d.CL = AI5(2);  d.CD = AI5(3);  d.V = AI5(4);
c5 = checkDesign(d, V_bl_ai, CD_bl_ai);

d = struct('name','C000_conv','cr',1,'ct',1,'tc_root',0.12,'tc_tip',0.12, ...
           'sweep',0,'twist_tip',0,'alpha',CV0(1),'CL',CV0(2),'CD',CV0(3),'V',CV0(4));
checkDesign(d, V_bl_cv, CD_bl_cv);

%% ---------------- (2) week-6 prediction vs CFD ---------------------------
% Week 6 calibrated llScreen with ONE profile-drag factor, f_ai = 1.3270,
% on C000_v2 / C002 / C004 and predicted the taper line search with it.
F_WK6 = 1.3270;
CD0at = @(p) getfield(llScreen(p, RE_FIX), 'CD0');
CDiat = @(p) getfield(llScreen(p, RE_FIX), 'CDi');
model = @(p, f, CL) CDiat(p)*(CL/0.4)^2 + f*CD0at(p);
CDbl_m6 = model(P0, F_WK6, 0.4005);

fprintf('==========================================================================\n');
fprintf(' WEEK-6 PREDICTION vs CFD  (AI workflow, CD_bl = %.6f)\n', CD_bl_ai);
fprintf('==========================================================================\n');
fprintf(' %-10s %7s %10s %10s %9s\n', 'case', 'lambda', 'predicted', 'CFD', 'miss');
pr4 = imp(model(P4, F_WK6, 0.4005), CDbl_m6);
pr5 = imp(model(P5, F_WK6, 0.4005), CDbl_m6);
fprintf(' %-10s %7.2f %+9.2f%% %+9.2f%% %+8.2f\n', 'C004_ai_v2', 0.45, pr4, c4.improvement, c4.improvement - pr4);
fprintf(' %-10s %7.2f %+9.2f%% %+9.2f%% %+8.2f\n', 'C005_ai',    0.35, pr5, c5.improvement, c5.improvement - pr5);
fprintf('--------------------------------------------------------------------------\n');
fprintf(' taper 0.45 -> 0.35 gain:  predicted %.2f points, CFD %.2f points\n\n', ...
        pr5 - pr4, c5.improvement - c4.improvement);

%% ---------------- (3) recalibration: where does the model miss? ----------
% f = (CD_cfd - CDi_LL) / CD0_LL for each fixed-viscosity AI case.
% If f stays constant the model's profile-drag trend is right.
rows = {AI0, AI4, AI5};  Pl = {P0, P4, P5};  nm = {'C000_v2','C004_v2','C005'};
lamk = [1.00 0.45 0.35];
fk = zeros(1,3);  CDik = fk;  CD0k = fk;  ek = fk;  Sk = fk;
fprintf('==========================================================================\n');
fprintf(' llScreen CALIBRATION, fixed-viscosity AI points  (CD = CDi_LL + f*CD0_LL)\n');
fprintf('==========================================================================\n');
fprintf(' %-8s %7s %7s %9s %9s %9s %8s\n', 'case', 'lambda', 'S[m2]', 'CDi_LL', 'CD0_LL', 'CD_cfd', 'f');
for k = 1:3
    r = llScreen(Pl{k}, RE_FIX);
    CDik(k) = r.CDi * (rows{k}(2)/0.4)^2;
    CD0k(k) = r.CD0;  ek(k) = r.e;  Sk(k) = r.S;
    fk(k)   = (rows{k}(3) - CDik(k)) / CD0k(k);
    fprintf(' %-8s %7.2f %7.4f %9.6f %9.6f %9.6f %8.4f\n', nm{k}, lamk(k), Sk(k), CDik(k), CD0k(k), rows{k}(3), fk(k));
end
fprintf('--------------------------------------------------------------------------\n');
fprintf(' C000 -> C004: f changes %+.2f%%  (thick root + smaller chords: model is right)\n', (fk(2)/fk(1)-1)*100);
fprintf(' C004 -> C005: f changes %+.2f%%  (lower taper: profile drag per unit\n', (fk(3)/fk(2)-1)*100);
fprintf('               planform area RISES - the area saving is only partly real)\n');
fprintf(' span efficiency e: %.4f -> %.4f, so the induced-drag side barely moves\n\n', ek(2), ek(3));

% Corrected model: f varies linearly with taper, through the two CFD points
% on the NACA 2415/2412 family. Pure chord scaling at fixed taper keeps f.
f_lam = @(lam) fk(2) + (fk(3) - fk(2)) * (0.45 - lam) / 0.10;

% Conventional workflow: same taper trend, scaled to its own baseline
f_cv0 = (CV0(3) - CDiat(P0)*(CV0(2)/0.4)^2) / CD0at(P0);
f_cv  = @(lam) f_cv0 * f_lam(lam) / fk(1);

CDbl_ai_m = model(P0, fk(1), 0.4005);
CDbl_cv_m = model(P0, f_cv0, 0.4005);

%% ---------------- (4) re-sized taper family, corrected model -------------
% Same sizing rule as week 6: BOTH workflows clear V_bl by at least +1%
%   AI:   vspVolume  >= 1.01 V_bl_ai  (tool reads 1.94% above vspVolume on
%                                      C004 and C005, so the tool shows ~+3%)
%   Conv: wingVolume >= 1.01 V_bl_cv
MARGIN = 1.01;
K_TOOL = mean([AI4(4)/vspVolume(P4.cr, P4.ct, 'NACA 2415', 'NACA 2412'), ...
               AI5(4)/vspVolume(P5.cr, P5.ct, 'NACA 2415', 'NACA 2412')]);
lam = [0.45 0.40 0.35 0.30 0.25];
nL  = numel(lam);
T   = zeros(nL, 8);     % [cr ct V_ai V_cv impAI impCV a0AI a0CV]

% starting alpha: anchor on C005's CFD alpha, move with lifting-line alpha
LL0  = llScreen(P0, RE_FIX);
LL5  = llScreen(P5, RE_FIX);
k_ai = AI0(1) / LL0.alpha;                  % CFD/LL alpha ratio, symmetric baseline
k_cv = CV0(1) / LL0.alpha;
P5s  = P5;  P5s.p_root = 'NACA 0012';  P5s.p_tip = 'NACA 0012';
rs5  = llScreen(P5s, RE_FIX);
aZL  = AI5(1) - rs5.alpha*k_ai;             % zero-lift shift of the 2415/2412 airfoils, from CFD
a5cv = aZL + rs5.alpha*k_cv;                % Conv starting alpha for C005 itself

for j = 1:nL
    fa = @(c) vspVolume(c, lam(j)*c, 'NACA 2415', 'NACA 2412') - MARGIN*V_bl_ai;
    fc = @(c) wingVolume(c, lam(j)*c, 0.15, 0.12, 3.00)       - MARGIN*V_bl_cv;
    cr = max(fzero(fa, [0.5 3.0]), fzero(fc, [0.5 3.0]));
    p  = P5;  p.cr = cr;  p.ct = lam(j)*cr;
    r  = llScreen(p, RE_FIX);
    T(j,:) = [cr, p.ct, ...
              (K_TOOL*vspVolume(cr, p.ct, 'NACA 2415', 'NACA 2412')/V_bl_ai - 1)*100, ...
              (wingVolume(cr, p.ct, 0.15, 0.12, 3.00)/V_bl_cv - 1)*100, ...
              imp(model(p, f_lam(lam(j)), 0.4005), CDbl_ai_m), ...
              imp(model(p, f_cv(lam(j)),  0.4005), CDbl_cv_m), ...
              AI5(1) + (r.alpha - LL5.alpha)*k_ai, a5cv + (r.alpha - LL5.alpha)*k_cv];
end

fprintf('==========================================================================================\n');
fprintf(' RE-SIZED TAPER FAMILY, CORRECTED MODEL  (NACA 2415/2412, both workflows >= +1%% volume)\n');
fprintf('==========================================================================================\n');
fprintf(' %6s %7s %7s %8s %8s %7s %7s %7s %7s\n', 'lambda', 'cr[m]', 'ct[m]', 'V_AItool', 'V_Conv', ...
        'imp AI', 'imp Cv', 'a0 AI', 'a0 Cv');
fprintf('------------------------------------------------------------------------------------------\n');
for j = 1:nL
    tag = '';
    if abs(lam(j) - 0.35) < 1e-9, tag = '  <- C007'; end
    if abs(lam(j) - 0.30) < 1e-9, tag = '  <- C008'; end
    fprintf(' %6.2f %7.3f %7.3f %+7.2f%% %+7.2f%% %+6.2f%% %+6.2f%% %7.2f %7.2f%s\n', lam(j), T(j,1:8), tag);
end
fprintf('------------------------------------------------------------------------------------------\n');
fprintf(' V_AItool = vspVolume x %.4f (tool/vspVolume ratio measured on C004_v2 and C005)\n', K_TOOL);
fprintf(' imp      = predicted CD reduction vs own C000 (f varies with taper, from CFD)\n');
fprintf(' a0       = starting alpha [deg]\n');
fprintf(' lambda < 0.30 is an EXTRAPOLATION of f - treat as a guide only\n\n');

%% ---------------- (5) line search along taper (re-sized family) ----------
% CFD points move onto the re-sized family with the model's chord-scaling
% effect (f fixed at that taper). C004 confirmed the scaling side of the
% model to within 0.03 points, so this shift is the trusted part.
shiftTo = @(Pas, lamj, jT) ...
    model(setfield(setfield(Pas,'cr',T(jT,1)),'ct',T(jT,2)), f_lam(lamj), 0.4005) ...
  - model(Pas, f_lam(lamj), 0.4005);
CD45 = AI4(3) + shiftTo(P4, 0.45, 1);      % C004_v2 moved to lambda 0.45 re-sized
CD35 = AI5(3) + shiftTo(P5, 0.35, 3);      % C005    moved to lambda 0.35 re-sized

fprintf('==========================================================================\n');
fprintf(' QUADRATIC LINE SEARCH ON TAPER  (AI workflow, re-sized family)\n');
fprintf('==========================================================================\n');
fprintf(' lambda 0.45 : C004_v2 moved to re-sized chords   CD %.6f  (%+.2f%%)\n', CD45, imp(CD45, CD_bl_ai));
fprintf(' lambda 0.35 : C005    moved to re-sized chords   CD %.6f  (%+.2f%%)  -> C007 checks this\n', CD35, imp(CD35, CD_bl_ai));

% ---- CFD: fill these in when C007 / C008 return ----
CD_C007 = NaN;     % lambda = 0.35 re-sized (cr 1.313 / ct 0.460)
CD_C008 = NaN;     % lambda = 0.30 re-sized (cr 1.348 / ct 0.404)

if isnan(CD_C008)
    CD30m = CD_bl_ai * (1 - T(4,5)/100);
    [lm, Cm, info] = lineSearchQuad([0.45 0.35 0.30], [CD45 CD35 CD30m], 0.20/1.4, 1.0);
    fprintf(' lambda 0.30 : model only (C008 pending)         CD %.6f  (%+.2f%%)\n', CD30m, imp(CD30m, CD_bl_ai));
    if info.bracketed
        fprintf(' preview     : minimum bracketed, lambda* = %.3f  (%+.2f%%)\n', lm, imp(Cm, CD_bl_ai));
    else
        fprintf(' preview     : NOT bracketed - drag still falling at lambda 0.30\n');
        fprintf('               (gains shrink each step: %.2f then %.2f points)\n', ...
                imp(CD35,CD_bl_ai)-imp(CD45,CD_bl_ai), imp(CD30m,CD_bl_ai)-imp(CD35,CD_bl_ai));
    end
else
    CDa = CD35;  if ~isnan(CD_C007), CDa = CD_C007; end
    [lc, Cc, ic] = lineSearchQuad([0.45 0.35 0.30], [CD45 CDa CD_C008], 0.20/1.4, 1.0);
    if ic.bracketed
        fprintf(' CFD         : minimum bracketed, lambda* = %.3f  (predicted %+.2f%%)\n', lc, imp(Cc, CD_bl_ai));
    else
        fprintf(' CFD         : NOT bracketed - expand the search\n');
    end
    if isnan(ic.next)
        fprintf('               minimum is at a tested point - line search done\n');
    else
        fprintf('               next CFD run: lambda = %.3f\n', ic.next);
    end
end
fprintf('==========================================================================\n\n');

%% ---------------- (6) C005 to the conventional workflow ------------------
CD5cv = model(P5, f_cv(0.35), 0.4005);
fprintf('==========================================================================\n');
fprintf(' C005 FOR THE CONVENTIONAL WORKFLOW  (same geometry the AI workflow ran)\n');
fprintf('==========================================================================\n');
fprintf(' volume (wingVolume, straight loft) %.6f m^3  -> %+.2f%% over V_bl(conv)\n', ...
        wingVolume(P5.cr, P5.ct, 0.15, 0.12, 3.00), (wingVolume(P5.cr, P5.ct, 0.15, 0.12, 3.00)/V_bl_cv - 1)*100);
fprintf(' predicted CD %.6f  -> %+.2f%% vs CD_bl(conv) = %.6f\n', CD5cv, imp(CD5cv, CDbl_cv_m), CD_bl_cv);
fprintf(' same absolute drop as AI CFD would give %+.2f%%\n', imp(CD_bl_cv - (CD_bl_ai - AI5(3)), CD_bl_cv));
fprintf(' starting alpha: %.2f deg, then %.2f deg, then trimAlpha\n', a5cv, a5cv + 1);
fprintf('==========================================================================\n');

%% ---------------- Plot ---------------------------------------------------
lf = linspace(0.25, 0.50, 51);
ia = zeros(size(lf));  ic6 = ia;  icv = ia;
for j = 1:numel(lf)
    fa = @(c) vspVolume(c, lf(j)*c, 'NACA 2415', 'NACA 2412') - MARGIN*V_bl_ai;
    fc = @(c) wingVolume(c, lf(j)*c, 0.15, 0.12, 3.00)       - MARGIN*V_bl_cv;
    cr = max(fzero(fa, [0.5 3.0]), fzero(fc, [0.5 3.0]));
    p  = P5;  p.cr = cr;  p.ct = lf(j)*cr;
    ia(j)  = imp(model(p, f_lam(lf(j)), 0.4005), CDbl_ai_m);
    icv(j) = imp(model(p, f_cv(lf(j)),  0.4005), CDbl_cv_m);
    ic6(j) = imp(model(p, F_WK6, 0.4005), CDbl_m6);
end

figure('Color','w');
plot(lf, ia,  'k-',  'LineWidth', 1.5);  hold on;
plot(lf, icv, 'k--', 'LineWidth', 1.2);
plot(lf, ic6, ':', 'Color', [0.55 0.55 0.55], 'LineWidth', 1.2);
plot([0.45 0.35], [c4.improvement c5.improvement], 'ks', 'MarkerFaceColor', 'k', 'MarkerSize', 7);
plot([0.45 0.35], [imp(CD45,CD_bl_ai) imp(CD35,CD_bl_ai)], 'ko', 'MarkerSize', 7);
plot([0.25 0.50], [3 3], 'r:',  'LineWidth', 1.2);
plot([0.25 0.50], [5 5], 'b-.', 'LineWidth', 1.2);
text(0.495, 3.08, '3% bonus', 'Color', 'r', 'HorizontalAlignment', 'left');
text(0.495, 5.08, '5% bonus', 'Color', 'b', 'HorizontalAlignment', 'left');
grid on; box on;
set(gca, 'XDir', 'reverse');
xlabel('taper ratio \lambda = c_{tip}/c_{root}');
ylabel('CD reduction vs own C000  [%]');
legend({'AI, re-sized (+1% volume), corrected model', 'Conv, re-sized, corrected model', ...
        'week-6 model (constant f)', 'AI CFD as run (C004\_v2, C005)', ...
        'AI CFD moved to re-sized chords'}, 'Location', 'northwest');
ylim([2.8 6.5]);  xlim([0.25 0.50]);
title('Week 7: taper line search, NACA 2415/2412 family');

exportgraphics(gcf, 'screening_week7.png', 'Resolution', 200);
