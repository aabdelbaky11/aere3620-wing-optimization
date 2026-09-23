% run_week2.m
% AerE 3620 Project - Design Lead, Week 2
% Generate candidate designs C001-C004 that satisfy the volume constraint
% by construction, and verify every Table 1 bound.
%
% Requires: wingVolume.m, checkDesign.m, solveRootChord.m

clear; clc; close all;

%% ---------------- Baseline ---------------------------------------------
SEMISPAN = 3.00;
TC_0012  = 0.12;

V_bl = wingVolume(1.00, 1.00, TC_0012, TC_0012, SEMISPAN);
S_bl = (1.00 + 1.00)/2 * SEMISPAN;

% Deliberate volume margin.  The spec voids any improvement if a constraint
% is violated "even by a small amount", so we do not design at equality.
MARGIN   = 1.02;
V_target = MARGIN * V_bl;

fprintf('BASELINE\n');
fprintf('  V_bl     = %.6f m^3\n', V_bl);
fprintf('  S_half   = %.4f m^2\n', S_bl);
fprintf('  V_target = %.6f m^3  (+%.0f%% margin)\n\n', V_target, (MARGIN-1)*100);

%% ---------------- Candidate definitions --------------------------------
% Each row: name, taper ratio, t/c root, t/c tip, tip twist [deg], comment
cand = {
  'C001', 1.00, 0.12, 0.12,  0.0, 'Camber only (NACA 2412), no taper'
  'C002', 0.45, 0.12, 0.12,  0.0, 'Taper 0.45, symmetric section'
  'C003', 0.45, 0.12, 0.12, -2.0, 'Taper + camber + 2 deg washout'
  'C004', 0.45, 0.15, 0.12, -2.0, 'Thick root 15%, chords shrunk to hold V'
};

nC = size(cand,1);
results = struct([]);

for k = 1:nC
    name   = cand{k,1};
    lambda = cand{k,2};
    tcr    = cand{k,3};
    tct    = cand{k,4};
    twist  = cand{k,5};

    % Solve for the chord that pays for the chosen taper and thickness
    cr = solveRootChord(lambda, tcr, tct, V_target);
    ct = lambda * cr;

    d.name      = name;
    d.cr        = cr;
    d.ct        = ct;
    d.tc_root   = tcr;
    d.tc_tip    = tct;
    d.sweep     = 0.0;
    d.twist_tip = twist;
    d.alpha     = 2.0;    % placeholder, CFD will set the real value
    d.CL        = NaN;    % pending CFD
    d.CD        = NaN;    % pending CFD

    out = checkDesign(d, V_bl, NaN);

    results(k).name = name;
    results(k).cr   = cr;
    results(k).ct   = ct;
    results(k).tcr  = tcr;
    results(k).tct  = tct;
    results(k).tw   = twist;
    results(k).V    = out.V;
    results(k).S    = (cr + ct)/2 * SEMISPAN;
    results(k).pass = out.checks.volume;
end

%% ---------------- Summary table ----------------------------------------
fprintf('\n');
fprintf('=================================================================================\n');
fprintf(' CANDIDATE SUMMARY   (all at %.0f%% volume margin)\n', (MARGIN-1)*100);
fprintf('=================================================================================\n');
fprintf(' %-6s %7s %7s %6s %6s %7s %9s %8s %9s %8s\n', ...
        'case','c_root','c_tip','tc_r','tc_t','twist','V [m^3]','dV %','S [m^2]','dS %');
fprintf('---------------------------------------------------------------------------------\n');
fprintf(' %-6s %7.3f %7.3f %6.2f %6.2f %7.1f %9.5f %8s %9.4f %8s\n', ...
        'C000', 1.000, 1.000, 0.12, 0.12, 0.0, V_bl, '--', S_bl, '--');
for k = 1:nC
    r = results(k);
    fprintf(' %-6s %7.3f %7.3f %6.2f %6.2f %7.1f %9.5f %+7.2f%% %9.4f %+7.2f%%\n', ...
            r.name, r.cr, r.ct, r.tcr, r.tct, r.tw, r.V, ...
            (r.V - V_bl)/V_bl*100, r.S, (r.S - S_bl)/S_bl*100);
end
fprintf('=================================================================================\n');
fprintf(' All candidates satisfy V >= V_bl by construction.\n');
fprintf(' Negative dS means less wetted area, which reduces profile drag\n');
fprintf(' directly because CD is normalized by the FIXED A_ref = 3.00 m^2.\n');
fprintf('=================================================================================\n\n');
