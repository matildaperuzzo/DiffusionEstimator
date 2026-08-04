function [error, grad, hessian] = optimize_model(theta, parameters, factor, model)
    if nargin>3
        if model == "monte carlo"
            result = run_model(parameters, theta);
            error = result.squared_error;
            f = @(theta) run_model(parameters, theta).squared_error;
        elseif model == "kpp"
            result = run_model_kpp(parameters, theta);
            error = result.squared_error;
            f = @(theta) run_model_kpp(parameters, theta).squared_error;
        elseif model == "fast marching"
            result = run_model_fast_marching(parameters, theta);
            error = result.squared_error;
            f = @(theta) run_model_fast_marching(parameters, theta).squared_error;
        end
    end
    if nargout > 1
        
        grad = calculateGradient(f, theta, 0.05, factor);
    end
    if nargout > 2
        hessian = calculateHessian(f, theta, 0.05);
    end
end
