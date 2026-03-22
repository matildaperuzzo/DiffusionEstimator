function database = build_filename_database_impl(repo_root, verbose)
if nargin < 2
    verbose = false;
end

crops = {'all_wheat', 'cobo', 'maize'};
labels = {'wheat', 'rice', 'maize'};
all_layers = {'asym', 'csi', 'hydro', 'prec', 'tmean', 'sea'};
database = {};

for c = 1:numel(crops)
    if verbose
        fprintf('Scanning crop %s\n', crops{c});
    end

    base_file = get_recent_fit_file(repo_root, crops{c}, {});
    base_fit = load_fit_result(base_file);

    metadata = struct();
    metadata.dataset = labels{c};
    metadata.file = base_file;
    metadata.layers = {'av'};
    metadata.theta = base_fit.theta_optim;
    metadata.best_error = get_best_error(base_fit);
    database{end + 1} = metadata; %#ok<AGROW>
    if verbose
        fprintf('  Found baseline fit: %s | best_error = %.12g\n', base_file, metadata.best_error);
    end

    for i = 1:numel(all_layers)
        for j = i:numel(all_layers)
            if i == j
                layers = {all_layers{i}};
            else
                layers = {all_layers{i}, all_layers{j}};
            end

            try
                file = get_recent_fit_file(repo_root, crops{c}, layers);
            catch
                if verbose
                    fprintf('  Missing fit for layers %s\n', strjoin(layers, ', '));
                end
                continue
            end

            fit = load_fit_result(file);
            metadata = struct();
            metadata.dataset = labels{c};
            metadata.file = file;
            metadata.layers = layers;
            metadata.theta = fit.theta_optim;
            metadata.best_error = get_best_error(fit);
            database{end + 1} = metadata; %#ok<AGROW>
            if verbose
                fprintf('  Found fit for layers %s | best_error = %.12g\n', ...
                    strjoin(layers, ', '), metadata.best_error);
            end
        end
    end
end
end

function best_error = get_best_error(fit)
if isfield(fit, 'min_error') && ~isempty(fit.min_error)
    best_error = fit.min_error;
elseif isfield(fit, 'result') && isfield(fit.result, 'squared_error')
    best_error = fit.result.squared_error;
else
    best_error = NaN;
end
end
