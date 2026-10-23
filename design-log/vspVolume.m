function [V, Vloft] = vspVolume(cr, ct, p_root, p_tip)
%VSPVOLUME  Half-wing volume the way the AI tool measures it (volume_val).
%
%   [V, Vloft] = vspVolume(cr, ct, p_root, p_tip)
%
%   Inputs
%     cr, ct          root and tip chord [m]
%     p_root, p_tip   NACA 4-digit strings, e.g. 'NACA 2415'
%
%   Outputs
%     V      volume as the AI tool reports it   [m^3]
%     Vloft  exact volume of the lofted wing    [m^3]
%
%   WHY THIS EXISTS (week 6)
%   wingVolume.m disagreed with the AI tool's OpenVSP volume by -1.4% on
%   C002 and +4.4% on C004. The constraint V >= V_bl is strict, so the
%   check has to use the same volume the CFD workflow reports. Reading the
%   agent's case files showed how volume_val is computed:
%     - script_run_dafoam.py: DAFoamVSPVolume(..., slice_dir="y", n_slices=10)
%       -> 10 plane slices along the span, area x spacing (midpoint rule)
%     - wing.vsp3: CapUMaxOption = 2 -> ROUND tip cap, which stretches the
%       slicing span past 3.00 m by about half the tip thickness
%     - wing.vsp3: the two sections are lofted LINEARLY in physical
%       coordinates, so thickness t = (t/c)*c varies linearly, not t/c
%       (wingVolume.m assumed linear t/c, which is wrong when the root and
%       tip airfoils have different t/c, as in C004)
%   Section areas per unit chord^2 were read from the XSec "Area" values
%   in the C000, C002 and C004 wing.vsp3 files.
%
%   ACCURACY vs the tool's volume_val
%     C000  +0.14%     C002  +0.15%     C004  -1.9%  (this function reads LOW)
%   Reading low is the safe direction for V >= V_bl. Size designs with a
%   margin of at least +1% and always confirm the tool's own volume_val.
%
%   AerE 3620 Project - Design Lead tooling (week 6)

SEMISPAN = 3.00;
NSLICE   = 10;             % n_slices in the agent's DAFoamVSPVolume call

[ar, tcr] = sectionArea(p_root);
[at, tct] = sectionArea(p_tip);

% linear loft: chord linear, thickness-scaled area term linear
c  = @(y) cr + (ct - cr) .* (y / SEMISPAN);
L  = @(y) cr*ar + (ct*at - cr*ar) .* (y / SEMISPAN);
A  = @(y) c(y) .* L(y) .* (y <= SEMISPAN);        % sectional area [m^2]

% slicing span includes the round tip cap (radius = half tip thickness)
Lspan = SEMISPAN + 0.5 * tct * ct;
dy    = Lspan / NSLICE;
ys    = ((1:NSLICE) - 0.5) * dy;                   % midpoint slices
V     = sum(A(ys)) * dy;

% exact loft volume, no cap, for reference
yy    = linspace(0, SEMISPAN, 2001);
Vloft = trapz(yy, A(yy));

end

% -------------------------------------------------------------------------
function [a, tc] = sectionArea(code)
%SECTIONAREA  Area of a unit-chord section and its actual t/c in the AI tool.
%   Values measured from the agent's wing.vsp3 files (CST-fitted sections).
%   Other NACA 4-digit codes fall back to a = 0.6816 * t/c.
digits = regexp(code, '\d{4}', 'match', 'once');
switch digits
    case '0012', a = 0.080813;  tc = 0.11916;
    case '2412', a = 0.081789;  tc = 0.11996;
    case '2415', a = 0.102248;  tc = 0.14993;
    otherwise
        tc = str2double(digits(3:4)) / 100;
        a  = 0.6816 * tc;
end
end
