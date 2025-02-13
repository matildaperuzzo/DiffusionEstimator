%% Start new run 

clear all
tic
t = datetime;
t.Format = 'yyyy-MM-dd_HH-mm';
% choose whether to load or start
load = false;

%%
if load == false

    number_of_averages = 100;
    filename = 'Cobo_two_start_dataset_Hydro_layers';
    filename = filename + string(number_of_averages);
    filename = filename + "_";
    filename = filename + string(t);
    level = 0;
    
    save(filename, "number_of_averages");

end

%% Load existing run

if load
    % filename
    load(filename);
    
    load = true;
end

%% choose geographical layers

if level < 1
    
    % Average diffusion
    average_range = [-2.0, 2.0];
    % Anisotropy 
    anisotropy_range = [0.0, 0.0];
    % csi
    csi_range = [0.0, 0.0]; 
    % hydro
    hydro_range = [-2.0, 2.0];

    ranges = [average_range; anisotropy_range; csi_range; hydro_range];

    sage_layers = [];
    
    for i = 0:16
        if ismember(i,sage_layers)
            ranges = [ranges; [-1.0 1.0]];
        else
            ranges = [ranges; [0.0 0.0]];
        end
    end

    active_layers = diff(ranges,1,2)>0;
    ranges = ranges(active_layers,:);
    active_layers = active_layers';

    level = 1;

    save(filename, "ranges","level","active_layers", '-append');

end
%% import the data

% add parent directory
addpath('src');
 
if level < 2

    % load pinhasi
    % pinhasi = readtable( ...
    %     'data/raw/pinhasi/Neolithic_timing_Europe_PLOS.xls');
    % 
    % pinhasi = pinhasi(pinhasi.Var1 == "SITE",:); %% keep only site rows
    % 
    % pinhasi = renamevars(pinhasi, {'Latitude', 'Longitude', 'CALC14BP'}, ...
    %     {'lat', 'lon', 'bp'});
    % 
    % pinhasi = pinhasi(:,{'lat', 'lon', 'bp'});
    % pinhasi.bp = 2000 - pinhasi.bp; % from BP to year
    % 
    % parameters = data_prep(number_of_averages, active_layers, pinhasi.lat, pinhasi.lon, pinhasi.bp);
    
    % LOAD COBO et al

    cobo = readtable( ...
         'data/raw/cobo_etal/cobo_etal_data.xlsx');
    parameters = data_prep(number_of_averages, active_layers, cobo.Latitude, cobo.Longitude, cobo.Est_DateMean_BC_AD_);

    % data_prep creates parameters struct with the following fields:
    % parameters.A - initial matrix
    % parameters.T - number of time steps
    % parameters.terrain - terrain data
    % parameters.dataset_idx - matrix storing index coordinates of dataset sites
    % parameters.datset_lat - latitude of dataset sites
    % parameters.dataset_lon - longitude of dataset sites
    % parameters.dataset_bp - years before present of dataset sites
    % parameters.dt - time step in years
    % parameters.start_time - start time
    % parameters.end_time - end time
    % parameters.lat - first and last latitude
    % parameters.lon - first and last longitude
    % parameters.n - number of averages

    level = 2;

    save(filename,"level","parameters", '-append');

end

%% check speeds
    
if level < 3
    % identify earliest adoption point
    [min_time, min_idx] = min(parameters.dataset_idx(:,3));
    % calculate distance and time of datapoint relative to origin
    rel_times = parameters.dataset_idx(:,3) - min_time;
    rel_lat = parameters.dataset_idx(:,1) - parameters.dataset_idx(min_idx,1);
    rel_lon = parameters.dataset_idx(:,2) - parameters.dataset_idx(min_idx,2);
    distances = sqrt(rel_lat.^2 +rel_lon.^2);
    speeds = distances./rel_times;
    speeds = speeds(~isnan(speeds));
    
    figure (1)
    histogram(speeds,linspace(0,1,21))
    xlabel("Speed")
    ylabel('Frequency')
    title("Speed distribution")
    
    if mean(speeds) > 0.6
        disp("Speeds are too high, decrease the time step for convergence")
    elseif mean(speeds) < 0.2
        disp("Speeds are too low, increase the time step for better speed")
    else
        disp("Speeds are within acceptable range")
    end

    level = 3;

end

%% measure grid

if level < 4
    parameters.n = 20;
    [theta_start, on_edge, min_error, errors] = sweep(ranges, 6, 1, parameters);

    ranges = [0.15 1.15].*theta_start';  

    [theta_start, ~, min_error, errors] = sweep(ranges, 6, 1, parameters);

    parameters.n = number_of_averages;
    level = 4;

    if on_edge
        disp("Likely the given ranges are wrong")
    else
        disp('Local minimum found at '+ str(theta_start))
    end
    save(filename, 'theta_start', "level", "min_error", '-append')
end

%% Level 5 - run optimizer

function [error, grad, hessian] = optimize_model(theta, parameters, factor)
    result = run_model(parameters, theta);
    error = result.squared_error;
    if nargout > 1
        f = @(theta) run_model(parameters, theta).squared_error;
        grad = calculateGradient(f, theta, 0.001, factor);
    end
    if nargout > 2
        hessian = calculateHessian(f, theta, 0.001);
    end
end

function stop = saveIterations(x, optimValues, state)
    % Persistent variable to store the fitted parameters
    persistent paramsHistory

    % Initialize if the state is 'init'
    if strcmp(state, 'init')
        paramsHistory = []; % clear history at the beginning
    end

    % Append current parameters to the history during iterations
    if strcmp(state, 'iter')
        paramsHistory = [paramsHistory; x]; 
        assignin('base', 'paramsHistory', paramsHistory); % Save to workspace
    end

    % No stopping criterion
    stop = false;
end

if level < 5
parameters = data_prep(number_of_averages, active_layers, cobo.Latitude, cobo.Longitude, cobo.Est_DateMean_BC_AD_);

    factors = [1];
    all_params = {};
    for factor=factors
    
        objective_function = @(theta) optimize_model(theta, parameters, 1e6);
        theta_start = theta_start*factor;
        
        % WITH GRADIENT
        options = optimoptions('fminunc', ...
            'Display', 'iter', ...
            'Algorithm', 'trust-region', ...
            'HessianFcn','objective', ...
            'SpecifyObjectiveGradient',true, ...
            'StepTolerance', 5e-3*factor, ...,
            "FiniteDifferenceStepSize", 0.001*factor, ...,
            "FunctionTolerance",0.00001, ...
            "OptimalityTolerance",2e-6/factor, ...
            'MaxFunctionEvaluations', 10000, ...
            'MaxIterations', 10000, ...
            'OutputFcn', @saveIterations, ... % Call the custom function
            "UseParallel", true);

        % % WITHOUT GRADIENT
        % options = optimoptions('fminunc', ...
        %     'Display', 'iter', ...
        %     'Algorithm', 'quasi-newton', ...
        %     'SpecifyObjectiveGradient', false, ... % Use numerical gradients
        %     'HessianFcn', [], ... % Use numerical Hessian
        %     'MaxFunctionEvaluations', 10000, ...
        %     "FiniteDifferenceStepSize", 5e-2*factor, ...,
        %     'OutputFcn', @saveIterations, ... % Call the custom function
        %     'MaxIterations', 10000);
       
        % Run fminunc
        
        [theta, fval, exitflag, output, grad, hessian] = fminunc(objective_function, theta_start, options);

        
        theta = theta/factor;
        theta_start = theta_start/factor;
        
        result = run_model(parameters,theta);
        
        A = result.A;
        error = result.squared_error;
        times = result.times;

        all_params{length(all_params)+1} = paramsHistory;
        
        theta_start = theta;
        min_error = error;
        disp("New minimum found")
        disp('Optimized Parameters for factor '+string(factor)+':');
        disp(theta);

        theta_optim = theta_start;
    end

    level = 5;
    save(filename, 'theta_optim', "level", "min_error", "all_params", '-append')
end

%%
[error, grad, hessian] = optimize_model(theta_optim, parameters, 1);
parameters.calculate_W = true;
result = run_model(parameters,theta_optim);
parameters.calculate_W = false;
jacobian = grad*grad';
var_mat = 1/length(parameters.dataset_idx) * (hessian)^-1 * (jacobian) * (hessian)^-1;
standard_errors = sqrt(diag(var_mat))

%% report results
runtime = toc;
A = result.A;
final_errors = result.errors;
times = result.times;

disp('Final result:');
disp(theta_optim);

plot_map(parameters, final_errors, true)

save(filename, "result", '-append')

%% Bootstrapp

n_bootstraps = 50;

all_theta = zeros(n_bootstraps,length(theta_start));
factor = 1;
complete_dataset = parameters.dataset_idx;

parameters.calculate_W = false;

for i = 1:n_bootstraps
    % 
    rng('shuffle');
    parameters.U = rand(size(parameters.A));
    % n = size(complete_dataset, 1); % Number of points in the dataset
    % % Generate n random indices between 1 and n
    % random_indices = randi(n, n, 1);
    % % Use the indices to sample points from the dataset
    % sampled_dataset = complete_dataset(random_indices, :);
    % parameters.dataset_idx = sampled_dataset;


    objective_function = @(theta) optimize_model(theta, parameters, factor);
    % theta_start = theta_start*factor;

    options = optimoptions('fminunc', ...
            'Display', 'iter', ...
            'Algorithm', 'trust-region', ...
            'HessianFcn','objective', ...
            'SpecifyObjectiveGradient',true, ...
            'StepTolerance', 1e-4*factor, ...,
            "FiniteDifferenceStepSize", 0.1*factor, ...,
            "FunctionTolerance",0.00001, ...
            "OptimalityTolerance",2e-6/factor, ...
            'MaxFunctionEvaluations', 10000, ...
            'MaxIterations', 10000, ...
            'OutputFcn', @saveIterations, ... % Call the custom function
            "UseParallel", true);

    % Run fminunc
    
    [theta, fval, exitflag, output, grad, hessian] = fminunc(objective_function, theta_start, options);
    theta = theta/factor;
    
    result = run_model(parameters,theta);
    disp(result.squared_error)
    disp("New minimum found")
    disp(theta);
    all_theta(i,:) = theta;
end
save(filename, "all_theta", '-append')