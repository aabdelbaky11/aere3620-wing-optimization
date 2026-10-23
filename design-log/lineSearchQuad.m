function [xmin, fmin, info] = lineSearchQuad(x, f, xlo, xhi)
%LINESEARCHQUAD  One quadratic-interpolation step of a line search.
%
%   [xmin, fmin, info] = lineSearchQuad(x, f)
%   [xmin, fmin, info] = lineSearchQuad(x, f, xlo, xhi)
%
%   Inputs
%     x         three trial points along the search direction (any order)
%               e.g. taper ratios [0.45 0.35 0.30]
%     f         objective at those points, e.g. CD from CFD
%     xlo, xhi  optional bounds on the step (default: no bounds)
%
%   Outputs
%     xmin      minimizer of the parabola through the three points
%               (clipped to [xlo, xhi])
%     fmin      parabola value at xmin (a PREDICTION - needs a CFD run)
%     info      .a       parabola coefficients, f = a(1) + a(2)x + a(3)x^2
%               .bracketed   true if the lowest point is in the middle,
%                            so the minimum is trapped (Lecture 11, Phase I)
%               .convex      true if a(3) > 0 (a real minimum exists)
%               .next        suggested next trial point
%
%   Why not golden section: Lecture 11 points out that interval-reducing
%   searches need many function evaluations, and each evaluation here is a
%   full CFD run. Fitting a parabola through three CFD points (polynomial
%   interpolation, Arora Sec. 8.2 / Martins & Ning Sec. 4.3) lands near
%   the minimum of a smooth f in one step.
%
%   AerE 3620 Project - Design Lead tooling (week 6)

if nargin < 3, xlo = -Inf; end
if nargin < 4, xhi =  Inf; end

x = x(:);  f = f(:);
if numel(x) ~= 3 || numel(f) ~= 3 || any(isnan(f))
    error('lineSearchQuad:input', 'Need exactly three points with known f.');
end
[x, i] = sort(x);  f = f(i);

% f = a1 + a2*x + a3*x^2 through the three points
a = [ones(3,1), x, x.^2] \ f;

info.a         = a;
info.convex    = a(3) > 0;
info.bracketed = f(2) < f(1) && f(2) < f(3);

if info.convex
    xmin = -a(2) / (2*a(3));
else
    % no interior minimum: step to the better end (expand the search)
    [~, k] = min(f);
    xmin = x(k) + (x(k) - x(2));
end
xmin = min(max(xmin, xlo), xhi);
fmin = a(1) + a(2)*xmin + a(3)*xmin^2;

% next trial point: the parabola minimum if it is new, otherwise stop
if min(abs(xmin - x)) < 0.01 * (x(3) - x(1))
    info.next = NaN;          % converged: minimum sits on a tested point
else
    info.next = xmin;
end

end
