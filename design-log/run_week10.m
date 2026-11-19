% run_week10.m
% AerE 3620 Project - Design Lead, Week 10 (report week ending 11/20)
% New CFD in: C000_conv_rerun (conventional baseline re-meshed with prism
%             layer stretching 1.2, the same setting C008_conv used; 11/13)
% This script:
%   (1) compares the re-run baseline with the original C000_conv
%   (2) re-checks the final design C008 against both baselines
%   (3) bonus status with the re-run baseline
%   (4) workflow gap: alpha shift and drag drop vs lifting-line theory
%       on the two identical wings (C005, C008) - evidence for the final
%       report's workflow-comparison discussion
%   (5) figure for the final report
%
% Requires: llScreen.m, checkDesign.m

clear; clc; close all;

%% ---------------- CFD results on file -----------------------------------
% All CL/CD on A_ref = 3.00 m^2.
RE_FIX = 5.0e6;

%           alpha     CL          CD           V
AI0   = [   5.41482,  0.400507,   0.020052,    0.246898 ];  % C000_ai_v2
AI5   = [   4.03904,  0.40045,    0.019234,    0.263592 ];  % C005_ai
AI8   = [   4.21572,  0.40051,    0.019087,    0.254221 ];  % C008_ai
CV0o  = [   5.840,    0.4006155,  0.0206204,   0.24688  ];  % C000_conv, original (stretching 1.3)
CV0   = [   5.840,    0.4002621,  0.0206168,   0.24688  ];  % C000_conv_rerun (stretching 1.2) (new)
CV5   = [   4.970,    0.4000489,  0.0201390,   0.25948  ];  % C005_conv (stretching 1.3)
CV8   = [   5.145,    0.4000218,  0.0199495,   0.250497 ];  % C008_conv (stretching 1.2)

P0 = struct('p_root','NACA 0012','p_tip','NACA 0012','cr',1.000,'ct',1.000,'twist_tip',0);
P5 = struct('p_root','NACA 2415','p_tip','NACA 2412','cr',1.337,'ct',0.468,'twist_tip',0);
P8 = P5;  P8.cr = 1.348;  P8.ct = 0.404;

V_bl_ai = AI0(4);   CD_bl_ai = AI0(3);
V_bl_cv = CV0(4);   CD_bl_cv = CV0(3);

imp = @(CD, CDbl) (CDbl - CD) / CDbl * 100;

%% ---------------- (1) re-run baseline vs original ------------------------
fprintf('==========================================================================\n');
fprintf(' C000_conv RE-RUN  (prism layer stretching 1.3 -> 1.2, same as C008_conv)\n');
fprintf('==========================================================================\n');
fprintf(' %-22s %12s %12s %10s\n', '', 'original', 're-run', 'change');
fprintf(' %-22s %12.3f %12.3f %+10.3f\n', 'alpha [deg]', CV0o(1), CV0(1), CV0(1)-CV0o(1));
fprintf(' %-22s %12.6f %12.6f %+9.3f%%\n', 'CL', CV0o(2), CV0(2), (CV0(2)/CV0o(2)-1)*100);
fprintf(' %-22s %12.6f %12.6f %+9.3f%%\n', 'CD', CV0o(3), CV0(3), (CV0(3)/CV0o(3)-1)*100);
fprintf(' %-22s %12d %12d %+10d\n', 'cells', 439710, 439369, 439369-439710);
fprintf(' %-22s %12.1f %12.1f\n', 'max skewness [deg]', 85.0, 80.0);
fprintf(' %-22s %12s %12s\n', 'wall y+', '<= 109.6', '31.3-96.1');
fprintf('--------------------------------------------------------------------------\n');
fprintf(' The stretching change moves CD by %.3f%% - far below the 3-sig-fig CFD\n', abs(CV0(3)/CV0o(3)-1)*100);
fprintf(' resolution. Baseline and C008 now share the same mesh settings (spec).\n');
fprintf(' y+ and skewness are now inside the limits. Residuals still ~1e-5 (energy\n');
fprintf(' 6.8e-4): Prof. He''s approval must be quoted in the final report.\n');
fprintf(' CL 0.40026 >= 0.4 (not re-trimmed; alpha kept at 5.840 deg).\n');
fprintf('==========================================================================\n\n');

%% ---------------- (2) final design C008 against both baselines -----------
d = struct('name','C008_conv','cr',P8.cr,'ct',P8.ct,'tc_root',0.15,'tc_tip',0.12, ...
           'sweep',0,'twist_tip',0,'alpha',CV8(1),'CL',CV8(2),'CD',CV8(3),'V',CV8(4));
c8cv = checkDesign(d, V_bl_cv, CD_bl_cv);

d.name = 'C008_ai';
d.alpha = AI8(1);  d.CL = AI8(2);  d.CD = AI8(3);  d.V = AI8(4);
c8 = checkDesign(d, V_bl_ai, CD_bl_ai);

% C000_conv_rerun itself against Table 1 (the baseline must satisfy it too)
d.name = 'C000_conv_rerun';  d.cr = 1.0;  d.ct = 1.0;  d.tc_root = 0.12;
d.alpha = CV0(1);  d.CL = CV0(2);  d.CD = CV0(3);  d.V = CV0(4);
c0cv = checkDesign(d, V_bl_cv, CD_bl_cv);

%% ---------------- (3) bonus status ----------------------------------------
CD3 = 0.97 * CD_bl_cv;
fprintf('==========================================================================\n');
fprintf(' BONUS STATUS WITH THE RE-RUN BASELINE (only the highest row applies)\n');
fprintf('==========================================================================\n');
fprintf(' C008_conv vs original C000_conv : %+.2f%%\n', imp(CV8(3), CV0o(3)));
fprintf(' C008_conv vs re-run   C000_conv : %+.2f%%   <- reported value\n', c8cv.improvement);
fprintf(' C008_ai   vs C000_ai_v2         : %+.2f%%\n', c8.improvement);
fprintf(' 3%% line (conv): CD <= %.6f   C008_conv margin: %.6f (%.2f points)\n', ...
        CD3, CD3 - CV8(3), c8cv.improvement - 3);
fprintf('--------------------------------------------------------------------------\n');
if c8.improvement >= 3 && c8cv.improvement >= 3
    fprintf(' Both workflows >= 3%% on the same design -> +5 points. BONUS HOLDS.\n');
end
fprintf('==========================================================================\n\n');

%% ---------------- (4) workflow gap vs lifting-line theory ----------------
r0 = llScreen(P0, RE_FIX);  r5 = llScreen(P5, RE_FIX);  r8 = llScreen(P8, RE_FIX);
daLL = [r5.alpha - r0.alpha,  r8.alpha - r0.alpha];
daAI = [AI5(1) - AI0(1),      AI8(1) - AI0(1)];
daCV = [CV5(1) - CV0(1),      CV8(1) - CV0(1)];
dAI  = [CD_bl_ai - AI5(3),    CD_bl_ai - AI8(3)];
dCV  = [CD_bl_cv - CV5(3),    CD_bl_cv - CV8(3)];

fprintf('==========================================================================\n');
fprintf(' WORKFLOW GAP: identical wings, each workflow vs its own C000\n');
fprintf('==========================================================================\n');
fprintf(' %-34s %10s %10s\n', '', 'C005', 'C008');
fprintf(' %-34s %+10.3f %+10.3f\n', 'alpha shift, lifting line [deg]', daLL(1), daLL(2));
fprintf(' %-34s %+10.3f %+10.3f\n', 'alpha shift, AI CFD [deg]', daAI(1), daAI(2));
fprintf(' %-34s %+10.3f %+10.3f\n', 'alpha shift, conv CFD [deg]', daCV(1), daCV(2));
fprintf(' %-34s %9.0f%% %9.0f%%\n', '  AI share of theory', daAI(1)/daLL(1)*100, daAI(2)/daLL(2)*100);
fprintf(' %-34s %9.0f%% %9.0f%%\n', '  conv share of theory', daCV(1)/daLL(1)*100, daCV(2)/daLL(2)*100);
fprintf(' %-34s %10.6f %10.6f\n', 'drag drop, AI', dAI(1), dAI(2));
fprintf(' %-34s %10.6f %10.6f\n', 'drag drop, conv', dCV(1), dCV(2));
fprintf(' %-34s %10.3f %10.3f\n', '  conv/AI drag-drop ratio', dCV(1)/dAI(1), dCV(2)/dAI(2));
fprintf('--------------------------------------------------------------------------\n');
fprintf(' Lifting line (inviscid) gives the full camber + planform alpha shift.\n');
fprintf(' Viscous CFD should show less (boundary-layer decambering), and both do,\n');
fprintf(' but the conv workflow shows much less than the AI workflow. Theory\n');
fprintf(' predicts the SAME shift in both, so the gap is a workflow difference:\n');
fprintf('  - camber/incidence of the SOLIDWORKS sections (volume checks cannot\n');
fprintf('    detect it: volume depends on thickness only) - asked Gabriel 11/18\n');
fprintf('  - near-wall treatment: conv wall functions (y+ 30-100) vs AI y+ ~8-83\n');
fprintf('  - conv residuals stop at ~1e-5 (AI drops >= 6.5 orders)\n');
fprintf(' Note: C005_conv was meshed with stretching 1.3, so its numbers vs the\n');
fprintf(' re-run baseline are for this comparison only (CD effect ~0.02%%).\n');
fprintf('==========================================================================\n');

%% ---------------- (5) figure for the final report -------------------------
figure('Color','w', 'Position', [100 100 900 380]);

subplot(1,2,1);
hb = bar(-[daLL(:) daAI(:) daCV(:)], 0.85);
set(hb(1), 'FaceColor', [0.75 0.75 0.75]);
set(hb(2), 'FaceColor', [0.25 0.25 0.25]);
set(hb(3), 'FaceColor', [0.85 0.33 0.10]);
set(gca, 'XTickLabel', {'C005', 'C008'});
ylabel('alpha reduction vs C000  [deg]');
legend({'lifting line', 'AI CFD', 'Conv CFD'}, 'Location', 'northeast');
title('Alpha needed for CL = 0.4');
grid on;  box on;  ylim([0 2.8]);

subplot(1,2,2);
hb = bar([imp(AI5(3),CD_bl_ai) imp(CV5(3),CD_bl_cv); c8.improvement c8cv.improvement], 0.85);
set(hb(1), 'FaceColor', [0.25 0.25 0.25]);
set(hb(2), 'FaceColor', [0.85 0.33 0.10]);
hold on;
plot([0.5 2.5], [3 3], 'r:', 'LineWidth', 1.2);
set(gca, 'XTickLabel', {'C005', 'C008 (final)'});
ylabel('CD reduction vs own C000  [%]');
legend({'AI CFD', 'Conv CFD', '3% bonus'}, 'Location', 'northwest');
title('Drag reduction');
grid on;  box on;  ylim([0 5.5]);

exportgraphics(gcf, 'workflow_gap_week10.png', 'Resolution', 200);
