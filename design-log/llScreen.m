function r = llScreen(d)
%LLSCREEN  Low-fidelity drag screening of one candidate wing at CL = 0.4.
%
%   r = llScreen(d)
%
%   Purpose: rank candidate designs BEFORE spending CFD runs on them, and
%   give the workflow leads a starting angle of attack for each case.
%   This is NOT a substitute for CFD. It only captures:
%     - induced drag, from Prandtl lifting-line theory (Glauert series)
%     - skin-friction/form drag, from a flat-plate strip estimate
%   It does NOT capture camber effects on profile drag, pressure drag
%   changes with alpha, tip-vortex roll-up, or viscous lift-curve losses.
%
%   d is a struct with fields (same convention as checkDesign.m):
%     .cr, .ct          root and tip chord [m]
%     .p_root, .p_tip   NACA 4-digit strings, e.g. 'NACA 2412'
%     .twist_tip        tip twist [deg] (root twist fixed at 0)
%
%   Output r:
%     .alpha   alpha [deg] that gives CL = 0.4 (on A_ref = 3.00 m^2)
%     .e       span efficiency factor
%     .CDi     induced drag coefficient   (on A_ref)
%     .CD0     skin-friction + form drag  (on A_ref)
%     .CD      CDi + CD0
%     .S       actual half-wing planform area [m^2]
%
%   AerE 3620 Project - Design Lead tooling (week 3)

% ---- fixed project quantities ------------------------------------------
SEMISPAN = 3.00;            % b/2 [m]
AREF     = 3.00;            % reference area [m^2]
CL_REQ   = 0.40;            % lift constraint
MACH     = 0.30;
RE_PER_M = 5.0e6;           % Re based on 1.00 m chord
N        = 40;              % number of Glauert terms / control points

% 2D lift slope with Prandtl-Glauert correction
a0 = 2*pi / sqrt(1 - MACH^2);

% ---- airfoil data at root and tip ---------------------------------------
[aL0r, tcr] = naca4(d.p_root);
[aL0t, tct] = naca4(d.p_tip);

% ---- lifting-line setup (symmetric wing, odd terms only) ----------------
b   = 2*SEMISPAN;
th  = linspace(pi/2, 0, N+1);  th = th(1:N)';   % control points, root -> tip
eta = cos(th);                                  % |y| / (b/2)
n   = 2*(1:N) - 1;                              % odd harmonics 1,3,5,...

c    = d.cr + (d.ct - d.cr) .* eta;             % chord at each station
S    = SEMISPAN * (d.cr + d.ct);                % FULL-wing planform area
AR   = b^2 / S;

M = sin(th*n) .* (4*b ./ (a0*c)) + sin(th*n) .* (n ./ sin(th));

% Effective incidence = alpha + twist(y) - alphaL0(y)
twist = deg2rad(d.twist_tip) .* eta;
aL0   = aL0r + (aL0t - aL0r) .* eta;

A_fix   = M \ (twist - aL0);     % response to twist/camber at alpha = 0
A_alpha = M \ ones(N,1);         % response per radian of alpha

% Convert planform-based CL to the fixed reference area
k = (S/2) / AREF;
CL_fix   = pi*AR*A_fix(1)   * k;
CL_alpha = pi*AR*A_alpha(1) * k;

alpha = (CL_REQ - CL_fix) / CL_alpha;   % [rad]
A     = A_fix + alpha*A_alpha;

CDi = pi*AR*sum(n(:) .* A.^2) * k;
e   = A(1)^2 / sum(n(:) .* A.^2);

% ---- skin friction + form factor strip estimate -------------------------
yy  = linspace(0, 1, 2001);
cc  = d.cr + (d.ct - d.cr) .* yy;
tc  = tcr  + (tct  - tcr ) .* yy;
Cf  = 0.455 ./ (log10(RE_PER_M .* cc)).^2.58;    % turbulent flat plate
FF  = 1 + 2*tc + 60*tc.^4;                       % Hoerner form factor
cd  = 2 .* Cf .* FF;                             % both surfaces
CD0 = trapz(yy, cd .* cc) * SEMISPAN / AREF;

% ---- pack ---------------------------------------------------------------
r.alpha = rad2deg(alpha);
r.e     = e;
r.CDi   = CDi;
r.CD0   = CD0;
r.CD    = CDi + CD0;
r.S     = S/2;

end

% -------------------------------------------------------------------------
function [aL0, tc] = naca4(code)
%NACA4  Zero-lift angle [rad] (thin-airfoil theory) and t/c of a NACA 4-digit.
digits = regexp(code, '\d{4}', 'match', 'once');
m  = str2double(digits(1)) / 100;
p  = str2double(digits(2)) / 10;
tc = str2double(digits(3:4)) / 100;

if m == 0
    aL0 = 0;
    return
end

% alphaL0 = -(1/pi) * integral_0^pi  dz/dx * (cos(t) - 1) dt
t  = linspace(0, pi, 4001);
x  = (1 - cos(t)) / 2;
dz = zeros(size(x));
fwd = x <  p;
dz(fwd)  = 2*m/p^2       * (p - x(fwd));
dz(~fwd) = 2*m/(1-p)^2   * (p - x(~fwd));
aL0 = -trapz(t, dz .* (cos(t) - 1)) / pi;
end
