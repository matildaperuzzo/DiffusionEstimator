function [best_theta, best_result, info] = grad_descent_sweep(theta0, parameters, options)
%GRAD_DESCENT_SWEEP Gradient descent with nested sweeps over gradient and search steps.
%   [best_theta, best_result, info] = grad_descent_sweep(theta0, parameters, options)
%   evaluates the gradient at the current point using calculateGradient,
%   tries search steps from large to small, accepts the first improving move,
%   and repeats until no improving move is found for a given gradient step.
%   options.objective_function determines how candidate points are scored.
%   options.result_function determines what best_result contains. These can
%   be different, so callers should treat info.best_error as the optimizer's
%   authoritative objective value and best_result as contextual output.

    if nargin < 3
        options = struct();
    end

    objective_function = get_opt(options, 'objective_function', @(theta) optimize_model(theta, parameters, 1));
    gradient_objective = get_opt(options, 'gradient_objective', objective_function);
    result_function = get_opt(options, 'result_function', @(theta) run_model(parameters, theta));
    gradient_steps = get_opt(options, 'gradient_steps', fliplr([0.01 0.02 0.05 0.1]));
    steps = get_opt(options, 'steps', fliplr([0.002 0.01 0.02 0.05 0.15]));
    verbose = get_opt(options, 'verbose', false);
    debug = get_opt(options, 'debug', false);

    theta = theta0(:)';
    value = objective_function(theta);

    gradient_steps = sort(reshape(gradient_steps, 1, []), 'descend');
    steps = sort(reshape(steps, 1, []), 'descend');

    history = struct();
    history.old_theta = zeros(0, numel(theta));
    history.new_theta = zeros(0, numel(theta));
    history.gradient_step = zeros(0, 1);
    history.step_size = zeros(0, 1);
    history.values = value;
    history.iteration = zeros(0, 1);
    history.attempt_iteration = zeros(0, 1);
    history.attempt_old_theta = zeros(0, numel(theta));
    history.attempt_new_theta = zeros(0, numel(theta));
    history.attempt_gradient = zeros(0, numel(theta));
    history.attempt_gradient_step = zeros(0, 1);
    history.attempt_step_size = zeros(0, 1);
    history.attempt_old_value = zeros(0, 1);
    history.attempt_new_value = zeros(0, 1);
    history.attempt_accepted = false(0, 1);

    move_count = 0;
    iteration_count = 0;

    for grad_idx = 1:numel(gradient_steps)
        grad_step = gradient_steps(grad_idx);
        if verbose
            fprintf('Outer loop %d/%d: gradient step = %.6g\n', ...
                grad_idx, numel(gradient_steps), grad_step);
        end

        while true
            iteration_count = iteration_count + 1;
            grad = calculateGradient(gradient_objective, theta, grad_step, 1);
            grad = grad(:)';
            grad_norm = norm(grad);

            if verbose
                fprintf('  Iteration %d theta=%s value=%.12g |g|=%.12g\n', ...
                    iteration_count, mat2str(theta, 6), value, grad_norm);
            end

            if ~isfinite(grad_norm) || grad_norm == 0
                break;
            end

            direction = -grad / grad_norm;
            found_improvement = false;

            for step_idx = 1:numel(steps)
                step_size = steps(step_idx);
                candidate_theta = theta + step_size * direction;
                candidate_value = objective_function(candidate_theta);

                if debug
                    history.attempt_iteration(end + 1, 1) = iteration_count;
                    history.attempt_old_theta(end + 1, :) = theta;
                    history.attempt_new_theta(end + 1, :) = candidate_theta;
                    history.attempt_gradient(end + 1, :) = grad;
                    history.attempt_gradient_step(end + 1, 1) = grad_step;
                    history.attempt_step_size(end + 1, 1) = step_size;
                    history.attempt_old_value(end + 1, 1) = value;
                    history.attempt_new_value(end + 1, 1) = candidate_value;
                    history.attempt_accepted(end + 1, 1) = false;
                end

                if verbose
                    fprintf('    Trial %d/%d step=%.6g value=%.12g\n', ...
                        step_idx, numel(steps), step_size, candidate_value);
                end

                if candidate_value < value
                    history.old_theta(end + 1, :) = theta;
                    history.new_theta(end + 1, :) = candidate_theta;
                    history.gradient_step(end + 1, 1) = grad_step;
                    history.step_size(end + 1, 1) = step_size;
                    history.values(end + 1, 1) = candidate_value;
                    history.iteration(end + 1, 1) = iteration_count;

                    if debug
                        history.attempt_accepted(end, 1) = true;
                    end

                    theta = candidate_theta;
                    value = candidate_value;
                    move_count = move_count + 1;
                    found_improvement = true;
                    break;
                end
            end

            if ~found_improvement
                break;
            end
        end
    end

    best_theta = theta;
    best_result = result_function(best_theta);

    info = struct();
    info.best_theta = best_theta;
    info.best_error = value;
    info.n_accepted_moves = move_count;
    info.gradient_steps = gradient_steps;
    info.steps = steps;
    info.history = history;
end

function val = get_opt(options, field_name, default_val)
    if isfield(options, field_name)
        val = options.(field_name);
    else
        val = default_val;
    end
end
