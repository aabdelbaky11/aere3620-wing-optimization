function alphaNext = trimAlpha(alpha1, CL1, alpha2, CL2, CLtarget)
%TRIMALPHA  Secant-method step to find the alpha that gives CL = CLtarget.
%
%   alphaNext = trimAlpha(alpha1, CL1, alpha2, CL2)
%   alphaNext = trimAlpha(alpha1, CL1, alpha2, CL2, CLtarget)
%
%   Root-finding problem (lecture 09):  g(alpha) = CL(alpha) - CLtarget = 0
%   Each g evaluation is one CFD run, so we use the secant method: it needs
%   no derivative and CL(alpha) is close to linear below stall, so it
%   lands within tolerance in one or two steps.
%
%   Procedure for every case the workflow leads run:
%     1. Run CFD at alpha1 = the llScreen estimate in the request file
%     2. Run CFD at alpha2 = alpha1 + 1 deg
%     3. alpha3 = trimAlpha(alpha1, CL1, alpha2, CL2)  -> run CFD at alpha3
%     4. If |CL3 - 0.4| > 1e-3, repeat with (alpha2, CL2, alpha3, CL3)
%   Report the final alpha with CL >= 0.4 (the constraint is strict).
%
%   AerE 3620 Project - Design Lead tooling (week 3)

if nargin < 5, CLtarget = 0.40; end

g1 = CL1 - CLtarget;
g2 = CL2 - CLtarget;

if abs(g2 - g1) < 1e-8
    error('trimAlpha:flat', 'CL1 and CL2 are equal; pick two different alphas.');
end

alphaNext = alpha2 - g2 * (alpha2 - alpha1) / (g2 - g1);

if alphaNext < 0 || alphaNext > 10
    warning('trimAlpha:bound', ...
        'Predicted alpha %.3f deg is outside the 0-10 deg bound.', alphaNext);
end

fprintf('  secant: (%.3f, %.4f), (%.3f, %.4f)  ->  next alpha = %.3f deg\n', ...
        alpha1, CL1, alpha2, CL2, alphaNext);
end
