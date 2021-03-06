function Q = set_densities(Q_init, P_min, P_max, dx)

[N, K] = size(P_min);
Q = zeros(N, K);

if ~isscalar(Q_init)
    for n=1:N
        if any(isnan(Q_init(n,:)))
            a = (1 / dx - sum(P_min(n,:))) / (sum(P_max(n,:)) - sum(P_min(n,:)));
            Q(n,:) = (1 - a)*P_min(n,:) + a*P_max(n,:);
        elseif all(Q_init(n,:) >= 0.0)
            Q(n,:) = Q_init(n,:);
        else
            error("User supplied initialization for q is invalid.");
        end
    end
else
    a = (1 / dx - sum(P_min, 2)) ./ (sum(P_max, 2) - sum(P_min, 2));
    Q = (1 - repmat(a, 1, K)).*P_min + repmat(a, 1, K).*P_max;
end