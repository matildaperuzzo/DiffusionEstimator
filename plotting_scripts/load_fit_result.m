function fit = load_fit_result(file)
fit = load(file);

if ~isfield(fit, 'parameters') || ~isfield(fit, 'theta_optim')
    error('Fit file %s must contain parameters and theta_optim.', file);
end

if ~isfield(fit, 'result')
    result = run_model(fit.parameters, fit.theta_optim);
    fit.result = result;
    save(file, 'result', '-append')
end

if ~isfield(fit, 'variance_info') || isempty(fit.variance_info)
    variance_info = compute_variance(fit.theta_optim, fit.parameters);
    fit.variance_info = variance_info;
    save(file,"variance_info",'-append')
end

if ~isfield(fit, 'bs_theta')
    fit.bs_theta = [];
end

if ~isfield(fit, 'bs_errors')
    fit.bs_errors = [];
end
end
