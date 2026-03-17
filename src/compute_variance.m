function out = compute_variance(theta, parameters)

    K = numel(theta);
    L = length(parameters.dataset_idx);
    
    Y_hat = parameters.start_time + run_model(parameters, theta).times*parameters.dt;
    Y = parameters.dataset_bp;

    e = Y - Y_hat';
    J = estimate_jacobian(theta, parameters);

    Gamma = (J' * J) / L;

    if rcond(Gamma) < 1e-10
        warning('Gamma is ill-conditioned; using pinv.');
        Ginv = pinv(Gamma);
    else
        Ginv = Gamma \ eye(K);
    end

    % Heteroskedastic site-i.i.d. meat
    Meat_iid = (J' * diag(e.^2) * J) /L;
    V_iid = Ginv * Meat_iid * Ginv;
    se_iid = sqrt(diag(V_iid) / L);
    sigma2 = (e' * e) / max(L - K, 1);
    V_homo = sigma2 * Ginv;

    se_homo = sqrt(diag(V_homo) / L);

    out = struct();

    out.resid = e;
    out.J = J;
    out.Gamma = Gamma;
    out.Meat_iid = Meat_iid;
    out.V_iid = V_iid;
    out.se_iid = se_iid;
    out.sigma2 = sigma2;
    out.se_homo = se_homo;
    out.V_homo = V_homo;

end