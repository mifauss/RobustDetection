function [Q, I, residuals, c, nit_prox] = multi_lfds_density_band_proximal(f, df, f_param, P_min, P_max, dw, varargin)
% Get least favourable densities for multiple hypotheses under density band
% uncertainty using the proximal version of the algorithm detailed in
% 
% M. Fauß and A. M. Zoubir, "On the Minimization of Convex Functionals of
% Probability Distributions Under Band Constraints," in IEEE Transactions on
% Signal Processing, vol. 66, no. 6, pp. 1425-1437, March, 2018.
%
% INPUT
%     f:                function handle of objective function
%     df:               N dim. cell array of function handles of the partial
%                       derivatives
%     f_param:          additional parameters of f and df
%     Pmin, Pmax:       matrices with density band specifications, each row corresponds 
%                       to one density bound
%     dw:               scalar, grid size parameter
%
% OPTIONAL INPUT
%     varargin
%     | {1}:            verbose {true, false}. Turn display of progress on or off.
%     |                 Defaults to true
%     | {2}:            skip sanity checks {true, false}. Turn sanity checks of the
%     |                 input on or off. Defaults to false.
%     | {3}:            initial lfds, K x N dim. matrix. Provide initial densities for
%     |                 the algorithm. 
%     | {4}:            tolerance, defaults to 1e-6.
%     | {5}:            maximum number of iterations, defaults to 100.
%     | {6}:            maximum number of proximal iterations, defaults to 50.
%
% OUTPUT
%     Q:                K x N dim. matrix. least favorable distributions
%     I:                Objective function evaluated at Q
%     residuals:        N dim. vector of residuals
%     c:                N dim. vector of derivative thresholds
%     nit_prox:         Number of proximal iterations
%
% REMARK
%
% The objective function must be of the form
% 
% f(k, X, f_param) 
%
% and must accept vectors of positive integers as the first argument and N
% x K dim. matrices as the second argument, for example, f(1:K, Pmin). Use
% X(n,k) to access X within the function
%
% The derivative function must be of the form
% 
% df(n, k, X, f_param) 
%
% where the first index indicates the element of X w.r.t. which the partial 
% derivative is taken. Again, use X(n,k) to access X.
%
% See the examples for how to define f and df.

% initialization
[verbose, skip_sanity_check, Q, tol, itmax, itmax_prox] = initialize_bands(P_min, P_max, dw, nargin-6, varargin);

% sanity checks
if ~skip_sanity_check
    sanity_check_bands(P_min, P_max, dw);
end

[N, K] = size(P_min);

% get bounds for c
c = get_c(N, K, df, f_param, P_min, P_max);

% update residuals
residuals = update_residuals(N, K, df, Q, f_param, P_max, P_min, dw, c);

% display progress
nit_prox = 0;
if verbose
    fprintf("\n");
    fprintf("Proximal Iteration | Residual Objective | Residual Densities\n");
    fprintf("-------------------|--------------------|-------------------\n");
    fprintf("%18d |     %.4e     |     %.4e\n", nit_prox, sum(residuals), max(abs(sum(Q,2))*dw-1));
end

% iteratively solve non-proximal problems with augmented df
while sum(residuals) > tol && nit_prox < itmax_prox

        % define proximal objective
        df_prox = @(n, k, X, f_param) df(n, k, X, f_param) + X(n,k) - Q(n, k);

        % solve proximal problem
        [Q, I, ~, c] = multi_lfds_density_band(f, df_prox, f_param, P_min, P_max, dw, false, true, Q, tol, itmax);

        % update residuals
        residuals = update_residuals(N, K, df, Q, f_param, P_max, P_min, dw, c);

        % display progress
        nit_prox = nit_prox+1;
        if verbose
            fprintf("%18d |     %.4e     |     %.4e\n", nit_prox, sum(residuals), max(abs(sum(Q,2))*dw-1));
        end

end


% get inital c and bounds
function [c, c_min, c_max] = get_c(N, K, df, f_param, P_min, P_max)
    c_min = zeros(N, 1); 
    c_max = zeros(N, 1);
    for n=1:N
        c_min(n) = min(df(n, 1:K, P_min(:,1:K), f_param));
        c_max(n) = max(df(n, 1:K, P_max(:,1:K), f_param));
    end
    c = (c_min+c_max)/2;
    c_min = c_min - 0.1;
    c_max = c_max + 0.1;