function V = wingVolume(cr, ct, tc_root, tc_tip, semispan, K)
%WINGVOLUME  Half-wing volume for a linearly tapered, linearly lofted wing.
%
%   V = wingVolume(cr, ct, tc_root, tc_tip, semispan)
%   V = wingVolume(cr, ct, tc_root, tc_tip, semispan, K)
%
%   Inputs
%     cr        root chord [m]
%     ct        tip chord [m]
%     tc_root   root thickness-to-chord ratio (0.12 for NACA 0012)
%     tc_tip    tip thickness-to-chord ratio
%     semispan  b/2 [m]   (fixed at 3.00 for AerE 3620 project)
%     K         airfoil area coefficient (default 0.685)
%
%   Output
%     V         half-wing volume [m^3]
%
%   ASSUMPTIONS (state these in the report)
%     1. Sectional area is A = K * (t/c) * c^2.  For NACA 4-digit sections
%        K = 0.685 to within about 0.5%.  Camber does not change the
%        thickness distribution, so K is the same for NACA 2412 as for 0012.
%     2. Chord and thickness ratio vary LINEARLY from root to tip.
%     3. Sweep and twist do not change sectional area, so they do not
%        appear here.  Sweep shears sections spanwise; twist rotates them.
%        Neither alters the area of any section.
%
%   Closed form when tc_root == tc_tip == tc:
%     V = K * tc * (b/2) * (cr^2 + cr*ct + ct^2) / 3
%
%   AerE 3620 Project - Design Lead tooling

if nargin < 6 || isempty(K)
    K = 0.685;
end

% Numerical integration over the normalized span coordinate eta = y/(b/2)
n   = 2001;
eta = linspace(0, 1, n);

c  = cr      + (ct      - cr     ) .* eta;   % chord distribution [m]
tc = tc_root + (tc_tip  - tc_root) .* eta;   % thickness ratio distribution

A = K .* tc .* c.^2;                          % sectional area [m^2]

V = trapz(eta, A) * semispan;                 % [m^3]

end
