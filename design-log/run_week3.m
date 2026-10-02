% run_week3.m
% AerE 3620 Project - Design Lead, Week 3
% Low-fidelity screening of C000-C004 while the baseline CFD is pending:
%   (1) predicted alpha for CL = 0.4 and predicted CD for each candidate
%   (2) taper / tip-twist sweep at fixed volume to check the candidate choices
%
% Requires: llScreen.m, solveRootChord.m, wingVolume.m

clear; clc; close all;

%% ---------------- Candidates (from design_log.csv) ----------------------
%        name    p_root       p_tip        cr     ct     twist
cand = {
  'C000', 'NACA 0012', 'NACA 0012', 1.000, 1.000,  0.0
  'C001', 'NACA 2412', 'NACA 2412', 1.010, 1.010,  0.0
  'C002', 'NACA 0012', 'NACA 0012', 1.361, 0.612,  0.0
  'C003', 'NACA 2412', 'NACA 2412', 1.361, 0.612, -2.0
  'C004', 'NACA 2415', 'NACA 2412', 1.266, 0.570, -2.0
};

nC = size(cand,1);
R  = struct([]);
for k = 1:nC
    d.p_root    = cand{k,2};
    d.p_tip     = cand{k,3};
    d.cr        = cand{k,4};
    d.ct        = cand{k,5};
    d.twist_tip = cand{k,6};
    R = [R, llScreen(d)]; %#ok<AGROW>
end
CD_bl_est = R(1).CD;

fprintf('==========================================================================\n');
fprintf(' LOW-FIDELITY SCREENING  (lifting line + skin friction, CL = 0.4)\n');
fprintf('==========================================================================\n');
fprintf(' %-5s %9s %7s %8s %8s %8s %10s\n', ...
        'case', 'alpha[deg]', 'e', 'CDi', 'CD0', 'CD', 'dCD vs C000');
fprintf('--------------------------------------------------------------------------\n');
for k = 1:nC
    imp = (CD_bl_est - R(k).CD) / CD_bl_est * 100;
    fprintf(' %-5s %9.3f %7.4f %8.5f %8.5f %8.5f %+9.2f%%\n', ...
            cand{k,1}, R(k).alpha, R(k).e, R(k).CDi, R(k).CD0, R(k).CD, imp);
end
fprintf('==========================================================================\n\n');

%% ---------------- Taper / twist sweep at fixed volume -------------------
% Every point is volume-matched at +2% margin (same as run_week2.m), so
% every point on these curves satisfies V >= V_bl by construction.
V_bl     = wingVolume(1.00, 1.00, 0.12, 0.12, 3.00);
V_target = 1.02 * V_bl;

lam    = 0.25:0.025:1.00;
twists = [-2 0 2];
imp    = zeros(numel(twists), numel(lam));

for i = 1:numel(twists)
    for j = 1:numel(lam)
        cr = solveRootChord(lam(j), 0.12, 0.12, V_target);
        d.p_root = 'NACA 0012';  d.p_tip = 'NACA 0012';
        d.cr = cr;  d.ct = lam(j)*cr;  d.twist_tip = twists(i);
        r = llScreen(d);
        imp(i,j) = (CD_bl_est - r.CD) / CD_bl_est * 100;
    end
end

%% ---------------- Plot ---------------------------------------------------
figure('Color','w');
hold on; grid on; box on;
sty = {'--', '-', ':'};
for i = 1:numel(twists)
    plot(lam, imp(i,:), sty{i}, 'Color', 'k', 'LineWidth', 1.8, ...
         'DisplayName', sprintf('\\theta_{tip} = %+d^\\circ', twists(i)));
end
mk  = {'o','s','^','d'};
lamC = [1.00 0.45 0.45 0.45];
for k = 2:nC
    plot(lamC(k-1), (CD_bl_est - R(k).CD)/CD_bl_est*100, mk{k-1}, ...
         'MarkerSize', 9, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k', ...
         'DisplayName', cand{k,1});
end
yline(2, 'b-.', '2% target', 'LineWidth', 1.2, 'HandleVisibility', 'off');
xlabel('taper ratio  \lambda = c_t / c_r');
ylabel('predicted CD reduction vs C000  [%]');
title('Low-fidelity screening at fixed volume (NACA 0012, +2% V margin)');
legend('Location', 'northeast');
xlim([0.25 1.0]);

exportgraphics(gcf, 'screening_week3.png', 'Resolution', 200);
fprintf('Saved screening_week3.png\n');
