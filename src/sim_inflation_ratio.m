function rho = sim_inflation_ratio(theta,parameters)

    L = length(parameters.dataset_idx);
    N = parameters.n;
    Y_draws = zeros(L, N);
    Y_obs = parameters.dataset_bp;
    parameters.n = 1;

    for n = 1:N
        result = run_model(parameters, theta);
        parameters.random = "shuffle";
        Y_draws(:, n) = parameters.start_time + result.times*parameters.dt;
    end

    Y_hat = mean(Y_draws, 2);
    total_var = mean((Y_obs - Y_hat).^2);
    sim_var_avgdiag = mean(var(Y_draws, 1, 2)) / N;  % population normalization
    rho = sim_var_avgdiag / total_var;

    fprintf('Simulation inflation ratio (avg diagonal): %.3f\n', rho);
end
