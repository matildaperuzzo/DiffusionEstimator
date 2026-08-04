function [x, y, colors, y_se] = get_plot_coords_from_result(parameters, result, variance_info)
cmap = get_plotting_colormap();
num_colors = size(cmap, 1);

x = parameters.dataset_bp;
y = result.errors;
[x, order] = sort(x);
y = y(order);
y_se = [];

if nargin >= 3 && ~isempty(variance_info) && isfield(variance_info, 'V_iid') && ...
        isfield(variance_info, 'J') && ~isempty(variance_info.V_iid) && ~isempty(variance_info.J)
    cov_theta = variance_info.V_iid / size(parameters.dataset_idx, 1);
    pred_var = max(sum((variance_info.J * cov_theta) .* variance_info.J, 2), 0);
    y_se = sqrt(pred_var);
    y_se = y_se(order);
end

y_min = min(y);
y_max = max(y);
y_range = max(abs(y_min), abs(y_max));
if y_range == 0
    y_range = 1;
end

color_idx = round((y + y_range) / (2 * y_range) * (num_colors - 1)) + 1;
color_idx = max(1, min(num_colors, color_idx));
colors = cmap(color_idx, :);
end
