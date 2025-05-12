
addpath('src');
load('generated_data\filename_database.mat')
n_bootstraps = 100;
for d=1:length(database)
    if (length(database{d}.layers) == 2)
        if ~all(ismember('sea', database{d}.layers{2}))
            continue
        end
    elseif length(database{d}.layers) == 1
        if ~all(ismember(database{d}.layers{1}, {'sea','av'}))
            continue
        end

    end
    
    spread_errors_boot = zeros(n_bootstraps,1);
    spread_sq_errors_boot = zeros(n_bootstraps,1);
    load(database{d}.file)
    disp(database{d}.file)
    complete_dataset = parameters.dataset_idx;
    figure(d)
    hold on
    for i = 1:n_bootstraps
        rng('shuffle');
        n = size(complete_dataset, 1); % Number of points in the dataset
        % Generate n random indices between 1 and n
        random_indices = randi(n, n, 1);
        % Use the indices to sample points from the dataset
        sampled_dataset = complete_dataset(random_indices, :);
        scatter(sampled_dataset(:,2),sampled_dataset(:,1),'.')
        parameters.dataset_idx = sampled_dataset;
        result = run_model(parameters, theta_optim);
        spread_sq_errors_boot(i) = result.squared_error;
        spread_errors_boot(i) = sqrt(result.squared_error);

    end
    save(database{d}.file, "spread_sq_errors_boot", "spread_errors_boot", '-append')
    disp(database{d}.dataset)
    disp(database{d}.layers)
    load(database{d}.file)
    disp(result.squared_error)
    disp(mean(spread_sq_errors_boot))
    disp(std(spread_sq_errors_boot))
end

%%
for i=1:length(database)
    if (length(database{i}.layers) == 2)
        if ~all(ismember('sea', database{i}.layers{2}))
            continue
        end
    elseif length(database{i}.layers) == 1
        if ~all(ismember(database{i}.layers{1}, {'sea','av'}))
            continue
        end

    end
    
    disp(database{i}.dataset)
    disp(database{i}.layers)
    load(database{i}.file)
    disp(result.squared_error)
    disp(mean(spread_sq_errors_boot))
    disp(std(spread_sq_errors_boot))
end