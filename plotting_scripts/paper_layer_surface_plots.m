clear;
clc;

script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
addpath(script_dir);
addpath(fullfile(repo_root, 'src'));

set(0, 'defaulttextinterpreter', 'latex');

crop = 'all_wheat';
data_path = fullfile(repo_root, 'generated_data', 'sweep_grad_descent');
output_file = fullfile(repo_root, 'saved_plots', 'paper_layer_surface_plots.pdf');

layer_order = {'sea', 'csi', 'hydro', 'prec', 'tmean'};
layer_titles = {
    'Sea'
    'Crop suitability'
    'River size'
    'Precipitation'
    'Mean temperature'
};
zlabels = {
    'Sea'
    'Crop suitability'
    'River size'
    'Precipitation'
    'Mean temperature'
};

cmap = flipud(get_plotting_colormap());
f = figure(1);
f.Position = [100 100 2500 300];
set(gcf, 'Color', 'White', 'Alphamap', 1);

tiledlayout(1, 5, 'Padding', 'compact', 'TileSpacing', 'compact');

for i = 1:numel(layer_order)
    fit = load_fit_result(get_fit_file(data_path, crop, layer_order{i}));
    layer_data = get_layer_matrix(fit, layer_order{i});
    if ismember(layer_order{i}, {'sea', 'csi'})
        layer_data = smooth_layer(layer_data);
    elseif ismember(layer_order{i}, {'hydro'})
        layer_data = smooth_layer(layer_data);
        layer_data = log10(1+layer_data);
    end
    [X, Y] = get_grid(fit.parameters, size(layer_data));

    nexttile
    s = mesh(X, Y, layer_data');
    s.FaceColor = 'flat';
    s.FaceAlpha = 1;

    view([45 60]);
    xlim([min(X(:)), max(X(:))]);
    ylim([min(Y(:)), max(Y(:))]);
    colormap(gca, cmap);
    grid off

    ax = gca;
    ax.FontSize = 12;
    set(ax, 'TickLabelInterpreter', 'latex');

    xlabel('Latitude', 'Rotation', -25, 'FontSize', 12);
    ylabel('Longitude', 'Rotation', 25, 'FontSize', 12);
    zlabel(zlabels{i}, 'FontSize', 12);
    title(layer_titles{i}, 'FontSize', 14);
end

% exportgraphics(gcf, output_file, 'ContentType', 'vector');

function file = get_fit_file(data_path, crop, layer_name)
if strcmp(layer_name, 'sea')
    layers = {'sea'};
else
    layers = {layer_name, 'sea'};
end

file = get_recent_fit_file(data_path, crop, layers);
end

function layer_data = get_layer_matrix(fit, layer_name)
layer_slots = {'csi', 'hydro', 'prec', 'tmean', 'sea', 'crop_wheat', 'crop_rice', 'crop_maize'};
active_slots = fit.parameters.active_layers(3:end);
available_layers = layer_slots(active_slots);
layer_idx = find(strcmp(available_layers, layer_name), 1);

if isempty(layer_idx)
    error('Layer %s not found in fit file.', layer_name);
end

layer_data = fit.parameters.X{layer_idx};
end

function [X, Y] = get_grid(parameters, layer_size)
nx = layer_size(1);
ny = layer_size(2);
x = linspace(parameters.lat(1), parameters.lat(2), nx);
y = linspace(parameters.lon(1), parameters.lon(2), ny);
[X, Y] = meshgrid(x, y);
end

function smoothed = smooth_layer(layer_data)
kernel = gaussian_kernel(7, 1.2);
smoothed = conv2(layer_data, kernel, 'same');
end

function kernel = gaussian_kernel(kernel_size, sigma)
radius = floor(kernel_size / 2);
[x, y] = meshgrid(-radius:radius, -radius:radius);
kernel = exp(-(x.^2 + y.^2) / (2 * sigma^2));
kernel = kernel / sum(kernel(:));
end
