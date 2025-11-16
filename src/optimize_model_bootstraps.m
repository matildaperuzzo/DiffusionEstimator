function [error, grad, hessian] = optimize_model_bootstraps(theta, parameters, data, factor)
    result = run_model(parameters, theta, data);
    error = result.squared_error;
    if nargout > 1
        f = @(theta) run_model(parameters, theta, data).squared_error;
        grad = calculateGradient(f, theta, 0.01, factor);
    end
    if nargout > 2
        hessian = calculateHessian(f, theta, 0.01);
    end
end
