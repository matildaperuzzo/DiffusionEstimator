function [value, se] = get_velocity_stat(fit, mode, vmax)
theta = fit.theta_optim(:);
cov_theta = fit.variance_info.V_iid / size(fit.parameters.dataset_idx, 1);

switch mode
    case 'baseline'
        p = 1 ./ (1 + exp(-theta(1)));
        value = vmax * p;
        grad = vmax * p * (1 - p);
        se = abs(grad) * fit.variance_info.se_iid(1);
    case 'sea_only'
        p = 1 ./ (1 + exp(-theta(1)));
        value = vmax * p;
        grad = vmax * p * (1 - p);
        se = abs(grad) * fit.variance_info.se_iid(1);
    case 'difference'
        p1 = 1 ./ (1 + exp(-theta(1)));
        p12 = 1 ./ (1 + exp(-(theta(1) + theta(2))));
        value = vmax * (p12 - p1);
        grad = [vmax * (p12 * (1 - p12) - p1 * (1 - p1)); ...
            vmax * p12 * (1 - p12)];
        se = sqrt(max(grad' * cov_theta(1:2, 1:2) * grad, 0));
    otherwise
        error('Unknown velocity stat mode %s.', mode);
end
end
