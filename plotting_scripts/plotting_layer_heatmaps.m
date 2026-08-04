clear;
clc;

script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
addpath(script_dir);
addpath(fullfile(repo_root, 'src'));

database = build_filename_database_impl(repo_root);
all_layers = {'asym', 'csi', 'hydro', 'prec', 'tmean', 'sea'};
crop_specs = {
    'all_wheat', 'Wheat'
    'cobo', 'Rice'
    'maize', 'Maize'
};

for c = 1:size(crop_specs, 1)
    crop = crop_specs{c, 1};
    title_text = crop_specs{c, 2};
    base_fit = load_fit_result(get_recent_fit_file(repo_root, crop, {}));
    sq_errs = NaN(numel(all_layers));

    for i = 1:numel(all_layers)
        for j = i:numel(all_layers)
            if i == j
                layers = {all_layers{i}};
            else
                layers = {all_layers{i}, all_layers{j}};
            end

            try
                fit = load_fit_result(get_recent_fit_file(repo_root, crop, layers));
            catch
                continue
            end

            sq_errs(i, j) = fit.result.squared_error;
            sq_errs(j, i) = fit.result.squared_error;
        end
    end

    sq_errors = 1 - sq_errs / base_fit.result.squared_error;
    figure;
    imagesc(sq_errors);
    axis image;
    colormap(pink);
    colorbar;
    xticks(1:numel(all_layers));
    yticks(1:numel(all_layers));
    xticklabels(all_layers);
    yticklabels(all_layers);
    xtickangle(45);
    title(title_text);
end

save(fullfile(repo_root, 'generated_data', 'filename_database.mat'), 'database');
