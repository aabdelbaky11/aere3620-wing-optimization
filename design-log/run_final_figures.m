% run_final_figures.m
% AerE 3620 Project - Design Lead, final report figures
% Makes every figure the Design Lead sections need (spec section 3, item 2):
%   Fig 3.1  design history: CD reduction per case, both workflows
%            (conventional values vs the RE-RUN C000_conv baseline)
%   Fig 3.2  taper line search on the re-sized family (AI CFD) + parabola
%   Fig 3.3  overlaid baseline and C008 airfoil profiles at root and tip,
%            drawn to scale                                      (spec 2b)
%   Fig 3.4  3D views of the baseline and C008 wings + planform  (spec 2d)
%   Fig 3.5  overlaid baseline and C008 Cp, AI workflow, at 10/50/90% span
%                                                                (spec 2a)
%   Fig 3.6  same for the conventional workflow - only if Gabriel's Cp
%            CSV files are in the repo (see section 6 below)     (spec 2a)
%
% Run from design-log/ inside a clone of the repo, or set REPO below.
% Requires: lineSearchQuad.m (same folder)
% Output PNGs go to report/figures/.

clear; clc; close all;

%% ---------------- paths -------------------------------------------------
REPO = fullfile(fileparts(mfilename('fullpath')), '..');   % repo root
AI   = fullfile(REPO, 'results-ai');
CONV = fullfile(REPO, 'results-conventional');
OUT  = fullfile(REPO, 'report', 'figures');
if ~exist(OUT, 'dir'), mkdir(OUT); end

%% ---------------- CFD results on file (same as run_week10.m) -------------
% All CL/CD on A_ref = 3.00 m^2, Re_cref = 5.0e6 (fixed viscosity).
CD_bl_ai = 0.020052;       % C000_ai_v2
CD_bl_cv = 0.0206168;      % C000_conv_rerun (prism stretching 1.2)
imp = @(CD, CDbl) (CDbl - CD) / CDbl * 100;

CD_AI = struct('C002', CD_bl_ai*(1-0.0191), ...  % Re-corrected (drifted mu run)
               'C004', 0.019308, 'C005', 0.019234, 'C007', 0.019117, ...
               'C008', 0.019087, 'C009', 0.019074);
CD_CV = struct('C005', 0.0201390, 'C008', 0.0199495);

% colours: AI dark grey, conventional orange (as in the weekly figures)
cAI = [0.25 0.25 0.25];   cCV = [0.85 0.33 0.10];
cBL = [0 0 0];            cOP = [0.80 0.10 0.10];   % baseline / optimized

%% ---------------- (1) Fig 3.1 design history -----------------------------
names = {'C002','C004','C005','C007','C008','C009'};
impAI = cellfun(@(n) imp(CD_AI.(n), CD_bl_ai), names);
impCV = NaN(size(names));
impCV(strcmp(names,'C005')) = imp(CD_CV.C005, CD_bl_cv);
impCV(strcmp(names,'C008')) = imp(CD_CV.C008, CD_bl_cv);

figure('Color','w', 'Position', [100 100 760 420]);
hb = bar([impAI(:) impCV(:)], 0.8);  hold on;
set(hb(1), 'FaceColor', cAI);  set(hb(2), 'FaceColor', cCV);
plot([0.4 6.6], [2 2], 'k--', 'LineWidth', 1.0);
plot([0.4 6.6], [3 3], 'r:',  'LineWidth', 1.2);
plot([0.4 6.6], [5 5], 'b-.', 'LineWidth', 1.2);
for k = 1:numel(names)              % value labels on the bars
    text(k-0.15, impAI(k)+0.12, sprintf('%.2f', impAI(k)), ...
         'HorizontalAlignment','center', 'FontSize', 8);
    if ~isnan(impCV(k))
        text(k+0.15, impCV(k)+0.12, sprintf('%.2f', impCV(k)), ...
             'HorizontalAlignment','center', 'FontSize', 8, 'Color', cCV);
    end
end
set(gca, 'XTick', 1:6, 'XTickLabel', names);
ylabel('CD reduction vs own C000  [%]');
ylim([0 5.6]);  grid on;  box on;
legend({'AI workflow', 'Conventional workflow (not run where blank)', ...
        '2% requirement', '3% bonus', '5% bonus'}, 'Location', 'northwest');
title('Design history: CD reduction against each workflow''s own baseline');
exportgraphics(gcf, fullfile(OUT, 'fig3_1_design_history.png'), 'Resolution', 200);

%% ---------------- (2) Fig 3.2 taper line search --------------------------
lamLS = [0.35 0.30 0.25];
CDLS  = [CD_AI.C007 CD_AI.C008 CD_AI.C009];
[lm, Cm, info] = lineSearchQuad(lamLS, CDLS, 0.20/1.40, 1.0);
aqv = @(a, x) a(1) + a(2)*x + a(3)*x.^2;
fprintf('Line search: parabola minimum at taper %.3f, %.3f%% (C009 %.3f%%)\n', ...
        lm, imp(Cm, CD_bl_ai), imp(CD_AI.C009, CD_bl_ai));

lf = linspace(0.20, 0.40, 41);
figure('Color','w', 'Position', [100 100 700 460]);
plot(lf, imp(aqv(info.a, lf), CD_bl_ai), 'k-', 'LineWidth', 1.5);  hold on;
plot(lamLS, imp(CDLS, CD_bl_ai), 'ks', 'MarkerFaceColor', 'k', 'MarkerSize', 8);
plot(lm, imp(Cm, CD_bl_ai), 'kp', 'MarkerFaceColor', [0.6 0.6 0.6], 'MarkerSize', 13);
plot(0.30, imp(CD_AI.C008, CD_bl_ai), 'o', 'Color', [0 0.45 0.74], ...
     'MarkerSize', 16, 'LineWidth', 1.5);
lbl = {'C007','C008','C009'};
for k = 1:3
    text(lamLS(k), imp(CDLS(k), CD_bl_ai) - 0.035, lbl{k}, ...
         'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
end
grid on;  box on;  set(gca, 'XDir', 'reverse');
xlabel('taper ratio \lambda = c_{tip}/c_{root}');
ylabel('CD reduction vs C000\_ai\_v2  [%]');
legend({'parabola through the three CFD points', 'AI CFD', ...
        sprintf('parabola minimum (\\lambda = %.3f)', lm), 'final design C008'}, ...
       'Location', 'southwest');
xlim([0.20 0.40]);  ylim([4.35 5.0]);
title('Taper line search, NACA 2415/2412 re-sized family (AI workflow)');
exportgraphics(gcf, fullfile(OUT, 'fig3_2_line_search.png'), 'Resolution', 200);

%% ---------------- (3) Fig 3.3 airfoil profiles, to scale -----------------
% NACA 4-digit: m = max camber, p = its position, t = thickness (fractions)
BL_root = [0 0 0.12];  BL_c = 1.000;
OP_root = [0.02 0.4 0.15];  OP_cr = 1.348;
OP_tip  = [0.02 0.4 0.12];  OP_ct = 0.404;

figure('Color','w', 'Position', [100 100 760 520]);
tiledlayout(2, 1, 'TileSpacing', 'compact');
nexttile;
[xb, zb] = naca4(BL_root, BL_c);  [xo, zo] = naca4(OP_root, OP_cr);
plot(xb, zb, '-', 'Color', cBL, 'LineWidth', 1.3);  hold on;
plot(xo, zo, '-', 'Color', cOP, 'LineWidth', 1.3);
axis equal;  grid on;  xlim([-0.05 1.45]);
ylabel('z [m]');
legend({'C000: NACA 0012, c = 1.000 m', 'C008: NACA 2415, c = 1.348 m'}, 'Location', 'northeast');
title('Root section (y = 0)');
nexttile;
[xo, zo] = naca4(OP_tip, OP_ct);
plot(xb, zb, '-', 'Color', cBL, 'LineWidth', 1.3);  hold on;
plot(xo, zo, '-', 'Color', cOP, 'LineWidth', 1.3);
axis equal;  grid on;  xlim([-0.05 1.45]);
xlabel('x [m]  (leading edges at x = 0: zero leading-edge sweep)');  ylabel('z [m]');
legend({'C000: NACA 0012, c = 1.000 m', 'C008: NACA 2412, c = 0.404 m'}, 'Location', 'northeast');
title('Tip section (y = 3.00 m)');
exportgraphics(gcf, fullfile(OUT, 'fig3_3_airfoils.png'), 'Resolution', 200);

%% ---------------- (4) Fig 3.4 3D views + planform ------------------------
% Straight loft between root and tip sections, leading edge straight
% (the AI geometry defines sweep at the leading edge, Sweep_Location = 0).
B2 = 3.00;
figure('Color','w', 'Position', [100 100 1100 440]);
tiledlayout(1, 3, 'TileSpacing', 'compact');
nexttile;  drawWing(BL_root, BL_root, BL_c, BL_c, B2, [0.70 0.70 0.70]);
title('Baseline C000 (NACA 0012, rectangular)');
nexttile;  drawWing(OP_root, OP_tip, OP_cr, OP_ct, B2, [0.95 0.55 0.45]);
title('Optimized C008 (NACA 2415/2412, taper 0.30)');
nexttile;
fill([0 BL_c BL_c 0], [0 0 B2 B2], [0.85 0.85 0.85], 'EdgeColor', cBL, 'LineWidth', 1.2);  hold on;
fill([0 OP_cr OP_ct 0], [0 0 B2 B2], cOP, 'FaceAlpha', 0.25, 'EdgeColor', cOP, 'LineWidth', 1.5);
axis equal;  grid on;  xlim([-0.1 1.5]);  ylim([0 3.1]);
xlabel('x [m]');  ylabel('y [m]');
legend({'C000, S = 3.00 m^2', sprintf('C008, S = %.3f m^2', (OP_cr+OP_ct)/2*B2)}, ...
       'Location', 'northeast');
title('Planform (top view, flow +x)');
exportgraphics(gcf, fullfile(OUT, 'fig3_4_wings_3d.png'), 'Resolution', 200);

%% ---------------- (5) Fig 3.5 Cp overlays, AI workflow --------------------
% AI stations are 10/50/90% span (y = 0.3, 1.5, 2.7 m): the agent's
% post-processing cannot cut exactly at the symmetry plane or the tip cap.
stations = [10 50 90];
stName   = {'near root, 10% span', 'mid-span, 50%', 'near tip, 90% span'};
figure('Color','w', 'Position', [100 100 1150 400]);
tiledlayout(1, 3, 'TileSpacing', 'compact');
for k = 1:3
    nexttile;
    b = readCp(fullfile(AI, 'C000_ai_v2', 'plot_data', ...
        sprintf('C000_ai_v2_wing_pressure_profile_span_%d%%_surface_ordered.dat', stations(k))));
    o = readCp(fullfile(AI, 'C008_ai', 'plot_data', ...
        sprintf('C008_ai_wing_pressure_profile_span_%d%%_surface_ordered.dat', stations(k))));
    plot(b(:,1), b(:,2), '-', 'Color', cBL, 'LineWidth', 1.2);  hold on;
    plot(o(:,1), o(:,2), '-', 'Color', cOP, 'LineWidth', 1.2);
    set(gca, 'YDir', 'reverse');  grid on;  box on;
    xlim([0 1]);  ylim([-1.7 1.1]);
    xlabel('x/c');
    if k == 1, ylabel('C_p'); end
    title(stName{k});
    if k == 1
        legend({'C000\_ai\_v2 (\alpha 5.415\circ)', 'C008\_ai (\alpha 4.216\circ)'}, ...
               'Location', 'southeast');
    end
end
sgtitle('Sectional C_p at CL = 0.4, baseline vs C008 (AI workflow)');
exportgraphics(gcf, fullfile(OUT, 'fig3_5_cp_ai.png'), 'Resolution', 200);

%% ---------------- (6) Fig 3.6 Cp overlays, conventional workflow ---------
% Needs CSV exports from STAR-CCM+ (x/c in column 1, Cp in column 2, one
% header row), named as below, at the SAME stations as the AI plots
% (y = 0.3, 1.5, 2.7 m). Skipped until the files are in the repo.
convFiles = @(c, st) fullfile(CONV, c, sprintf('%s_cp_span_%d.csv', c, st));
haveConv = all(arrayfun(@(st) isfile(convFiles('C000_conv_rerun', st)) && ...
                              isfile(convFiles('C008_conv', st)), stations));
if haveConv
    figure('Color','w', 'Position', [100 100 1150 400]);
    tiledlayout(1, 3, 'TileSpacing', 'compact');
    for k = 1:3
        nexttile;
        b = readmatrix(convFiles('C000_conv_rerun', stations(k)), 'NumHeaderLines', 1);
        o = readmatrix(convFiles('C008_conv',       stations(k)), 'NumHeaderLines', 1);
        % STAR-CCM+ exports are not ordered round the section: plot as points
        plot(b(:,1), b(:,2), '.', 'Color', cBL, 'MarkerSize', 6);  hold on;
        plot(o(:,1), o(:,2), '.', 'Color', cOP, 'MarkerSize', 6);
        set(gca, 'YDir', 'reverse');  grid on;  box on;
        xlim([0 1]);  ylim([-1.7 1.1]);
        xlabel('x/c');
        if k == 1, ylabel('C_p'); end
        title(stName{k});
        if k == 1
            legend({'C000\_conv (\alpha 5.840\circ)', 'C008\_conv (\alpha 5.145\circ)'}, ...
                   'Location', 'southeast');
        end
    end
    sgtitle('Sectional C_p at CL = 0.4, baseline vs C008 (conventional workflow)');
    exportgraphics(gcf, fullfile(OUT, 'fig3_6_cp_conv.png'), 'Resolution', 200);
else
    fprintf(['Fig 3.6 skipped: conventional Cp CSVs not found, e.g.\n  %s\n' ...
             'Ask Gabriel to export x/c and Cp at y = 0.3, 1.5 and 2.7 m.\n'], ...
            convFiles('C008_conv', 10));
end

fprintf('Figures written to %s\n', OUT);

%% ======================== local functions ================================
function [x, z] = naca4(mpt, c, n)
% NACA 4-digit section scaled to chord c, closed loop from the trailing edge
% over the upper surface to the leading edge and back along the lower surface.
% mpt = [m p t] as fractions, e.g. NACA 2415 -> [0.02 0.4 0.15].
if nargin < 3, n = 81; end
m = mpt(1);  p = mpt(2);  t = mpt(3);
xc = (1 - cos(linspace(0, pi, n))) / 2;            % cosine spacing
yt = 5*t*(0.2969*sqrt(xc) - 0.1260*xc - 0.3516*xc.^2 + 0.2843*xc.^3 - 0.1015*xc.^4);
yc = zeros(size(xc));  dy = zeros(size(xc));
if m > 0
    f = xc < p;
    yc(f)  = m/p^2 * (2*p*xc(f) - xc(f).^2);
    dy(f)  = 2*m/p^2 * (p - xc(f));
    yc(~f) = m/(1-p)^2 * ((1 - 2*p) + 2*p*xc(~f) - xc(~f).^2);
    dy(~f) = 2*m/(1-p)^2 * (p - xc(~f));
end
th = atan(dy);
xu = xc - yt.*sin(th);  zu = yc + yt.*cos(th);
xl = xc + yt.*sin(th);  zl = yc - yt.*cos(th);
x = c * [fliplr(xu) xl(2:end)];
z = c * [fliplr(zu) zl(2:end)];
end

function drawWing(secRoot, secTip, cr, ct, b2, col)
% Straight loft between the root and tip sections, leading edge at x = 0.
[xr, zr] = naca4(secRoot, cr);
[xt, zt] = naca4(secTip,  ct);
eta = linspace(0, 1, 25)';                       % spanwise stations
X = (1-eta)*xr + eta*xt;
Z = (1-eta)*zr + eta*zt;
Y = repmat(eta*b2, 1, numel(xr));
surf(X, Y, Z, 'FaceColor', col, 'EdgeColor', 'none');  hold on;
plot3(xr, zeros(size(xr)), zr, 'k-', 'LineWidth', 1);  % root outline
plot3(xt, b2*ones(size(xt)), zt, 'k-', 'LineWidth', 1);  % tip outline
plot3([0 0], [0 b2], [0 0], 'k-');                       % leading edge
plot3([xr(1) xt(1)], [0 b2], [zr(1) zt(1)], 'k-');      % trailing edge
axis equal;  grid on;  box on;
xlim([-0.1 1.5]);  ylim([0 3.1]);  zlim([-0.4 0.4]);
xlabel('x [m]');  ylabel('y [m]');  zlabel('z [m]');
view(-50, 22);  camlight('headlight');  lighting gouraud;
end

function d = readCp(file)
% AI plot_data file: columns point_order, x/c, z/c, Cp; '#' comment lines.
% Rows are already ordered round the section, so they are plotted as given.
fid = fopen(file, 'r');
if fid < 0, error('Cannot open %s', file); end
C = textscan(fid, '%f %f %f %f', 'CommentStyle', '#');
fclose(fid);
d = [C{2} C{4}];                                     % [x/c, Cp]
end
