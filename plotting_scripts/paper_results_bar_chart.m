clear;
clc;

script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
addpath(script_dir);
addpath(fullfile(repo_root, 'src'));

database_file = fullfile(repo_root, 'generated_data', 'filename_database.mat');
if exist(database_file, 'file') ~= 2
    database = build_filename_database_impl(repo_root);
    save(database_file, 'database');
end
load(database_file, 'database');

crop_specs = {
    'wheat', 'Wheat'
    'rice', 'Rice'
    'maize', 'Maize'
};
target_layers = {{'av'}, {'sea'}, {'asym', 'sea'}, {'csi', 'sea'}, {'hydro', 'sea'}, {'prec', 'sea'}, {'tmean', 'sea'}};
layer_names = {'Baseline', 'Sea only', 'Anisotropy', 'Crop suitability', 'River size', 'Precipitation', 'Mean temperature'};
cmap = get_plotting_colormap();

f = figure(1);
f.Position = [100 100 800 180];
tiledlayout(1, 3, 'Padding', 'none', 'TileSpacing', 'compact');

for c = 1:size(crop_specs, 1)
    nexttile;
    hold on;
    values = NaN(1, numel(target_layers));
    for i = 1:numel(target_layers)
        entry = find_entry(database, crop_specs{c, 1}, target_layers{i});
        if isempty(entry)
            continue
        end
        fit = load_fit_result(entry.file);
        values(i) = sqrt(fit.result.squared_error) / 1e3;
    end

    b = barh(values, 0.95);
    for i = 1:numel(values)
        b.FaceColor = 'flat';
        b.CData(i, :) = cmap(round(i * size(cmap, 1) / (numel(values) + 1)), :);
    end
    yticks(1:numel(values));
    yticklabels(layer_names);
    title(crop_specs{c, 2});
    xlabel('Average error (kyears)');
    grid on;
end

function entry = find_entry(database, dataset, layers)
entry = [];
for k = 1:numel(database)
    candidate = database{k};
    if strcmp(candidate.dataset, dataset) && isequal(sort(candidate.layers), sort(layers))
        entry = candidate;
        return
    end
end
end
