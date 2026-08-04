function [grad, hessian] = calculate_gradient_fit(f, theta, dims, max_window_size)
%CALCULATE_GRADIENT_FIT Estimate gradients and optionally Hessians by fitting polynomials.
%   grad = calculate_gradient_fit(f, theta)
%   grad = calculate_gradient_fit(f, theta, dims)
%   grad = calculate_gradient_fit(f, theta, dims, max_window_size)
%   [grad, hessian] = calculate_gradient_fit(...)
%
%   Inputs:
%     f               - function handle of theta
%     theta           - point at which to evaluate derivatives
%     dims            - optional vector of theta indices to evaluate
%     max_window_size - optional half-window size, default 0.1
%
%   When only grad is requested, the function evaluates f at 5 points in
%   each requested dimension over [-max_window_size, max_window_size], fits
%   a line, and uses the fitted slope as the gradient estimate.
%
%   When hessian is also requested, the function fits quadratics. Diagonal
%   entries are estimated from 1D quadratic fits and off-diagonal entries
%   from 2D quadratic fits over a 5x5 grid. The central value f(theta) is
%   evaluated once and reused through a cache.

    narginchk(2, 4);

    theta = theta(:)';

    if nargin < 3 || isempty(dims)
        dims = 1:numel(theta);
    end
    if nargin < 4 || isempty(max_window_size)
        max_window_size = 0.1;
    end

    validateattributes(dims, {'numeric'}, {'vector', 'integer', 'positive', '<=', numel(theta)}, ...
        mfilename, 'dims');
    validateattributes(max_window_size, {'numeric'}, {'scalar', 'positive', 'finite'}, ...
        mfilename, 'max_window_size');

    dims = unique(reshape(dims, 1, []), 'stable');
    theta_count = numel(theta);

    % Cache sampled function values so shared points across fits are only evaluated once.
    cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
    center_value = evaluate_cached(theta);
    output_count = numel(center_value);

    grad = zeros(theta_count, output_count);

    if nargout < 2
        hessian = [];
        grad = fit_gradient_lines();
        return;
    end

    hessian = zeros(theta_count, theta_count, output_count);
    [grad, hessian] = fit_gradient_and_hessian_quadratics();

    function grad_out = fit_gradient_lines()
        offsets = linspace(-max_window_size, max_window_size, 5)';
        center_idx = ceil(numel(offsets) / 2);
        % Fit value ~= slope * offset + intercept along each requested axis.
        design = [offsets, ones(size(offsets))];
        grad_out = zeros(theta_count, output_count);

        for dim_idx = dims
            values = zeros(numel(offsets), output_count);
            values(center_idx, :) = reshape(center_value, 1, []);

            for point_idx = 1:numel(offsets)
                if point_idx == center_idx
                    continue;
                end
                theta_shifted = theta;
                theta_shifted(dim_idx) = theta_shifted(dim_idx) + offsets(point_idx);
                values(point_idx, :) = reshape(evaluate_cached(theta_shifted), 1, []);
            end

            coeffs = design \ values;
            grad_out(dim_idx, :) = coeffs(1, :);
        end
    end

    function [grad_out, hessian_out] = fit_gradient_and_hessian_quadratics()
        offsets = linspace(-max_window_size, max_window_size, 5)';
        center_idx = ceil(numel(offsets) / 2);
        % Fit value ~= a * offset^2 + b * offset + c for each axis.
        design_1d = [offsets .^ 2, offsets, ones(size(offsets))];

        grad_out = zeros(theta_count, output_count);
        hessian_out = zeros(theta_count, theta_count, output_count);

        for dim_idx = dims
            values = zeros(numel(offsets), output_count);
            values(center_idx, :) = reshape(center_value, 1, []);

            for point_idx = 1:numel(offsets)
                if point_idx == center_idx
                    continue;
                end
                theta_shifted = theta;
                theta_shifted(dim_idx) = theta_shifted(dim_idx) + offsets(point_idx);
                values(point_idx, :) = reshape(evaluate_cached(theta_shifted), 1, []);
            end

            coeffs = design_1d \ values;
            grad_out(dim_idx, :) = coeffs(2, :);
            % For a quadratic a*x^2 + b*x + c, the second derivative is 2*a.
            hessian_out(dim_idx, dim_idx, :) = reshape(2 * coeffs(1, :), 1, 1, []);
        end

        [u_grid, v_grid] = ndgrid(offsets, offsets);
        u = u_grid(:);
        v = v_grid(:);
        % Fit value ~= a*u^2 + b*v^2 + c*u*v + d*u + e*v + f in each 2D plane.
        design_2d = [u .^ 2, v .^ 2, u .* v, u, v, ones(size(u))];

        for first_idx = 1:numel(dims)
            dim_i = dims(first_idx);
            for second_idx = first_idx + 1:numel(dims)
                dim_j = dims(second_idx);
                values = zeros(numel(u), output_count);

                for sample_idx = 1:numel(u)
                    theta_shifted = theta;
                    theta_shifted(dim_i) = theta_shifted(dim_i) + u(sample_idx);
                    theta_shifted(dim_j) = theta_shifted(dim_j) + v(sample_idx);
                    values(sample_idx, :) = reshape(evaluate_cached(theta_shifted), 1, []);
                end

                coeffs = design_2d \ values;
                % The mixed second derivative is the coefficient on the u*v term.
                hessian_out(dim_i, dim_j, :) = reshape(coeffs(3, :), 1, 1, []);
                hessian_out(dim_j, dim_i, :) = reshape(coeffs(3, :), 1, 1, []);
            end
        end
    end

    function value = evaluate_cached(theta_value)
        % Use the sampled theta values as cache keys so repeated center and grid points
        % across 1D and 2D fits do not trigger extra function evaluations.
        key = sprintf('%.16g,', theta_value);
        if isKey(cache, key)
            value = cache(key);
            return;
        end

        value = f(theta_value);
        cache(key) = value;
    end
end
