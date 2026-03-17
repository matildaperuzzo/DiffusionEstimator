function J = estimate_jacobian(theta, parameters, h)
    
    if nargin < 3 || isempty(h)
        h = 1e-2;
    end

    K = numel(theta);

    L = length(parameters.dataset_idx);
    J = zeros(L,K); % Initialize the Jacobian matrix

    for k = 1:K
        th_p = theta; th_m = theta;
        th_p(k) = th_p(k) + h;
        th_m(k) = th_m(k) - h;
        y_p = parameters.start_time + run_model(parameters, th_p).times*parameters.dt;
        y_m = parameters.start_time + run_model(parameters, th_m).times*parameters.dt;
        

        J(:, k) = (y_p - y_m) / (2*h); % Finite difference approximation
    end

end