% run_week6.m
% AerE 3620 Project - Design Lead, Week 6
% New baselines are in (C000_ai_v2 at fixed viscosity, C000_conv re-run).
% This script:
%   (1) checks both new C000 baselines against Table 1
%   (2) audits the volume check against the AI tool's own volume_val
%   (3) corrects C002 and C004 (run at drifted viscosity) to Re = 5.0e6
%       and checks the correction on C000 v1 -> v2
%   (4) recalibrates llScreen on all three AI CFD points
%   (5) re-sizes the C004 airfoil family to a +1% volume margin and
%       predicts the taper line search for both workflows
%   (6) quadratic-interpolation line search along taper (fill in CFD
%       results for C005/C006 when they come back)
%
% Requires: llScreen.m, checkDesign.m, wingVolume.m, vspVolume.m,
%           lineSearchQuad.m

clear; clc; close all;

%% ---------------- CFD results on file -----------------------------------
% All CL/CD on A_ref = 3.00 m^2.  mu = viscosity actually used in the run.
MU_FIX = 2.451491e-5;    % C000_ai_v2 thermophysicalProperties -> Re_cref = 5.0e6
RE_FIX = 5.0e6;

%            alpha     CL         CD          V_tool     mu_used
AI0v1 = [    5.408,    0.400007,  0.020010,   0.246898,  2.430198e-5 ];  % C000_ai (old)
AI0   = [    5.41482,  0.400507,  0.020052,   0.246898,  MU_FIX      ];  % C000_ai_v2
AI2   = [    5.47641,  0.40053,   0.019715,   0.247873,  2.5126e-5   ];  % C002_ai
AI4   = [    3.88047,  0.40031,   0.019210,   0.262578,  2.3385e-5   ];  % C004_ai
CV0   = [    5.84,     0.4006155, 0.0206204,  0.24688,   2.448e-5    ];  % C000_conv
% C000_conv volume: Gabriel's summary says 2.4688 m^3 - assumed decimal
% slip for 0.24688 (OpenVSP 0.246898). CONFIRM WITH GABRIEL.

Re_used = @(row) RE_FIX * MU_FIX / row(5);    % Re on c_ref = 1.00 m
nacaTC  = @(code) str2double(code(end-1:end)) / 100;   % 'NACA 2415' -> 0.15

% planforms
P0 = struct('p_root','NACA 0012','p_tip','NACA 0012','cr',1.000,'ct',1.000,'twist_tip',0);
P2 = struct('p_root','NACA 0012','p_tip','NACA 0012','cr',1.361,'ct',0.612,'twist_tip',0);
P4 = struct('p_root','NACA 2415','p_tip','NACA 2412','cr',1.266,'ct',0.570,'twist_tip',0);

V_bl_ai = AI0(4);
V_bl_cv = CV0(4);

%% ---------------- (1) constraint check on the new baselines -------------
d = struct('name','C000_ai_v2','cr',1,'ct',1,'tc_root',0.12,'tc_tip',0.12, ...
           'sweep',0,'twist_tip',0,'alpha',AI0(1),'CL',AI0(2),'CD',AI0(3),'V',AI0(4));
checkDesign(d, V_bl_ai, AI0(3));
d.name = 'C000_conv';  d.alpha = CV0(1);  d.CL = CV0(2);  d.CD = CV0(3);  d.V = CV0(4);
checkDesign(d, V_bl_cv, CV0(3));

%% ---------------- (2) volume audit ---------------------------------------
fprintf('==========================================================================\n');
fprintf(' VOLUME AUDIT  [m^3]   (half wing)\n');
fprintf('==========================================================================\n');
fprintf(' %-6s %12s %12s %12s %12s %9s\n', 'case', 'old wingVol', 'wingVolume', 'vspVolume', 'AI tool', 'vsp err');
fprintf('--------------------------------------------------------------------------\n');
P   = {P0, P2, P4};   Vt = [AI0(4) AI2(4) AI4(4)];   nm = {'C000','C002','C004'};
for k = 1:3
    p = P{k};
    [tcr, tct] = deal(nacaTC(p.p_root), nacaTC(p.p_tip));
    eta  = linspace(0,1,2001);                        % pre-week-6 formula
    Vold = trapz(eta, 0.685*(tcr+(tct-tcr)*eta).*(p.cr+(p.ct-p.cr)*eta).^2) * 3;
    Vw   = wingVolume(p.cr, p.ct, tcr, tct, 3.00);
    Vv   = vspVolume(p.cr, p.ct, p.p_root, p.p_tip);
    fprintf(' %-6s %12.6f %12.6f %12.6f %12.6f %+8.2f%%\n', nm{k}, Vold, Vw, Vv, Vt(k), (Vv/Vt(k)-1)*100);
end
fprintf('--------------------------------------------------------------------------\n');
fprintf(' old wingVol = linear t/c (pre week 6); wingVolume = straight loft (CAD, Conv)\n');
fprintf(' vspVolume   = AI tool method (10 slices + round tip cap); reads LOW on C004\n\n');

% current C005 / C006 requests (sized with the old formula at +2%)
req = {'C005 (as issued)', 1.337, 0.468; 'C006 (as issued)', 1.374, 0.412};
for k = 1:2
    Vv = vspVolume(req{k,2}, req{k,3}, 'NACA 2415', 'NACA 2412');
    Vw = wingVolume(req{k,2}, req{k,3}, 0.15, 0.12, 3.00);
    fprintf(' %-17s AI-tool margin %+5.2f%% (at least)   Conv margin %+5.2f%%\n', ...
            req{k,1}, (Vv/V_bl_ai-1)*100, (Vw/V_bl_cv-1)*100);
end
fprintf(' -> both pass, but carry ~5%% more volume than needed (extra wetted area)\n\n');

%% ---------------- (3) fixed-viscosity correction -------------------------
% Profile drag follows the flat-plate Cf(Re) in llScreen, scaled by the
% calibration factor f; induced drag scales with CL^2:
%   CD(Re_fix) = CD(Re_used) + f*[CD0_LL(Re_fix) - CD0_LL(Re_used)]
LL0  = llScreen(P0, RE_FIX);
f_ai = (AI0(3) - LL0.CDi*(AI0(2)/0.4)^2) / LL0.CD0;

% check: predict C000 v2 from C000 v1
r1   = llScreen(P0, Re_used(AI0v1));
CDv2 = AI0v1(3) + f_ai*(LL0.CD0 - r1.CD0) + LL0.CDi*(AI0(2)^2 - AI0v1(2)^2)/0.4^2;

CD0at = @(p, Re) getfield(llScreen(p, Re), 'CD0');
CDiat = @(p, Re) getfield(llScreen(p, Re), 'CDi');
corr = @(row, p) row(3) + f_ai*(CD0at(p, RE_FIX) - CD0at(p, Re_used(row)));
CD2c = corr(AI2, P2);
CD4c = corr(AI4, P4);
imp  = @(CD, CDbl) (CDbl - CD) / CDbl * 100;

fprintf('==========================================================================\n');
fprintf(' FIXED-VISCOSITY CORRECTION  (AI workflow, CD_bl = %.6f)\n', AI0(3));
fprintf('==========================================================================\n');
fprintf(' check on C000:  v1 %.6f -> predicted v2 %.6f   actual v2 %.6f  (err %+.2f%%)\n', ...
        AI0v1(3), CDv2, AI0(3), (CDv2/AI0(3)-1)*100);
fprintf('--------------------------------------------------------------------------\n');
fprintf(' %-6s %10s %10s %10s %11s %11s\n', 'case', 'Re_cref', 'CD as run', 'CD @5.0e6', 'imp as run', 'imp @5.0e6');
fprintf(' %-6s %10.3g %10.6f %10.6f %+10.2f%% %+10.2f%%\n', 'C002', Re_used(AI2), AI2(3), CD2c, imp(AI2(3),AI0v1(3)), imp(CD2c,AI0(3)));
fprintf(' %-6s %10.3g %10.6f %10.6f %+10.2f%% %+10.2f%%\n', 'C004', Re_used(AI4), AI4(3), CD4c, imp(AI4(3),AI0v1(3)), imp(CD4c,AI0(3)));
fprintf('--------------------------------------------------------------------------\n');
fprintf(' "as run" = vs old C000 (how they were first reported). C004_ai_v2 replaces\n');
fprintf(' the C004 estimate when Kade returns it.\n\n');

%% ---------------- (4) llScreen recalibration ----------------------------
% f = (CD_cfd - CDi_LL) / CD0_LL, each case at the Re it actually ran.
% If lifting line + flat plate captured the trends, f is the same for all.
rows = {AI0, AI2, AI4};  Pl = {P0, P2, P4};  nm = {'C000_v2','C002','C004'};
fk = zeros(1,3);  CDik = fk;  CD0k = fk;
fprintf('==========================================================================\n');
fprintf(' llScreen CALIBRATION ON AI CFD   (CD_cfd = CDi_LL + f * CD0_LL)\n');
fprintf('==========================================================================\n');
fprintf(' %-8s %9s %9s %9s %8s\n', 'case', 'CDi_LL', 'CD0_LL', 'CD_cfd', 'f');
for k = 1:3
    r = llScreen(Pl{k}, Re_used(rows{k}));
    CDi = r.CDi * (rows{k}(2)/0.4)^2;
    fk(k) = (rows{k}(3) - CDi) / r.CD0;
    CDik(k) = CDi;  CD0k(k) = r.CD0;
    fprintf(' %-8s %9.6f %9.6f %9.6f %8.4f\n', nm{k}, CDi, r.CD0, rows{k}(3), fk(k));
end
f_ai = mean(fk);
fprintf('--------------------------------------------------------------------------\n');
errk = (CDik + f_ai*CD0k) ./ [AI0(3) AI2(3) AI4(3)] - 1;
fprintf(' f_ai = %.4f  (one f reproduces all three CFD CDs within %.2f%%)\n', ...
        f_ai, max(abs(errk))*100);

f_cv = (CV0(3) - LL0.CDi*(CV0(2)/0.4)^2) / LL0.CD0;
fprintf(' f_cv = %.4f  (from C000_conv only - no changed design yet)\n\n', f_cv);

model = @(p, f, CL) CDiat(p, RE_FIX)*(CL/0.4)^2 + f*CD0at(p, RE_FIX);
CDbl_ai_m = model(P0, f_ai, 0.4005);    % model baselines so model errors cancel
CDbl_cv_m = model(P0, f_cv, 0.4005);

%% ---------------- (5) re-sized taper family (NACA 2415 / 2412) -----------
% Size so BOTH workflows clear V_bl by at least +1%:
%   AI:   vspVolume >= 1.01 V_bl_ai   (vspVolume reads low -> true margin larger)
%   Conv: wingVolume >= 1.01 V_bl_cv
MARGIN = 1.01;
lam    = [0.45 0.40 0.35 0.30 0.25];
nL     = numel(lam);
T      = zeros(nL, 9);    % [cr ct V_ai V_cv impAI impCV a0AI a0CV e]

LL4  = llScreen(P4, RE_FIX);
k_ai = AI0(1) / LL0.alpha;                 % CFD/LL alpha ratio, symmetric baseline
k_cv = CV0(1) / LL0.alpha;
P4s  = P4;  P4s.p_root = 'NACA 0012';  P4s.p_tip = 'NACA 0012';
rs4  = llScreen(P4s, RE_FIX);
aZL  = AI4(1) - rs4.alpha*k_ai;            % zero-lift shift of the C004 airfoils, from CFD
a4cv = aZL + rs4.alpha*k_cv;               % Conv starting alpha for C004 itself

for j = 1:nL
    fa = @(c) vspVolume(c, lam(j)*c, 'NACA 2415', 'NACA 2412') - MARGIN*V_bl_ai;
    fc = @(c) wingVolume(c, lam(j)*c, 0.15, 0.12, 3.00)       - MARGIN*V_bl_cv;
    cr = max(fzero(fa, [0.5 3.0]), fzero(fc, [0.5 3.0]));
    p  = P4;  p.cr = cr;  p.ct = lam(j)*cr;
    r  = llScreen(p, RE_FIX);
    T(j,:) = [cr, p.ct, ...
              (vspVolume(cr, p.ct, 'NACA 2415', 'NACA 2412')/V_bl_ai - 1)*100, ...
              (wingVolume(cr, p.ct, 0.15, 0.12, 3.00)/V_bl_cv - 1)*100, ...
              imp(model(p, f_ai, 0.4005), CDbl_ai_m), imp(model(p, f_cv, 0.4005), CDbl_cv_m), ...
              AI4(1) + (r.alpha - LL4.alpha)*k_ai, a4cv + (r.alpha - LL4.alpha)*k_cv, r.e];
end

% the C004 geometry itself, same model, for reference
imp4_ai = imp(model(P4, f_ai, 0.4005), CDbl_ai_m);
imp4_cv = imp(model(P4, f_cv, 0.4005), CDbl_cv_m);

fprintf('==========================================================================================\n');
fprintf(' RE-SIZED TAPER FAMILY  (NACA 2415 root / 2412 tip, both workflows >= +1%% volume)\n');
fprintf('==========================================================================================\n');
fprintf(' %6s %7s %7s %8s %8s %7s %7s %8s %8s %7s\n', 'lambda', 'cr[m]', 'ct[m]', 'V_AI', 'V_Conv', ...
        'imp AI', 'imp Cv', 'a0 AI', 'a0 Conv', 'e');
fprintf('------------------------------------------------------------------------------------------\n');
fprintf(' %6s %7.3f %7.3f %+7.2f%% %+7.2f%% %+6.2f%% %+6.2f%% %7.2f%s %7.2f%s %7.4f   <- C004 as run\n', ...
        '0.45', P4.cr, P4.ct, (AI4(4)/V_bl_ai-1)*100, (wingVolume(P4.cr,P4.ct,.15,.12,3)/V_bl_cv-1)*100, ...
        imp4_ai, imp4_cv, AI4(1), char(176), a4cv, char(176), LL4.e);
for j = 1:nL
    fprintf(' %6.2f %7.3f %7.3f %+7.2f%% %+7.2f%% %+6.2f%% %+6.2f%% %7.2f%s %7.2f%s %7.4f\n', lam(j), ...
            T(j,1:6), T(j,7), char(176), T(j,8), char(176), T(j,9));
end
fprintf('------------------------------------------------------------------------------------------\n');
fprintf(' imp = predicted CD reduction vs own C000 (calibrated llScreen, Re = 5.0e6, CL = 0.4005)\n');
fprintf(' V_AI is vspVolume (true AI-tool margin was ~1.9 points higher on C004)\n');
fprintf(' C004 CFD (corrected to Re 5.0e6): %+.2f%%  vs model %+.2f%%\n\n', imp(CD4c, AI0(3)), imp4_ai);

%% ---------------- (6) line search along taper ----------------------------
% Model-only preview: three points, as the CFD search will use them
iL = [1 3 4];                              % lambda = 0.45, 0.35, 0.30
CDm = AI0(3) * (1 - T(iL,5)/100);
[lm, Cm, info] = lineSearchQuad(lam(iL), CDm, 0.20/1.4, 1.0);
fprintf('==========================================================================\n');
fprintf(' QUADRATIC LINE SEARCH ON TAPER  (AI workflow)\n');
fprintf('==========================================================================\n');
if info.bracketed
    fprintf(' model preview : minimum bracketed, lambda* = %.3f  (%+.2f%%)\n', lm, imp(Cm, AI0(3)));
else
    fprintf(' model preview : NOT bracketed - drag still falling at lambda = 0.30,\n');
    fprintf('                 so the next step expands the search to lambda = %.3f\n', lm);
    fprintf('                 (lifting line + flat plate has no tip-loading penalty,\n');
    fprintf('                  so CFD - not this model - has to find the turn-around)\n');
end

% ---- CFD: fill these in when C005 / C006 return (re-sized versions) ----
CD_C005 = NaN;     % lambda = 0.35, CD on A_ref at Re 5.0e6
CD_C006 = NaN;     % lambda = 0.30
% lambda = 0.45 point: C004 CFD moved to the re-sized chords with the model
CD_045 = CD4c + (AI0(3)*(1 - T(1,5)/100) - AI0(3)*(1 - imp4_ai/100));

if isnan(CD_C005) || isnan(CD_C006)
    fprintf(' CFD           : waiting on C005 / C006 (lambda 0.45 point ready: CD %.6f)\n', CD_045);
else
    [lc, Cc, ic] = lineSearchQuad([0.45 0.35 0.30], [CD_045 CD_C005 CD_C006], 0.20/1.4, 1.0);
    if ic.bracketed
        fprintf(' CFD           : minimum bracketed, lambda* = %.3f  (predicted %+.2f%%)\n', lc, imp(Cc, AI0(3)));
    else
        fprintf(' CFD           : NOT bracketed - expand the search\n');
    end
    if isnan(ic.next)
        fprintf('                 minimum is at a tested point - line search done\n');
    else
        fprintf('                 next CFD run: lambda = %.3f\n', ic.next);
    end
end
fprintf('==========================================================================\n');

%% ---------------- Plot ---------------------------------------------------
figure('Color','w');
lf = linspace(0.22, 0.50, 60);
ia = zeros(size(lf));  ic = ia;
for j = 1:numel(lf)
    fa = @(c) vspVolume(c, lf(j)*c, 'NACA 2415', 'NACA 2412') - MARGIN*V_bl_ai;
    fc = @(c) wingVolume(c, lf(j)*c, 0.15, 0.12, 3.00)       - MARGIN*V_bl_cv;
    cr = max(fzero(fa, [0.5 3.0]), fzero(fc, [0.5 3.0]));
    p  = P4;  p.cr = cr;  p.ct = lf(j)*cr;
    ia(j) = imp(model(p, f_ai, 0.4005), CDbl_ai_m);
    ic(j) = imp(model(p, f_cv, 0.4005), CDbl_cv_m);
end
plot(lf, ia, 'k-', 'LineWidth', 1.5);  hold on;
plot(lf, ic, 'k--', 'LineWidth', 1.2);
plot(0.45, imp(CD4c, AI0(3)), 'ks', 'MarkerFaceColor', 'k', 'MarkerSize', 7);
plot(0.45, imp4_ai, 'ko', 'MarkerSize', 7);
yline(3, 'r:',  '3% bonus', 'LineWidth', 1.2, 'HandleVisibility', 'off');
yline(5, 'b-.', '5% bonus', 'LineWidth', 1.2, 'HandleVisibility', 'off');
grid on; box on;
set(gca, 'XDir', 'reverse');
xlabel('taper ratio \lambda = c_{tip}/c_{root}');
ylabel('CD reduction vs own C000  [%]');
legend({'AI, re-sized (+1% volume)', 'Conv, re-sized (+1% volume)', ...
        'C004 AI CFD, corrected to Re 5.0e6', 'C004 model'}, 'Location', 'northwest');
ylim([2.5 7]);
title('Taper line search, NACA 2415/2412 family (calibrated llScreen)');

if exist('exportgraphics', 'file')
    exportgraphics(gcf, 'screening_week6.png', 'Resolution', 200);
else
    print(gcf, 'screening_week6.png', '-dpng', '-r200');    % Octave
end
fprintf('Saved screening_week6.png\n');

