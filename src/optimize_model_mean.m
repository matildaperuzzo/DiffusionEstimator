
function [error, grad, hessian] = optimize_model_mean(theta, parameters, factor)
    error = optimize_function_mean(theta,parameters);
    if nargout > 1
        f = @(theta) optimize_function_mean(theta, parameters);
        grad = calculateGradient(f, theta, 0.05, factor);
    end
    if nargout > 2
        hessian = calculateHessian(f, theta, 0.05);
    end
end

function result = optimize_function_mean(theta,parameters)
% Evaluate the new theta and update the objective function value
    obj_functions = [];
    sweeps = [-0.005 +0.005];
    obj_functions(1) = run_model(parameters, theta).squared_error;
    for i=1:length(theta)
        for s = 1:length(sweeps)
            new_theta = theta;
            new_theta(i) = theta(i) + sweeps(s);
            obj_functions(end+1) = run_model(parameters, new_theta).squared_error;
        end
    end
    result = mean(obj_functions);
    
end
