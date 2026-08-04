function state = fit_model(crop, layers, do_bootstraps, file_to_load, level_to_load, bootstrap_type, bootstrap_group_size, n_bootstraps)
%FIT_MODEL Resumable fitting pipeline extracted from tests/fit_model.m.
%   state = fit_model(crop, layers)
%   state = fit_model(crop, layers, do_bootstraps, file_to_load, level_to_load, bootstrap_type, bootstrap_group_size, n_bootstraps)
%
%   Required inputs:
%     crop   - dataset/crop name, e.g. 'cobo'
%     layers - cell array of active layer names
%
%   Optional inputs:
%     do_bootstraps - logical, whether to run bootstrap re-estimation
%     file_to_load  - MAT file to resume from
%     level_to_load - level to resume from inside the loaded file
%     bootstrap_type - 'iid' or 'knn_cluster'
%     bootstrap_group_size - group size for the KNN cluster bootstrap
%     n_bootstraps - number of bootstrap iterations to run

    narginchk(2, 8);

    if nargin < 3 || isempty(do_bootstraps)
        do_bootstraps = false;
    end
    if nargin < 4
        file_to_load = "";
    end
    if nargin < 5
        level_to_load = [];
    end
    if nargin < 6 || isempty(bootstrap_type)
        bootstrap_type = 'iid';
    end
    if nargin < 7 || isempty(bootstrap_group_size)
        bootstrap_group_size = 10;
    end
    if nargin < 8 || isempty(n_bootstraps)
        n_bootstraps = 100;
    end

    if ischar(layers) || isstring(layers)
        layers = cellstr(layers);
    end

    number_of_averages = 100;
    factors = 1e3;
    directory = 'generated_data';
    load_data = strlength(string(file_to_load)) > 0;
    optimizer_options = struct();
    bootstrap_options = struct();

    tic;

    if load_data
        loaded = load(file_to_load);
        filename = string(file_to_load);
        validate_loaded_config(loaded, crop, layers, filename);
        level = get_loaded(loaded, 'level', 0);
        number_of_averages = get_loaded(loaded, 'number_of_averages', number_of_averages);
        parameters = get_loaded(loaded, 'parameters', []);
        ranges = get_loaded(loaded, 'ranges', []);
        active_layers = get_loaded(loaded, 'active_layers', []);
        theta_start = get_loaded(loaded, 'theta_start', []);
        theta_optim = get_loaded(loaded, 'theta_optim', []);
        min_error = get_loaded(loaded, 'min_error', []);
        all_params = get_loaded(loaded, 'all_params', {});
        bs_theta = get_loaded(loaded, 'bs_theta', []);
        bs_errors = get_loaded(loaded, 'bs_errors', []);
        variance_info = get_loaded(loaded, 'variance_info', []);

        if ~isempty(level_to_load)
            requested_level = level_to_load;
            if level < requested_level
                fprintf('Loaded file level %d is below requested level %d. Resuming from level %d instead.\n', ...
                    level, requested_level, level);
            else
                level = requested_level;
            end
        end
    else
        t = datetime;
        t.Format = 'yyyy-MM-dd_HH-mm';
        filename = fullfile(directory, sprintf('%s_%s_%dav_%s.mat', ...
            crop, strjoin(layers, '_'), number_of_averages, string(t)));
        level = 0;
        parameters = [];
        ranges = [];
        active_layers = [];
        theta_start = [];
        theta_optim = [];
        min_error = [];
        all_params = {};
        bs_theta = [];
        bs_errors = [];
        variance_info = [];

        save(filename, 'crop', 'number_of_averages', 'layers', 'filename');
    end

    if level < 1
        [ranges, active_layers] = build_ranges(crop, layers);
        level = 1;
        save(filename, 'ranges', 'active_layers', 'level', '-append');
    end

    if level < 2
        [x, y, t_data] = get_dataset(crop);
        parameters = data_prep(number_of_averages, active_layers, x, y, t_data);
        if strcmp(crop, 'cobo')
            parameters.A(76,39,46) = true;
        end
        level = 2;
        save(filename, 'parameters', 'level', '-append');
    end

    if level < 3
        check_speeds(parameters);
        level = 3;
        save(filename, 'level', '-append');
    end

    if level < 4
        parameters.n = 20;
        [theta_start, on_edge, min_error] = run_local_sweeps(ranges, parameters);
        parameters.n = number_of_averages;
        level = 4;

        if on_edge
            disp('Likely the given ranges are wrong');
        else
            disp('Local minimum found');
        end

        save(filename, 'theta_start', 'min_error', 'level', '-append');
    end

    if level < 5
        gd_options = create_grad_descent_options(parameters, factors);
        [theta_optim, result, gd_info] = grad_descent(theta_start, parameters, gd_options);
        min_error = gd_info.best_error;
        variance_info = compute_variance(theta_optim, parameters);
        all_params{end + 1} = gd_info;
        optimizer_options = gd_options;
        level = 5;

        save(filename, 'theta_optim', 'min_error', 'variance_info', 'all_params', 'optimizer_options', 'level', '-append');
    else
        result = run_model(parameters, theta_optim);
        optimizer_options = get_loaded(loaded, 'optimizer_options', struct());
        if isempty(variance_info)
            variance_info = compute_variance(theta_optim, parameters);
            save(filename, 'variance_info', '-append');
        end
    end

    if do_bootstraps
        bootstrap_completed = 0;
        save(filename, 'bootstrap_completed', '-append');
        [bs_theta, bs_errors, bootstrap_options, bootstrap_info] = ...
            run_bootstrap_stage(theta_optim, parameters, result, factors, bootstrap_type, ...
            bootstrap_group_size, n_bootstraps, filename);
        bootstrap_completed = n_bootstraps;
        save(filename, 'bs_theta', 'bs_errors', 'bootstrap_options', 'bootstrap_info', 'bootstrap_completed', '-append');
    elseif ~load_data
        bootstrap_options = struct();
        bootstrap_info = struct();
        bootstrap_completed = 0;
    else
        bootstrap_options = get_loaded(loaded, 'bootstrap_options', struct());
        bootstrap_info = get_loaded(loaded, 'bootstrap_info', struct());
        bootstrap_completed = get_loaded(loaded, 'bootstrap_completed', 0);
    end

    runtime = toc;
    save(filename, 'runtime', '-append');

    state = struct();
    state.filename = filename;
    state.level = level;
    state.crop = crop;
    state.layers = layers;
    state.parameters = parameters;
    state.ranges = ranges;
    state.active_layers = active_layers;
    state.theta_start = theta_start;
    state.theta_optim = theta_optim;
    state.min_error = min_error;
    state.result = result;
    state.all_params = all_params;
    state.bs_theta = bs_theta;
    state.bs_errors = bs_errors;
    state.variance_info = variance_info;
    state.optimizer_options = optimizer_options;
    state.bootstrap_options = bootstrap_options;
    state.bootstrap_info = bootstrap_info;
    state.bootstrap_completed = bootstrap_completed;
    state.bootstrap_type = bootstrap_type;
    state.bootstrap_group_size = bootstrap_group_size;
    state.n_bootstraps = n_bootstraps;
    state.runtime = runtime;
end

function [ranges, active_layers] = build_ranges(crop, layers)
    average_range = choose_range(ismember('av', layers), [-1.0, 1.0], [0.0, 0.0]);
    anisotropy_range = choose_range(ismember('asym', layers), [-2, 2], [0.0, 0.0]);
    csi_range = choose_range(ismember('csi', layers), [-1.0, 1.0], [0.0, 0.0]);
    hydro_range = choose_range(ismember('hydro', layers), [-1, 1], [0.0, 0.0]);
    prec_range = choose_range(ismember('prec', layers), [-2, 2], [0.0, 0.0]);
    tmean_range = choose_range(ismember('tmean', layers), [-1, 1], [0.0, 0.0]);
    sea_range = choose_range(ismember('sea', layers), [-1, 1], [0.0, 0.0]);

    if ismember('crop', layers)
        switch crop
            case {'all_wheat', 'pinhasi', 'desouza'}
                crop_ranges = [[-1, 1]; [0, 0]; [0, 0]];
            case 'cobo'
                crop_ranges = [[0, 0]; [-1, 1]; [0, 0]];
            case 'maize'
                crop_ranges = [[0, 0]; [0, 0]; [-1, 1]];
            otherwise
                crop_ranges = zeros(3, 2);
        end
    else
        crop_ranges = zeros(3, 2);
    end

    ranges = [average_range; anisotropy_range; csi_range; hydro_range; ...
        prec_range; tmean_range; sea_range; crop_ranges];
    active_layers = diff(ranges, 1, 2) > 0;
    ranges = ranges(active_layers, :);
    active_layers = active_layers';
end

function out = choose_range(flag, enabled_range, disabled_range)
    if flag
        out = enabled_range;
    else
        out = disabled_range;
    end
end

function check_speeds(parameters)
    [min_time, min_idx] = min(parameters.dataset_idx(:,3));
    rel_times = parameters.dataset_idx(:,3) - min_time;
    rel_lat = parameters.dataset_idx(:,1) - parameters.dataset_idx(min_idx,1);
    rel_lon = parameters.dataset_idx(:,2) - parameters.dataset_idx(min_idx,2);
    distances = sqrt(rel_lat.^2 + rel_lon.^2);
    speeds = distances ./ rel_times;
    speeds = speeds(~isnan(speeds));

    figure(1);
    histogram(speeds, linspace(0, 1, 21));
    xlabel('Speed');
    ylabel('Frequency');
    title('Speed distribution');

    if mean(speeds) > 0.6
        disp('Speeds are too high, decrease the time step for convergence');
    elseif mean(speeds) < 0.2
        disp('Speeds are too low, increase the time step for better speed');
    else
        disp('Speeds are within acceptable range');
    end
end

function [theta_start, on_edge, min_error] = run_local_sweeps(ranges, parameters)
    [theta_start, ~, ~] = sweep(ranges, 11, 2, parameters);
    ranges = [0.8 1.2] .* theta_start';
    [theta_start, on_edge, min_error] = sweep(ranges, 11, 1, parameters);
end

function options = create_grad_descent_options(parameters, factor)
    options = struct();
    options.n_starts = 8;
    options.variance_scale = 2.0;
    options.use_parallel = true;
    options.gradient_steps = fliplr([0.01 0.02 0.05 0.1]);
    options.steps = fliplr([0.002 0.01 0.02 0.05 0.15]);
    options.objective_function = @(theta) optimize_model(theta, parameters, factor);
    options.gradient_objective = options.objective_function;
    options.result_function = @(theta) run_model(parameters, theta);
    options.verbose = false;
    options.debug = false;
end

function [bs_theta, bs_errors, bootstrap_options, bootstrap_info] = run_bootstrap_stage(theta_start, parameters, result, factor, bootstrap_type, bootstrap_group_size, n_bootstraps, filename)
    bootstrap_type = lower(string(bootstrap_type));
    progress_callback = @(bs_theta, bs_errors, bootstrap_info, bootstrap_completed) ...
        save_bootstrap_progress(filename, bs_theta, bs_errors, bootstrap_info, bootstrap_completed);
    if bootstrap_type == "iid"
        bootstrap_info = struct('type', 'iid', 'group_size', NaN, 'n_bootstraps', n_bootstraps);
        [bs_theta, bs_errors, bootstrap_options] = run_iid_bootstrap_stage( ...
            theta_start, parameters, factor, n_bootstraps, bootstrap_info, progress_callback);
    elseif bootstrap_type == "knn_cluster"
        base_options = create_grad_descent_options(parameters, factor);
        bootstrap_info = struct('type', 'knn_cluster', 'group_size', bootstrap_group_size, ...
            'n_bootstraps', n_bootstraps);
        [bs_theta, bs_errors, bootstrap_options, cluster_info] = run_knn_cluster_bootstrap( ...
            theta_start, parameters, result.errors, base_options, factor, bootstrap_group_size, ...
            n_bootstraps, bootstrap_info, progress_callback);
        bootstrap_info.cluster_info = cluster_info;
        progress_callback(bs_theta, bs_errors, bootstrap_info, n_bootstraps);
    else
        error('Unknown bootstrap_type: %s. Use ''iid'' or ''knn_cluster''.', bootstrap_type);
    end
end

function [bs_theta, bs_errors, bootstrap_options] = run_iid_bootstrap_stage(theta_start, parameters, factor, n_bootstraps, bootstrap_info, progress_callback)
    bs_theta = NaN(n_bootstraps, numel(theta_start));
    bs_errors = NaN(n_bootstraps, 1);
    complete_dataset = parameters.dataset_idx;
    n = size(complete_dataset, 1);
    seeds = randi(2^32, n_bootstraps, 1);
    bootstrap_options = cell(n_bootstraps, 1);

    for i = 1:n_bootstraps
        rng(seeds(i));
        random_indices = randi(n, n, 1);
        sampled_dataset = complete_dataset(random_indices, :);
        gd_options = create_bootstrap_grad_descent_options(parameters, sampled_dataset, factor);

        [theta, ~, info] = grad_descent(theta_start, parameters, gd_options);
        bs_theta(i, :) = theta;
        bs_errors(i) = info.best_error;
        bootstrap_options{i} = gd_options;
        progress_callback(bs_theta, bs_errors, bootstrap_info, i);
    end
end

function options = create_bootstrap_grad_descent_options(parameters, sampled_dataset, factor)
    options = create_grad_descent_options(parameters, factor);
    options.objective_function = @(theta) optimize_model_bootstraps(theta, parameters, sampled_dataset, factor);
    options.gradient_objective = options.objective_function;
    options.result_function = @(theta) run_model(parameters, theta, sampled_dataset);
end

function val = get_loaded(loaded, field_name, default_val)
    if isfield(loaded, field_name)
        val = loaded.(field_name);
    else
        val = default_val;
    end
end

function validate_loaded_config(loaded, crop, layers, filename)
    if isfield(loaded, 'layers')
        loaded_layers = loaded.layers;
        if ischar(loaded_layers) || isstring(loaded_layers)
            loaded_layers = cellstr(loaded_layers);
        end
        if ~isequal(loaded_layers(:), layers(:))
            error('Loaded file %s was created with layers %s, not %s.', ...
                filename, strjoin(loaded_layers, ','), strjoin(layers, ','));
        end
    else
        error('Loaded file %s does not contain layer metadata, so fit_model cannot validate it safely.', filename);
    end

    if isfield(loaded, 'crop')
        loaded_crop = string(loaded.crop);
    elseif isfield(loaded, 'dataset')
        loaded_crop = string(loaded.dataset);
    else
        error('Loaded file %s does not contain crop metadata, so fit_model cannot validate it safely.', filename);
    end

    if loaded_crop ~= string(crop)
        error('Loaded file %s was created for crop %s, not %s.', filename, loaded_crop, string(crop));
    end
end

function save_bootstrap_progress(filename, bs_theta, bs_errors, bootstrap_info, bootstrap_completed)
    save(filename, 'bs_theta', 'bs_errors', 'bootstrap_info', 'bootstrap_completed', '-append');
end
