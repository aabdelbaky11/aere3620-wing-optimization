function cr = solveRootChord(lambda, tc_root, tc_tip, V_target)
%SOLVEROOTCHORD  Root chord that meets a target wing volume at a given taper ratio.
%
%   cr = solveRootChord(lambda, tc_root, tc_tip, V_target)
%
%   Inputs
%     lambda    taper ratio ct/cr  (1.0 = untapered)
%     tc_root   root thickness-to-chord ratio
%     tc_tip    tip thickness-to-chord ratio
%     V_target  required half-wing volume [m^3]
%
%   Output
%     cr        root chord [m] giving exactly V = V_target
%
%   Tip chord is then ct = lambda * cr.
%
%   Use this to generate candidate geometries that satisfy the volume
%   constraint BY CONSTRUCTION, instead of guessing chords and checking
%   afterward.  Pick the taper ratio and thickness you want on
%   aerodynamic grounds; this returns the chord that pays for it.
%
%   AerE 3620 Project - Design Lead tooling

SEMISPAN = 3.00;

f = @(c) wingVolume(c, lambda*c, tc_root, tc_tip, SEMISPAN) - V_target;

cr = fzero(f, [0.2, 3.0]);

% Warn if the resulting tip chord leaves the Table 1 bounds
ct = lambda * cr;
if ct < 0.2 || ct > 3.0
    warning('solveRootChord:tipBound', ...
        'Resulting tip chord %.3f m is outside the 0.2-3.0 m bound.', ct);
end
if cr < 0.2 || cr > 3.0
    warning('solveRootChord:rootBound', ...
        'Resulting root chord %.3f m is outside the 0.2-3.0 m bound.', cr);
end

end
