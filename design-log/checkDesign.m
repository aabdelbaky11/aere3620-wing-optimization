function out = checkDesign(d, V_bl, CD_bl)
%CHECKDESIGN  Verify every Table 1 constraint for one candidate wing design.
%
%   out = checkDesign(d, V_bl, CD_bl)
%
%   d is a struct with fields:
%     .name      case ID string, e.g. 'C003'
%     .cr        root chord [m]
%     .ct        tip chord [m]
%     .tc_root   root t/c
%     .tc_tip    tip t/c
%     .sweep     sweep angle [deg]
%     .twist_tip tip twist [deg]
%     .alpha     angle of attack [deg]
%     .CL        lift coefficient  (NaN if not yet evaluated)
%     .CD        drag coefficient  (NaN if not yet evaluated)
%
%   V_bl   baseline half-wing volume [m^3]
%   CD_bl  baseline drag coefficient (NaN until the baseline run returns)
%
%   Prints a pass/fail table and returns a struct of results.
%
%   AerE 3620 Project - Design Lead tooling

SEMISPAN = 3.00;   % fixed by the project spec

if nargin < 3, CD_bl = NaN; end

% ---- geometry ------------------------------------------------------------
V = wingVolume(d.cr, d.ct, d.tc_root, d.tc_tip, SEMISPAN);

% ---- bound checks (Table 1) ---------------------------------------------
chk = struct();
chk.alpha_bound = (d.alpha >=   0) && (d.alpha <=  10);
chk.sweep_bound = (d.sweep >= -10) && (d.sweep <=  10);
chk.twist_bound = (d.twist_tip >= -10) && (d.twist_tip <= 10);
chk.cr_bound    = (d.cr >= 0.2) && (d.cr <= 3.0);
chk.ct_bound    = (d.ct >= 0.2) && (d.ct <= 3.0);

% ---- inequality constraints ---------------------------------------------
chk.lift   = ~isnan(d.CL) && (d.CL >= 0.4);
chk.volume = (V >= V_bl);

% ---- improvement ---------------------------------------------------------
if ~isnan(CD_bl) && ~isnan(d.CD) && CD_bl > 0
    improvement = (CD_bl - d.CD) / CD_bl * 100;
else
    improvement = NaN;
end

allPass = chk.alpha_bound && chk.sweep_bound && chk.twist_bound && ...
          chk.cr_bound && chk.ct_bound && chk.lift && chk.volume;

% ---- report --------------------------------------------------------------
fprintf('\n=============================================\n');
fprintf(' Constraint check: case %s\n', d.name);
fprintf('=============================================\n');
fprintf('  cr = %.4f m    ct = %.4f m\n', d.cr, d.ct);
fprintf('  t/c root = %.4f   t/c tip = %.4f\n', d.tc_root, d.tc_tip);
fprintf('  sweep = %+.2f deg   tip twist = %+.2f deg\n', d.sweep, d.twist_tip);
fprintf('  alpha = %.3f deg\n', d.alpha);
fprintf('---------------------------------------------\n');
printRow('0 <= alpha <= 10',      chk.alpha_bound);
printRow('-10 <= sweep <= 10',    chk.sweep_bound);
printRow('-10 <= twist_tip <= 10',chk.twist_bound);
printRow('0.2 <= cr <= 3.0',      chk.cr_bound);
printRow('0.2 <= ct <= 3.0',      chk.ct_bound);
fprintf('---------------------------------------------\n');
if isnan(d.CL)
    fprintf('  %-26s  %s\n', 'CL >= 0.4', 'PENDING CFD');
else
    printRow(sprintf('CL >= 0.4  (CL = %.4f)', d.CL), chk.lift);
end
fprintf('  V       = %.6f m^3\n', V);
fprintf('  V_bl    = %.6f m^3\n', V_bl);
fprintf('  margin  = %+.6f m^3  (%+.2f%%)\n', V - V_bl, (V-V_bl)/V_bl*100);
printRow('V >= V_bl', chk.volume);
fprintf('---------------------------------------------\n');
if isnan(improvement)
    fprintf('  CD improvement:  PENDING CFD\n');
else
    fprintf('  CD = %.6f   CD_bl = %.6f\n', d.CD, CD_bl);
    fprintf('  Design improvement: %.2f%%\n', improvement);
end
fprintf('---------------------------------------------\n');
if allPass
    fprintf('  VERDICT: ALL CONSTRAINTS SATISFIED\n');
elseif isnan(d.CL)
    fprintf('  VERDICT: geometry OK, awaiting CFD for CL\n');
else
    fprintf('  VERDICT: *** CONSTRAINT VIOLATED - DESIGN INVALID ***\n');
end
fprintf('=============================================\n\n');

% ---- pack output ---------------------------------------------------------
out.name        = d.name;
out.V           = V;
out.V_margin    = V - V_bl;
out.improvement = improvement;
out.checks      = chk;
out.allPass     = allPass;

end

% -------------------------------------------------------------------------
function printRow(label, tf)
if tf
    fprintf('  %-26s  PASS\n', label);
else
    fprintf('  %-26s  FAIL\n', label);
end
end
