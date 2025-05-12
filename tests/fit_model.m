%% Start new run 

clear all
addpath("..\")
addpath("src")
tic
t = datetime;
t.Format = 'yyyy-MM-dd_HH-mm';
% choose whether to load or start
load_data = false;
get_errors = false;

%%
if load_data == false

    number_of_averages = 100;
    dataset = 'maize'; %options: 'cobo','pinhasi','all_wheat'
    layers = {'av','csi','sea'}; %full {'av' 'asym' 'csi','hydro' 'prec' 'tmean'}
    directory = 'generated_data/';

    %create filename
    filename = [directory dataset '_'];
    filename = [filename strjoin(layers,'_') '_'];
    filename = [filename string(number_of_averages) 'av_'];
    filename = [filename string(t)];
    filename = strjoin(filename,'');

    level = 0;
    
    save(filename, 'number_of_averages','layers','filename');

end

%% Load existing run

if load_data
    % filename
    load(filename);
    
    load_data= true;
end

%% choose geographical layers

if level < 1
    
    % Average diffusion
    if ismember('av',layers)
        average_range = [-1.0, 1.0];
    else
        average_range = [0.0, 0.0];
    end
    if ismember('asym',layers)
        anisotropy_range = [-2, 2];
    else
        anisotropy_range = [0.0, 0.0];
    end
    % csi
    if ismember('csi', layers)
        csi_range = [-1.0, 1.0];
    else
        csi_range = [-0.0, 0.0]; 
    end
    % hydro
    if ismember('hydro', layers)
        hydro_range = [-1, 1];
    else
        hydro_range = [0.0, 0.0];
    end
    % precipitation
    if ismember('prec', layers)
        prec_range = [-2, 2];
    else
        prec_range = [0.0, 0.0];
    end
    % mean temp
    if ismember('tmean',layers)
        tmean_range = [-1, 1];
    else
        tmean_range = [.0, .0];
    end

    if ismember('sea',layers)
        sea_range = [-1, 1];
    else
        sea_range = [0., 0.];
    end

    ranges = [average_range; anisotropy_range; csi_range; hydro_range; prec_range; tmean_range; sea_range];

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

    [x,y,t] = get_dataset(dataset);

    parameters = data_prep(number_of_averages, active_layers, x, y, t);
    
    if strcmp(dataset,'cobo')
        parameters.A(76,39,46) = true;
    end
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

%% add additional layers

% active_layers = [active_layers 1];
% parameters.active_layers = active_layers;
% ranges = [ranges; [-2 2]];
% temp_params = data_prep(1, [0 0 0 0 1 0 1], x, y, t);
% new_layer = temp_params.X{1}.*temp_params.X{2};
% 
% % remove sea from prec layer
% parameters.X{1} = parameters.X{1}.*(1-temp_params.X{2});
% parameters.X{2} = new_layer;

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
    [theta_start, on_edge, min_error, errors] = sweep(ranges, 11, 2, parameters);

    ranges = [0.8 1.2].*theta_start';  

    [theta_start, on_edge, min_error, errors] = sweep(ranges, 11, 1, parameters);

    parameters.n = number_of_averages;
    level = 4;

    if on_edge
        disp("Likely the given ranges are wrong")
    else
        disp('Local minimum found')
    end
    save(filename, 'theta_start', "level", "min_error", '-append')
end

%% Level 5 - run optimizer

if level < 5
    tic
    % parameters = data_prep(number_of_averages, active_layers, x, y, t);
    factors = [1e7];
    all_params = {};
    for factor=factors
    
        objective_function = @(theta) optimize_model(theta, parameters, factor);
        theta_start = theta_start;
        
        % WITH GRADIENT
        options = optimoptions('fminunc', ...
            'Display', 'iter', ...
            'Algorithm', 'trust-region', ...
            'HessianFcn','objective', ...
            'SpecifyObjectiveGradient',true, ...
            'StepTolerance', 5e-3, ...,
            "FiniteDifferenceStepSize", 0.001, ...,
            "FunctionTolerance",0.00001, ...
            "OptimalityTolerance",2e-6, ...
            'MaxFunctionEvaluations', 10000, ...
            'MaxIterations', 10000, ...
            'OutputFcn', @saveIterations, ... % Call the custom function
            "UseParallel", false);
        
        [theta, fval, exitflag, output, grad, hessian] = fminunc(objective_function, theta_start, options);

        
        theta = theta;
        theta_start = theta_start;
        
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
    disp(toc)
end

%%
% [error, grad, hessian] = optimize_model(theta_optim, parameters, 1);
% parameters.calculate_W = true;
% result = run_model(parameters,theta_optim);
% parameters.calculate_W = false;
% jacobian = grad*grad';
% var_mat = 1/length(parameters.dataset_idx) * (hessian)^-1 * (jacobian) * (hessian)^-1;
% standard_errors = sqrt(diag(var_mat))

%% report results
result = run_model(parameters,theta_optim);
runtime = toc;
A = result.A;
final_errors = result.errors;
times = result.times;

theta_str = sprintf("%s", strip(strip(sprintf("%.2f, ", theta_optim), " "),","));
disp('Final result: ['+theta_str+']');

probabilities = 1./(1 + exp(- (theta_optim)));
prob_str = sprintf("%s", strip(strip(sprintf("%.2f, ", probabilities), " "),","));
disp('Probabilities: ['+prob_str+']');

speed_str = sprintf("%s", strip(strip(sprintf("%.2f, ", probabilities*110.567/4), " "),","));
disp('Speeds (km/decade): ['+speed_str+']');

disp('Squared error: ' + string(result.squared_error))
disp('Error in years: ' + string(sqrt(mean(result.squared_error))))

save(filename, "result", '-append')

plot_map(parameters, final_errors, true)

%% Bootstrapp

if get_errors
    n_bootstraps = 50;
    
    all_theta = zeros(n_bootstraps,length(theta_start));
    all_errors = zeros(n_bootstraps, 1);
    factor = 1;
    complete_dataset = parameters.dataset_idx;
    
    parameters.calculate_W = false;
    if isfield(parameters,'random')
        parameters = parameters.rmfield(parameters, random);
    end
    
    for i = 1:n_bootstraps
        % 
        parameters.random = 10+3*i-1;
    
        objective_function = @(theta) optimize_model(theta, parameters, factor);
    
        options = optimoptions('fminunc', ...
            'Display', 'iter', ...
            'Algorithm', 'trust-region', ...
            'HessianFcn','objective', ...
            'SpecifyObjectiveGradient',true, ...
            'StepTolerance', 5e-3, ...,
            "FiniteDifferenceStepSize", 0.001, ...,
            "FunctionTolerance",0.00001, ...
            "OptimalityTolerance",2e-6, ...
            'MaxFunctionEvaluations', 10000, ...
            'MaxIterations', 10000, ...
            'OutputFcn', @saveIterations, ... % Call the custom function
            "UseParallel", false);
    
        % Run fminunc
    
        [theta, fval, exitflag, output, grad, hessian] = fminunc(objective_function, theta_start, options);
    
        result = run_model(parameters,theta);
        disp(result.squared_error)
        disp("New minimum found")
        disp(theta);
        all_theta(i,:) = theta;
        all_errors(i) = result.squared_error;
    end
    save(filename, "all_theta", "all_errors", '-append')
end