function [Q, llr, c, nit] = lfds_density_band(P_min, P_max, dx, varargin)
% Get least favourable densities for two hypotheses under density band uncertainty
% For details see:
%
% M. Fauß and A. M. Zoubir, "Old Bands, New Tracks—Revisiting the Band Model for Robust Hypothesis
% Testing," in IEEE Transactions on Signal Processing, vol. 64, no. 22, pp. 5875-5886, 15 Nov.15, 2016.
%
% INPUT
%   P_min:          2xK vector specifying the lower bounds
%   P_max:          2xK vector specifying the upper bounds
%   dx:             grid size for numerical integraton 
%
% varargin
% | {1}:            display progress, defaults to false
% | {2}:            regularization parameter, defaults to 0.0
% | {3}:            initial guess for Q, defaults to weighted sum of lower
%                   and upper bound  
% | {4}:            tolerance of fixed-point in terms of sup-norm, defaults to 1e-6
% | {5}:            maximum number of iterations, defaults to 100
% | {6}:            order of vector norm used for convergence criterion, defaults to Inf   
%
% OUTPUT
%   Q:              least favorable densities
%   llr:            log-likelihood ratio of q1 and q0, log(q1/q0)
%   c:              clipping constants c0, c1
%   nit:            number of iterations

% add path to helper functions
addpath ../Helper_Functions

% default values
verbose = false;
alpha = 0.0;
Q_init = NaN;
tol = 1e-6;
itmax = 100;
order = Inf;
c0 = 1; c1 = 1;

% sanity checks
if ~is_valid_density_band(P_min, P_max, dx)
    error("Invalid density bands.");
end

% verbosity
if nargin >= 4 && ~isempty(varargin{1})
    verbose = varargin{1};
end

% user defined alpha
if nargin >= 5 && ~isempty(varargin{2})
    if varargin{2} >= 0
        alpha = varargin{2};
    else
        error("'alpha' must be a nonnegative scalar.");
    end
end

% user defined Q
if nargin >= 6 && ~isempty(varargin{3})
    Q_init = varargin{3};
end

% user defined tolerance
if nargin >= 7 && ~isempty(varargin{4})
    if varargin{4} > 0
        tol = varargin{4};
    else
        error('Tolerance must be a positive scalar.');
    end
end

% user defined number of iterations
if nargin >= 8 && ~isempty(varargin{5})
    if varargin{5} > 0
        itmax = varargin{5};
    else
        error('Maximum number of iterations must be a positive scalar.');
    end
end

% user defined vector norm
if nargin >= 9 && ~isempty(varargin{6})
    order = varargin{6};
end

% initialize lfds
Q = set_densities(Q_init, P_min, P_max, dx);

% rename for easier reference
p0_min = P_min(1,:);
p0_max = P_max(1,:);
p1_min = P_min(2,:);
p1_max = P_max(2,:);
q0_new = Q(1,:);
q1_new = Q(2,:);

% initialize counters
dist = Inf;
nit = 0;

% display progress
if verbose
    fprintf("\n");
    fprintf("Iteration | Residual q0 | Residual q1 |  c0  |  c1  \n");
    fprintf("----------|-------------|-------------|------|------\n");
end

% solve fixed-point equation iteratively
while dist > tol && nit < itmax
    
    % assigne updated lfds
    q0 = q0_new;
    q1 = q1_new;
    
    % update q0
    func0 = @(c1) sum(min(p0_max, max(c1*(alpha*q0 + q1), p0_min))) - 1/dx;
    c1 = fzero(func0, c1);
    q0_new = min(p0_max, max(c1*(alpha*q0 + q1), p0_min));
        
    % update q1 using q0_new (!)
    func1 = @(c0) sum(min(p1_max, max(c0*(q0_new + alpha*q1), p1_min))) - 1/dx;
    c0 = fzero(func1, c0);
    q1_new = min(p1_max, max(c0*(q0_new + alpha*q1), p1_min));
    
    % calculate sup-norm
    res0 = vecnorm(q0_new-q0, order);
    res1 = vecnorm(q1_new-q1, order);
    dist = max( res0, res1 );
      
    % count iterations
    nit = nit+1;
    if verbose
         fprintf("%9d |  %.4e |  %.4e | %.2f | %.2f \n", nit, res0, res1, c0, c1);
    end
       
end

% check results
if nit == itmax
    warning([int2str(itmax) ' iterations exeeded, possible numerical problem!']);
elseif vecnorm(q1-q0, order) < tol
    disp('   Overlapping densities!');
end

% scaling factors
c = [c0 c1];

% log-likelihood ratio
llr = log(q1./q0);

% stack lfds
Q = [q0; q1];
