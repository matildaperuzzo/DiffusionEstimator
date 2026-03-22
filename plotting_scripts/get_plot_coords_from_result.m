function [x, y, colors] = get_plot_coords_from_result(parameters, result)
cmap = get_plotting_colormap();
num_colors = size(cmap, 1);

x = parameters.dataset_bp;
y = result.errors;
[x, order] = sort(x);
y = y(order);

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
