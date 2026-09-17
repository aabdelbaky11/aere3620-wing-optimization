% run_week1.m
% AerE 3620 Project - Design Lead, Week 1
% (1) Establish the baseline half-wing volume V_bl
% (2) Map the feasible taper region in the (cr, ct) plane
%
% Run this from the /design-log folder with wingVolume.m and checkDesign.m
% on the path.

clear; clc; close all;

%% ---------------- Fixed project quantities -----------------------------
SEMISPAN = 3.00;      % b/2 [m], fixed by spec
TC_0012  = 0.12;      % NACA 0012 thickness ratio
K        = 0.685;     % NACA 4-digit area coefficient

%% ---------------- (1) Baseline volume ----------------------------------
cr_bl = 1.00;
ct_bl = 1.00;

V_bl = wingVolume(cr_bl, ct_bl, TC_0012, TC_0012, SEMISPAN, K);

% Closed-form cross-check (valid because root and tip t/c are equal)
V_bl_closed = K * TC_0012 * SEMISPAN * (cr_bl^2 + cr_bl*ct_bl + ct_bl^2) / 3;

fprintf('BASELINE WING\n');
fprintf('  NACA 0012 root and tip, cr = %.2f m, ct = %.2f m, b/2 = %.2f m\n', ...
        cr_bl, ct_bl, SEMISPAN);
fprintf('  V_bl (numerical)  = %.6f m^3\n', V_bl);
fprintf('  V_bl (closed form)= %.6f m^3\n', V_bl_closed);
fprintf('  difference        = %.2e m^3\n\n', abs(V_bl - V_bl_closed));

%% ---------------- (2) Feasible taper region ----------------------------
% Constraint in normalized form:  g(cr,ct) = 1 - V/V_bl <= 0
% g > 0 is INFEASIBLE.

crv = linspace(0.2, 3.0, 300);
ctv = linspace(0.2, 3.0, 300);
[CR, CT] = meshgrid(crv, ctv);

V_grid = K * TC_0012 * SEMISPAN .* (CR.^2 + CR.*CT + CT.^2) / 3;
G      = 1 - V_grid ./ V_bl;          % > 0 means volume constraint violated

figure('Color','w');
hold on; grid on; box on;

% Cyan infeasible hatching FIRST so the boundary stays visible on top
contour(CR, CT, G, [0:0.05:0.4], 'Color', [0 0.8 0.9], 'LineWidth', 0.8);

% Constraint boundary g = 0
contour(CR, CT, G, [0 0], 'k-', 'LineWidth', 2.0);

% Baseline point
plot(cr_bl, ct_bl, 'ro', 'MarkerFaceColor','r', 'MarkerSize', 8);
text(cr_bl+0.06, ct_bl+0.06, 'baseline', 'FontSize', 10);

xlabel('root chord c_r  [m]');
ylabel('tip chord c_t  [m]');
title('Volume-feasible taper region  (V \geq V_{bl} = 0.247 m^3, NACA 0012)');
axis([0.2 3.0 0.2 3.0]);
axis square;

exportgraphics(gcf, 'feasible_taper_region.png', 'Resolution', 200);
fprintf('Saved feasible_taper_region.png\n\n');

%% ---------------- (3) Example: check a tapered candidate ---------------
% Illustrates how much root chord is needed to pay back a taper to ct = 0.6
d.name      = 'C001-example';
d.cr        = 1.36;
d.ct        = 0.60;
d.tc_root   = TC_0012;
d.tc_tip    = TC_0012;
d.sweep     = 0.0;
d.twist_tip = 0.0;
d.alpha     = NaN;    % not yet chosen
d.CL        = NaN;    % pending CFD
d.CD        = NaN;    % pending CFD

% alpha is NaN here, so relax that bound check by setting it mid-range
d.alpha = 2.0;

checkDesign(d, V_bl, NaN);
