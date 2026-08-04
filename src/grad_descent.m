function [best_theta, best_result, info] = grad_descent(theta0, parameters, options)
%GRAD_DESCENT Multi-start wrapper around the sweep-based gradient descent.
%   Uses the variance ellipse around theta0 to generate separated starts,
%   runs sweep descent from each one, and returns the best final point.

    if nargin < 3
        options = struct();
    end

    theta0 = theta0(:)';
    n_starts = get_opt(options, 'n_starts', 6);
    variance_scale = get_opt(options, 'variance_scale', 2.0);
    use_parallel = get_opt(options, 'use_parallel', true);
    start_point_function = get_opt(options, 'start_point_function', []);

    if isempty(start_point_function)
        [start_points, start_meta] = default_start_points(theta0, parameters, n_starts, variance_scale);
    else
        [start_points, start_meta] = start_point_function(theta0, parameters, options);
    end

    start_thetas = zeros(n_starts, numel(theta0));
    final_thetas = zeros(n_starts, numel(theta0));
    final_errors = inf(n_starts, 1);
    final_results = cell(n_starts, 1);
    histories = cell(n_starts, 1);

    can_parallel = use_parallel && has_parallel_toolbox();
    if can_parallel
        pool = gcp('nocreate');
        if isempty(pool)
            parpool('local', n_starts);
        elseif pool.NumWorkers ~= n_starts
            delete(pool);
            parpool('local', n_starts);
        end
        
        parfor start_idx = 1:n_starts
            start_theta = start_points(start_idx, :);
            [theta_i, result_i, info_i] = grad_descent_sweep(start_theta, parameters, options);
            start_thetas(start_idx, :) = start_theta;
            final_thetas(start_idx, :) = theta_i;
            final_errors(start_idx) = info_i.best_error;
            final_results{start_idx} = result_i;
            histories{start_idx} = info_i.history;
        end
    else
        for start_idx = 1:n_starts
            start_theta = start_points(start_idx, :);
            [theta_i, result_i, info_i] = grad_descent_sweep(start_theta, parameters, options);
            start_thetas(start_idx, :) = start_theta;
            final_thetas(start_idx, :) = theta_i;
            final_errors(start_idx) = info_i.best_error;
            final_results{start_idx} = result_i;
            histories{start_idx} = info_i.history;
        end
    end

    [~, best_idx] = min(final_errors);
    best_theta = final_thetas(best_idx, :);
    best_result = final_results{best_idx};

    info = struct();
    info.best_theta = best_theta;
    info.best_error = final_errors(best_idx);
    info.best_start_index = best_idx;
    info.start_thetas = start_thetas;
    info.final_thetas = final_thetas;
    info.final_errors = final_errors;
    info.start_meta = start_meta;
    info.histories = histories;
    info.used_parallel = can_parallel;
end

function val = get_opt(options, field_name, default_val)
    if isfield(options, field_name)
        val = options.(field_name);
    else
        val = default_val;
    end
end

function start_points = sample_start_points_on_ellipse(center, axes_lengths, n_points)
    n_dims = numel(center);
    center = reshape(center, 1, []);
    axes_lengths = reshape(axes_lengths, 1, []);

    if n_dims == 1
        offsets = linspace(-axes_lengths(1), axes_lengths(1), n_points)';
        start_points = center + offsets;
        return;
    end

    min_angle = min(pi / 3, 0.7 * pi / max(n_points, 2));
    max_tries = 5000;
    directions = zeros(n_points, n_dims);

    for point_idx = 1:n_points
        accepted = false;
        for try_idx = 1:max_tries
            candidate = randn(1, n_dims);
            candidate_norm = norm(candidate);
            if candidate_norm == 0
                continue;
            end
            candidate = candidate / candidate_norm;

            if point_idx == 1
                accepted = true;
            else
                cos_angles = directions(1:point_idx - 1, :) * candidate';
                cos_angles = min(max(cos_angles, -1), 1);
                accepted = all(acos(cos_angles) >= min_angle);
            end

            if accepted
                directions(point_idx, :) = candidate;
                break;
            end
        end

        if ~accepted
            directions = fallback_directions(n_points, n_dims);
            break;
        end
    end

    start_points = center + directions .* axes_lengths;
end

function [start_points, meta] = default_start_points(theta0, parameters, n_starts, variance_scale)
    variance_info = compute_variance(theta0, parameters);
    ellipse_axes = reshape(variance_info.se_homo, 1, []);
    ellipse_axes = max(ellipse_axes, 1e-3);
    start_axes = variance_scale * ellipse_axes;
    start_points = sample_start_points_on_ellipse(theta0, start_axes, n_starts);

    meta = struct();
    meta.center = theta0;
    meta.ellipse_axes = ellipse_axes;
    meta.start_axes = start_axes;
    meta.source = 'compute_variance';
end

function directions = fallback_directions(n_points, n_dims)
    directions = zeros(n_points, n_dims);
    basis = [eye(n_dims); -eye(n_dims)];
    for idx = 1:n_points
        directions(idx, :) = basis(mod(idx - 1, size(basis, 1)) + 1, :);
    end
end

function tf = has_parallel_toolbox()
    tf = ~isempty(ver('parallel')) && license('test', 'Distrib_Computing_Toolbox');
end
