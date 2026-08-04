function [bs_theta, bs_errors, bootstrap_options, cluster_info] = run_knn_cluster_bootstrap(theta_start, parameters, point_errors, base_gd_options, factor, group_size, n_bootstraps, bootstrap_info, progress_callback)
%RUN_KNN_CLUSTER_BOOTSTRAP Cluster bootstrap using KNN groups in [lat, lon, error].

    if nargin < 7 || isempty(n_bootstraps)
        n_bootstraps = 100;
    end
    if nargin < 6 || isempty(group_size)
        group_size = 10;
    end
    if nargin < 8
        bootstrap_info = struct('type', 'knn_cluster', 'group_size', group_size, ...
            'n_bootstraps', n_bootstraps);
    end
    if nargin < 9
        progress_callback = [];
    end

    complete_dataset = parameters.dataset_idx;
    n_points = size(complete_dataset, 1);

    if numel(point_errors) ~= n_points
        error('point_errors must have one element per data point.');
    end

    features = [parameters.dataset_lat(:), parameters.dataset_lon(:), point_errors(:)];
    features = normalize_features(features);
    clusters = build_knn_clusters(features, group_size);

    bs_theta = NaN(n_bootstraps, numel(theta_start));
    bs_errors = NaN(n_bootstraps, 1);
    bootstrap_options = cell(n_bootstraps, 1);
    seeds = randi(2^32, n_bootstraps, 1);

    for i = 1:n_bootstraps
        rng(seeds(i));
        sampled_dataset = sample_clusters_with_replacement(complete_dataset, clusters, n_points);
        gd_options = create_bootstrap_options(base_gd_options, parameters, sampled_dataset, factor);

        [theta, ~, info] = grad_descent(theta_start, parameters, gd_options);
        bs_theta(i, :) = theta;
        bs_errors(i) = info.best_error;
        bootstrap_options{i} = gd_options;
        if ~isempty(progress_callback)
            progress_callback(bs_theta, bs_errors, bootstrap_info, i);
        end
    end

    cluster_info = struct();
    cluster_info.group_size = group_size;
    cluster_info.n_clusters = numel(clusters);
    cluster_info.cluster_sizes = cellfun(@numel, clusters);
    cluster_info.clusters = clusters;
end

function features = normalize_features(features)
    mu = mean(features, 1, 'omitnan');
    sigma = std(features, 0, 1, 'omitnan');
    sigma(sigma == 0) = 1;
    features = (features - mu) ./ sigma;
end

function clusters = build_knn_clusters(features, group_size)
    remaining = (1:size(features, 1))';
    clusters = {};

    while ~isempty(remaining)
        if numel(remaining) <= group_size
            clusters{end + 1, 1} = remaining; %#ok<AGROW>
            break;
        end

        seed_idx = remaining(1);
        candidate_idx = remaining;
        local_features = features(candidate_idx, :);
        seed_feature = features(seed_idx, :);
        nn_local_idx = find_knn_indices(local_features, seed_feature, group_size);
        cluster_members = candidate_idx(nn_local_idx);

        clusters{end + 1, 1} = cluster_members; %#ok<AGROW>
        remaining = setdiff(remaining, cluster_members, 'stable');
    end
end

function idx = find_knn_indices(feature_matrix, query_point, k)
    if exist('knnsearch', 'file') == 2
        idx = knnsearch(feature_matrix, query_point, 'K', min(k, size(feature_matrix, 1)));
    else
        distances = sum((feature_matrix - query_point).^2, 2);
        [~, order] = sort(distances, 'ascend');
        idx = order(1:min(k, numel(order)))';
    end
end

function sampled_dataset = sample_clusters_with_replacement(complete_dataset, clusters, target_size)
    sampled_idx = zeros(0, 1);
    n_clusters = numel(clusters);

    while numel(sampled_idx) < target_size
        cluster_id = randi(n_clusters);
        sampled_idx = [sampled_idx; clusters{cluster_id}(:)]; %#ok<AGROW>
    end

    sampled_idx = sampled_idx(1:target_size);
    sampled_dataset = complete_dataset(sampled_idx, :);
end

function gd_options = create_bootstrap_options(base_gd_options, parameters, sampled_dataset, factor)
    gd_options = base_gd_options;
    gd_options.objective_function = @(theta) optimize_model_bootstraps(theta, parameters, sampled_dataset, factor);
    gd_options.gradient_objective = gd_options.objective_function;
    gd_options.result_function = @(theta) run_model(parameters, theta, sampled_dataset);
end
