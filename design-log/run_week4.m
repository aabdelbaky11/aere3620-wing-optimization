% run_week4.m
% AerE 3620 Project - Design Lead, Week 4
% C000 baseline results are back from both workflows. This script:
%   (1) checks both C000 results against the Table 1 constraints
%   (2) compares the CFD baselines with the llScreen prediction
%   (3) trims the conventional baseline to CL = 0.4 (one Newton step,
%       derivative dCL/dalpha taken from the lifting-line model)
%   (4) calibrates llScreen to each workflow and re-ranks C001-C004
%   (5) gives each workflow its own starting alpha for every request
%   (6) predicts a taper line search for the C004 airfoil family
%
% Requires: llScreen.m, checkDesign.m, wingVolume.m, solveRootChord.m

clear; clc; close all;

%% ---------------- C000 results returned this week -----------------------
%            alpha [deg]  CL         CD
AI   = [     5.408,       0.400007,  0.020010 ];   % Kade, AI-agent workflow
CONV = [     4.800,       0.404943,  0.023383 ];   % Gabriel, STAR-CCM+

V_bl   = wingVolume(1.00, 1.00, 0.12, 0.12, 3.00);
V_ai   = 0.246898;            % volume reported by the AI tool's geometry

%% ---------------- (1) constraint check on both baselines ----------------
d = struct('name','C000 (AI)','cr',1.00,'ct',1.00,'tc_root',0.12,'tc_tip',0.12, ...
           'sweep',0,'twist_tip',0,'alpha',AI(1),'CL',AI(2),'CD',AI(3));
checkDesign(d, V_bl, AI(3));
d.name = 'C000 (Conv)';  d.alpha = CONV(1);  d.CL = CONV(2);  d.CD = CONV(3);
checkDesign(d, V_bl, CONV(3));

%% ---------------- (2) llScreen prediction of the baseline ---------------
b.p_root = 'NACA 0012';  b.p_tip = 'NACA 0012';
b.cr = 1.00;  b.ct = 1.00;  b.twist_tip = 0;
LL  = llScreen(b);
CLa = 0.4 / LL.alpha;                         % [1/deg], symmetric section

%% ---------------- (3) trim the conventional case to CL = 0.4 ------------
% Newton step on g(alpha) = CL(alpha) - 0.4, using the lifting-line slope
% because only one CFD point exists. Induced drag scales with CL^2.
alpha_cv = CONV(1) - (CONV(2) - 0.4) / CLa;
CD_cv    = CONV(3) - LL.CDi * (CONV(2)^2 / 0.4^2 - 1);

fprintf('==========================================================================\n');
fprintf(' C000 BASELINE: CFD vs LOW-FIDELITY   (CL = 0.4, A_ref = 3.00 m^2)\n');
fprintf('==========================================================================\n');
fprintf(' %-16s %10s %8s %9s %9s %11s\n', 'source', 'alpha[deg]', 'CL', 'CD', 'CD/CD_LL', 'CLa[1/deg]');
fprintf('--------------------------------------------------------------------------\n');
fprintf(' %-16s %10.3f %8.4f %9.5f %9.3f %11.4f\n', 'llScreen',      LL.alpha, 0.4,     LL.CD,   1,             CLa);
fprintf(' %-16s %10.3f %8.4f %9.5f %9.3f %11.4f\n', 'AI (Kade)',     AI(1),    AI(2),   AI(3),   AI(3)/LL.CD,   AI(2)/AI(1));
fprintf(' %-16s %10.3f %8.4f %9.5f %9.3f %11.4f\n', 'Conv (Gabriel)',CONV(1),  CONV(2), CONV(3), CONV(3)/LL.CD, CONV(2)/CONV(1));
fprintf(' %-16s %10.3f %8.4f %9.5f %9.3f %11s\n',   'Conv trimmed*', alpha_cv, 0.4,     CD_cv,   CD_cv/LL.CD,   '-');
fprintf('--------------------------------------------------------------------------\n');
fprintf(' * estimate only: Newton step with lifting-line dCL/dalpha; needs a CFD re-run\n');
fprintf(' AI vs Conv(trimmed) CD gap: %.1f%%     V_ai / V_bl = %.4f\n', ...
        (CD_cv - AI(3))/AI(3)*100, V_ai/V_bl);

%% ---------------- (4) calibrate llScreen to each workflow ---------------
% Assume lifting line gets induced drag right and CFD sees more profile
% drag:  CD_cfd = CDi_LL + f * CD0_LL.  f is fitted on C000.
f_ai = (AI(3) - LL.CDi) / LL.CD0;
f_cv = (CD_cv - LL.CDi) / LL.CD0;
fprintf(' profile-drag factor f = (CD_cfd - CDi_LL)/CD0_LL :  AI %.3f   Conv %.3f\n\n', f_ai, f_cv);

%        name    p_root       p_tip        cr     ct     twist  description
cand = {
  'C001', 'NACA 2412', 'NACA 2412', 1.010, 1.010,  0.0, 'camber only'
  'C002', 'NACA 0012', 'NACA 0012', 1.361, 0.612,  0.0, 'taper 0.45'
  'C003', 'NACA 2412', 'NACA 2412', 1.361, 0.612,  0.0, 'camber + taper'
  'C004', 'NACA 2415', 'NACA 2412', 1.266, 0.570,  0.0, 'thick root + taper'
};
nC  = size(cand,1);
imp = zeros(nC,5);    % [LL, AI-cal, AI-add, Conv-cal, Conv-add]
a0  = zeros(nC,2);    % starting alpha [AI, Conv]

for k = 1:nC
    d.p_root = cand{k,2};  d.p_tip = cand{k,3};
    d.cr = cand{k,4};  d.ct = cand{k,5};  d.twist_tip = cand{k,6};
    r = llScreen(d);
    dCD = LL.CD - r.CD;
    imp(k,1) = dCD / LL.CD * 100;                                  % ratio model
    imp(k,2) = (AI(3) - (r.CDi + f_ai*r.CD0)) / AI(3) * 100;       % calibrated
    imp(k,3) = dCD / AI(3) * 100;                                  % offset model
    imp(k,4) = (CD_cv - (r.CDi + f_cv*r.CD0)) / CD_cv * 100;
    imp(k,5) = dCD / CD_cv * 100;

    % starting alpha: keep the lifting-line zero-lift angle, scale the
    % lift-slope part by each workflow's baseline alpha ratio
    d0 = d;  d0.p_root = 'NACA 0012';  d0.p_tip = 'NACA 0012';
    rs = llScreen(d0);                       % same planform, symmetric
    aZL = r.alpha - rs.alpha;                % zero-lift shift from camber
    a0(k,1) = aZL + rs.alpha * AI(1)   / LL.alpha;
    a0(k,2) = aZL + rs.alpha * alpha_cv / LL.alpha;
end

fprintf('==========================================================================================\n');
fprintf(' PREDICTED CD REDUCTION vs EACH WORKFLOW''S OWN C000  [%%]\n');
fprintf('==========================================================================================\n');
fprintf(' %-5s %-19s %6s %7s %7s %8s %8s %9s %9s\n', 'case', 'change', 'LL', 'AI-cal', 'AI-add', ...
        'Cv-cal', 'Cv-add', 'a0 AI', 'a0 Conv');
fprintf('------------------------------------------------------------------------------------------\n');
for k = 1:nC
    fprintf(' %-5s %-19s %+6.2f %+7.2f %+7.2f %+8.2f %+8.2f %8.2f%s %8.2f%s\n', cand{k,1}, cand{k,7}, ...
            imp(k,:), a0(k,1), char(176), a0(k,2), char(176));
end
fprintf('------------------------------------------------------------------------------------------\n');
fprintf(' cal = profile drag scaled by f     add = fixed CD offset (worst case for every candidate)\n\n');

%% ---------------- (6) taper line search, C004 airfoil family ------------
V_target = 1.02 * V_bl;
lam = [0.45 0.40 0.35 0.30];
fprintf('==========================================================================\n');
fprintf(' LINE SEARCH ALONG TAPER  (NACA 2415 root / 2412 tip, V = 1.02 V_bl)\n');
fprintf('==========================================================================\n');
fprintf(' %6s %8s %8s %10s %7s %7s %8s %8s\n', 'lambda', 'cr[m]', 'ct[m]', 'V[m^3]', 'e', 'LL', 'AI-cal', 'Cv-cal');
fprintf('--------------------------------------------------------------------------\n');
for j = 1:numel(lam)
    cr = solveRootChord(lam(j), 0.15, 0.12, V_target);
    d.p_root = 'NACA 2415';  d.p_tip = 'NACA 2412';
    d.cr = cr;  d.ct = lam(j)*cr;  d.twist_tip = 0;
    r = llScreen(d);
    fprintf(' %6.2f %8.3f %8.3f %10.5f %7.4f %+7.2f %+8.2f %+8.2f\n', lam(j), cr, d.ct, ...
            wingVolume(cr, d.ct, 0.15, 0.12, 3.00), r.e, (LL.CD - r.CD)/LL.CD*100, ...
            (AI(3) - (r.CDi + f_ai*r.CD0))/AI(3)*100, (CD_cv - (r.CDi + f_cv*r.CD0))/CD_cv*100);
end
fprintf('==========================================================================\n');

%% ---------------- Plot ---------------------------------------------------
figure('Color','w');
hb = bar(categorical(cand(:,1)), imp(:,[1 2 4 5]), 'grouped');
shades = [0.15 0.15 0.15; 0.45 0.45 0.45; 0.70 0.70 0.70; 1 1 1];
for i = 1:4
    hb(i).FaceColor = shades(i,:);  hb(i).EdgeColor = 'k';
end
hold on; grid on; box on;
yline(2, 'b-.', '2% target', 'LineWidth', 1.2, 'HandleVisibility', 'off');
yline(3, 'r:',  '3% bonus',  'LineWidth', 1.2, 'HandleVisibility', 'off');
yline(0, 'k-', 'HandleVisibility', 'off');
legend({'lifting line only', 'calibrated to AI C000', ...
        'calibrated to Conv C000', 'Conv, fixed-offset worst case'}, 'Location', 'northwest');
ylabel('predicted CD reduction vs own C000  [%]');
title('Candidates re-ranked after C000 (all at +2% V margin, CL = 0.4)');

exportgraphics(gcf, 'screening_week4.png', 'Resolution', 200);
fprintf('Saved screening_week4.png\n');
