% Example for least favorable densities under band uncertainty

% Sample space
dx = 0.01;
x = -8:dx:8;

% nominal densities
p0 = normpdf(x, -2, 2);
p1 = normpdf(x, 1, 1);
P = [p0; p1];

% LFDs under density band uncertainty

% bands
P_min = 0.8 * P;
P_max = 1.2 * P;

% solve for LFDs
[Q, llr, c, nit] = lfds_density_band(P_min, P_max, dx, true);

% plot lfds
figure;
plot(x, Q(1,:), x, Q(2,:))
legend('q_0', 'q_1')
title('Density band uncertainty')

% plot log-likelihood ratio
figure;
plot(x, llr)
legend('log-likelihood ratio')
title('Density band uncertainty')

% LFDs under 10% and 15% contamination (outliers)
 
eps = [0.1, 0.15];
 
% solve for LFDs
[Q, llr, c] = lfds_outliers(P, dx, eps, true, 0, P);

% plot lfds
figure;
plot(x, Q(1,:), x, Q(2,:))
legend('q_0', 'q_1')
title('Epsilon Contamination')

% plot log-likelihood ratio
figure;
plot(x, llr)
legend('log-likelihood ratio')
title('Epsilon Contamination')
