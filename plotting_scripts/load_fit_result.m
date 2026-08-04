function fit = load_fit_result(file)
fit = load(file);

if ~isfield(fit, 'parameters') || ~isfield(fit, 'theta_optim')
    error('Fit file %s must contain parameters and theta_optim.', file);
end

[fit, persisted] = reconcile_fit_state(fit);
if ~isempty(fieldnames(persisted))
    save(file, '-struct', 'persisted', '-append');
end

if ~isfield(fit, 'bs_theta')
    fit.bs_theta = [];
end

if ~isfield(fit, 'bs_errors')
    fit.bs_errors = [];
end
end

function [fit, persisted] = reconcile_fit_state(fit)
persisted = struct();
theta_changed = false;

[best_theta, best_error, found_best] = get_best_from_all_params(fit);
if found_best && ~same_theta(fit.theta_optim, best_theta)
    fit.theta_optim = best_theta;
    persisted.theta_optim = best_theta;
    theta_changed = true;
end

result_matches_best = false;
if found_best && isfield(fit, 'result') && ~isempty(fit.result) && ...
        isfield(fit.result, 'squared_error') && isfinite(fit.result.squared_error)
    result_matches_best = is_close_scalar(fit.result.squared_error, best_error);
end

needs_result = theta_changed || ~isfield(fit, 'result') || isempty(fit.result) || ...
    ~isfield(fit.result, 'squared_error') || ~isfinite(fit.result.squared_error) || ...
    (found_best && ~result_matches_best);
if needs_result
    fit.result = run_model(fit.parameters, fit.theta_optim);
    persisted.result = fit.result;
end

needs_min_error = ~isfield(fit, 'min_error') || isempty(fit.min_error) || ...
    ~is_close_scalar(fit.min_error, fit.result.squared_error);
if needs_min_error
    fit.min_error = fit.result.squared_error;
    persisted.min_error = fit.min_error;
end

if theta_changed || ~isfield(fit, 'variance_info') || isempty(fit.variance_info)
    fit.variance_info = compute_variance(fit.theta_optim, fit.parameters);
    persisted.variance_info = fit.variance_info;
end
end

function [best_theta, best_error, found_best] = get_best_from_all_params(fit)
best_theta = [];
best_error = NaN;
found_best = false;

if ~isfield(fit, 'all_params') || isempty(fit.all_params)
    return;
end

all_params = fit.all_params;
if isstruct(all_params)
    all_params = num2cell(all_params);
end

best_error = inf;
for idx = 1:numel(all_params)
    [candidate_theta, candidate_error, found_candidate] = extract_best_candidate(all_params{idx});
    if ~found_candidate || ~isfinite(candidate_error)
        continue;
    end

    if candidate_error < best_error
        best_theta = candidate_theta;
        best_error = candidate_error;
        found_best = true;
    end
end

if ~found_best
    best_error = NaN;
end
end

function [theta, err, found_candidate] = extract_best_candidate(entry)
theta = [];
err = NaN;
found_candidate = false;

if ~isstruct(entry)
    return;
end

if isfield(entry, 'final_errors') && isfield(entry, 'final_thetas') && ...
        ~isempty(entry.final_errors) && ~isempty(entry.final_thetas)
    final_errors = entry.final_errors(:);
    final_thetas = entry.final_thetas;
    valid = isfinite(final_errors);
    if any(valid)
        valid_idx = find(valid);
        [err, local_idx] = min(final_errors(valid_idx));
        theta = reshape(final_thetas(valid_idx(local_idx), :), 1, []);
        found_candidate = true;
        return;
    end
end

if isfield(entry, 'best_theta') && isfield(entry, 'best_error') && ...
        ~isempty(entry.best_theta) && ~isempty(entry.best_error) && isfinite(entry.best_error)
    theta = reshape(entry.best_theta, 1, []);
    err = entry.best_error;
    found_candidate = true;
end
end

function tf = same_theta(theta_a, theta_b)
theta_a = reshape(theta_a, 1, []);
theta_b = reshape(theta_b, 1, []);

if numel(theta_a) ~= numel(theta_b)
    tf = false;
    return;
end

scale = max([ones(size(theta_a)); abs(theta_a); abs(theta_b)], [], 1);
tf = all(abs(theta_a - theta_b) <= 1e-10 * scale);
end

function tf = is_close_scalar(a, b)
if isempty(a) || isempty(b) || ~isfinite(a) || ~isfinite(b)
    tf = false;
    return;
end

scale = max([1, abs(a), abs(b)]);
tf = abs(a - b) <= 1e-10 * scale;
end
