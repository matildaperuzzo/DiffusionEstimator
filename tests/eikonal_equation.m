%% EIKONAL SPEED FIELD FITTING SCRIPT
% This script is a MATLAB translation of the provided Python workflow.
%
% The original Python script used:
%   - skfmm.travel_time(...) for fast marching solution of the eikonal equation
%   - scipy.optimize.minimize(...) with L-BFGS-B
%   - RegularGridInterpolator for interpolation
%
% This MATLAB version:
%   - Does NOT define custom functions.
%   - Runs sequentially as a script.
%   - Includes a distinct data-loading block at the top.
%   - Uses an inline fast-sweeping solver for the eikonal equation.
%   - Uses a simple finite-difference gradient descent optimizer.
%
% The eikonal equation being solved is:
%
%       |grad T(x,y)| = 1 / F(x,y)
%
% where:
%       T(x,y) = arrival time
%       F(x,y) = speed field
%
% The source region is a small disk around the origin, equivalent to:
%
%       sqrt(x^2 + y^2) - 0.1 = 0
%
% in the Python script.

clear;
clc;
close all;

%% ================================================================
%  DATA LOADING BLOCK
%  ================================================================
%  This block is intentionally separated from the rest of the script.
%  In later versions, replace this synthetic setup with external data
%  loading, for example:
%
%       loaded_data = load("my_data.mat");
%       observation_points = loaded_data.observation_points;
%       observed_arrival_times = loaded_data.observed_arrival_times;
%
%  For now, this block defines the synthetic numerical experiment.

fprintf("Initializing simulation...\n");

% Random seed, equivalent to np.random.seed(42)
rng(42);

% Number of grid points in x and y
num_points_x = 101;
num_points_y = 101;

% Coordinate ranges
x_min = -1.0;
x_max =  3.0;

y_min = -2.0;
y_max =  2.0;

% Number of synthetic observation samples
num_samples = 200;

% Observation region
observation_x_min = -0.5;
observation_x_max =  2.5;

observation_y_min = -1.5;
observation_y_max =  1.5;

% Ground-truth source radius
source_radius = 0.1;

% Ground-truth speed values
background_speed = 1.0;
slow_region_speed = 0.5;
fast_region_speed = 2.0;

% Ground-truth circular perturbation locations
slow_region_center_x = 2.0;
slow_region_center_y = 0.0;
slow_region_radius   = 0.8;

fast_region_center_x = 0.0;
fast_region_center_y = -1.0;
fast_region_radius   = 0.8;

% Gaussian basis settings
num_basis_per_axis = 4;
basis_sigma = 0.5;

% Speed model settings
base_speed = 1.0;
min_speed = 0.01;

% Optimization settings
max_optimization_iterations = 50;
finite_difference_epsilon = 1e-2;
initial_learning_rate = 0.5;

% Fast-sweeping settings
% Larger values give more accurate travel times but slower optimization.
num_fast_sweeping_iterations = 80;

%% ================================================================
%  CREATE COORDINATE GRID
%  ================================================================

% Create x and y coordinate vectors
x_coordinates = linspace(x_min, x_max, num_points_x);
y_coordinates = linspace(y_min, y_max, num_points_y);

% Create 2D coordinate arrays
% grid_x and grid_y match the shape convention of Python np.meshgrid:
% rows correspond to y, columns correspond to x.
[grid_x, grid_y] = meshgrid(x_coordinates, y_coordinates);

% Grid spacing
dx = x_coordinates(2) - x_coordinates(1);
dy = y_coordinates(2) - y_coordinates(1);

% This script assumes square grid cells for the fast-sweeping update.
% In this setup dx == dy.
if abs(dx - dy) > 1e-12
    error("This script currently assumes dx == dy.");
end

grid_spacing = dx;

% Store grid size
[num_rows, num_cols] = size(grid_x);

%% ================================================================
%  BUILD GROUND-TRUTH SPEED FIELD
%  ================================================================

% Start from a uniform background speed
ground_truth_speed = background_speed * ones(size(grid_x));

% Define the slower circular region
slow_region_mask = sqrt((grid_x - slow_region_center_x).^2 + ...
                        (grid_y - slow_region_center_y).^2) < slow_region_radius;

% Define the faster circular region
fast_region_mask = sqrt((grid_x - fast_region_center_x).^2 + ...
                        (grid_y - fast_region_center_y).^2) < fast_region_radius;

% Assign speeds inside the circular regions
ground_truth_speed(slow_region_mask) = slow_region_speed;
ground_truth_speed(fast_region_mask) = fast_region_speed;

%% ================================================================
%  SOLVE GROUND-TRUTH ARRIVAL TIMES
%  ================================================================
%  This block replaces:
%
%       ground_truth_times = solve_travel_time(ground_truth_speed, grid_spacing)
%
%  from the Python code.
%
%  The solver below is a simple fast-sweeping method for:
%
%       |grad T| = 1 / speed
%
%  with T = 0 inside the source disk.

% Define source region
source_mask = sqrt(grid_x.^2 + grid_y.^2) <= source_radius;

% Initialize arrival time field
ground_truth_times = inf(size(grid_x));

% Arrival time is zero inside the source region
ground_truth_times(source_mask) = 0;

% Slowness is the reciprocal of speed
ground_truth_slowness = 1 ./ ground_truth_speed;

% Perform repeated directional sweeps through the grid
for sweep_iteration = 1:num_fast_sweeping_iterations

    % Sweep 1: top-left to bottom-right
    for i = 2:num_rows-1
        for j = 2:num_cols-1

            if source_mask(i,j)
                continue;
            end

            a = min(ground_truth_times(i,j-1), ground_truth_times(i,j+1));
            b = min(ground_truth_times(i-1,j), ground_truth_times(i+1,j));
            s = grid_spacing * ground_truth_slowness(i,j);

            if abs(a - b) >= s
                candidate_time = min(a,b) + s;
            else
                candidate_time = 0.5 * (a + b + sqrt(max(0, 2*s^2 - (a-b)^2)));
            end

            ground_truth_times(i,j) = min(ground_truth_times(i,j), candidate_time);
        end
    end

    % Sweep 2: top-right to bottom-left
    for i = 2:num_rows-1
        for j = num_cols-1:-1:2

            if source_mask(i,j)
                continue;
            end

            a = min(ground_truth_times(i,j-1), ground_truth_times(i,j+1));
            b = min(ground_truth_times(i-1,j), ground_truth_times(i+1,j));
            s = grid_spacing * ground_truth_slowness(i,j);

            if abs(a - b) >= s
                candidate_time = min(a,b) + s;
            else
                candidate_time = 0.5 * (a + b + sqrt(max(0, 2*s^2 - (a-b)^2)));
            end

            ground_truth_times(i,j) = min(ground_truth_times(i,j), candidate_time);
        end
    end

    % Sweep 3: bottom-left to top-right
    for i = num_rows-1:-1:2
        for j = 2:num_cols-1

            if source_mask(i,j)
                continue;
            end

            a = min(ground_truth_times(i,j-1), ground_truth_times(i,j+1));
            b = min(ground_truth_times(i-1,j), ground_truth_times(i+1,j));
            s = grid_spacing * ground_truth_slowness(i,j);

            if abs(a - b) >= s
                candidate_time = min(a,b) + s;
            else
                candidate_time = 0.5 * (a + b + sqrt(max(0, 2*s^2 - (a-b)^2)));
            end

            ground_truth_times(i,j) = min(ground_truth_times(i,j), candidate_time);
        end
    end

    % Sweep 4: bottom-right to top-left
    for i = num_rows-1:-1:2
        for j = num_cols-1:-1:2

            if source_mask(i,j)
                continue;
            end

            a = min(ground_truth_times(i,j-1), ground_truth_times(i,j+1));
            b = min(ground_truth_times(i-1,j), ground_truth_times(i+1,j));
            s = grid_spacing * ground_truth_slowness(i,j);

            if abs(a - b) >= s
                candidate_time = min(a,b) + s;
            else
                candidate_time = 0.5 * (a + b + sqrt(max(0, 2*s^2 - (a-b)^2)));
            end

            ground_truth_times(i,j) = min(ground_truth_times(i,j), candidate_time);
        end
    end
end

%% ================================================================
%  GENERATE SYNTHETIC OBSERVATION POINTS
%  ================================================================

% Sample random x coordinates
observation_x = observation_x_min + ...
    (observation_x_max - observation_x_min) * rand(num_samples, 1);

% Sample random y coordinates
observation_y = observation_y_min + ...
    (observation_y_max - observation_y_min) * rand(num_samples, 1);

% Combine into an N-by-2 matrix:
% column 1 = x
% column 2 = y
observation_points = [observation_x, observation_y];

% Interpolate ground-truth arrival times at observation locations.
% MATLAB interp2 expects:
%
%       interp2(X, Y, V, Xq, Yq)
%
% where X and Y are meshgrid arrays.
observed_arrival_times = interp2( ...
    grid_x, ...
    grid_y, ...
    ground_truth_times, ...
    observation_points(:,1), ...
    observation_points(:,2), ...
    "linear" ...
);

%% ================================================================
%  GENERATE GAUSSIAN BASIS FUNCTIONS
%  ================================================================

% Gaussian basis center locations
center_locations_x = linspace(-0.5, 2.5, num_basis_per_axis);
center_locations_y = linspace(-1.5, 1.5, num_basis_per_axis);

% Create grid of basis centers
[centers_grid_x, centers_grid_y] = meshgrid(center_locations_x, center_locations_y);

% Flatten basis centers into a list
basis_centers_x = centers_grid_x(:);
basis_centers_y = centers_grid_y(:);

% Number of basis functions
num_basis_functions = numel(basis_centers_x);

% Store basis functions in a 3D array:
%
%       basis_functions(row, col, basis_index)
%
basis_functions = zeros(num_rows, num_cols, num_basis_functions);

% Construct each Gaussian basis function
for basis_index = 1:num_basis_functions

    center_x = basis_centers_x(basis_index);
    center_y = basis_centers_y(basis_index);

    squared_distance = (grid_x - center_x).^2 + (grid_y - center_y).^2;

    basis_functions(:,:,basis_index) = exp(-squared_distance / (2 * basis_sigma^2));
end

%% ================================================================
%  OPTIMIZE SPEED FIELD PARAMETERS
%  ================================================================
%  Python version used scipy.optimize.minimize with L-BFGS-B.
%
%  To keep this as a pure sequential MATLAB script with no custom
%  functions, this version uses finite-difference gradient descent
%  with a simple backtracking line search.
%
%  Model:
%
%       speed(x,y) = max(base_speed + sum_k weight_k * basis_k(x,y), min_speed)
%
%  Loss:
%
%       mean((predicted_arrival_times_at_data - observed_arrival_times).^2)

fprintf("Fitting model parameters...\n");

% Initialize weights to zero
weights = zeros(num_basis_functions, 1);

% Initialize previous loss
current_loss = inf;

% Main optimization loop
for optimization_iteration = 1:max_optimization_iterations

    % ------------------------------------------------------------
    %  Evaluate current model speed field
    %  ------------------------------------------------------------

    current_speed = base_speed * ones(size(grid_x));

    for basis_index = 1:num_basis_functions
        current_speed = current_speed + weights(basis_index) * basis_functions(:,:,basis_index);
    end

    % Enforce positive minimum speed
    current_speed = max(current_speed, min_speed);

    % ------------------------------------------------------------
    %  Solve arrival times for current speed field
    %  ------------------------------------------------------------

    current_times = inf(size(grid_x));
    current_times(source_mask) = 0;

    current_slowness = 1 ./ current_speed;

    for sweep_iteration = 1:num_fast_sweeping_iterations

        for i = 2:num_rows-1
            for j = 2:num_cols-1

                if source_mask(i,j)
                    continue;
                end

                a = min(current_times(i,j-1), current_times(i,j+1));
                b = min(current_times(i-1,j), current_times(i+1,j));
                s = grid_spacing * current_slowness(i,j);

                if abs(a - b) >= s
                    candidate_time = min(a,b) + s;
                else
                    candidate_time = 0.5 * (a + b + sqrt(max(0, 2*s^2 - (a-b)^2)));
                end

                current_times(i,j) = min(current_times(i,j), candidate_time);
            end
        end

        for i = 2:num_rows-1
            for j = num_cols-1:-1:2

                if source_mask(i,j)
                    continue;
                end

                a = min(current_times(i,j-1), current_times(i,j+1));
                b = min(current_times(i-1,j), current_times(i+1,j));
                s = grid_spacing * current_slowness(i,j);

                if abs(a - b) >= s
                    candidate_time = min(a,b) + s;
                else
                    candidate_time = 0.5 * (a + b + sqrt(max(0, 2*s^2 - (a-b)^2)));
                end

                current_times(i,j) = min(current_times(i,j), candidate_time);
            end
        end

        for i = num_rows-1:-1:2
            for j = 2:num_cols-1

                if source_mask(i,j)
                    continue;
                end

                a = min(current_times(i,j-1), current_times(i,j+1));
                b = min(current_times(i-1,j), current_times(i+1,j));
                s = grid_spacing * current_slowness(i,j);

                if abs(a - b) >= s
                    candidate_time = min(a,b) + s;
                else
                    candidate_time = 0.5 * (a + b + sqrt(max(0, 2*s^2 - (a-b)^2)));
                end

                current_times(i,j) = min(current_times(i,j), candidate_time);
            end
        end

        for i = num_rows-1:-1:2
            for j = num_cols-1:-1:2

                if source_mask(i,j)
                    continue;
                end

                a = min(current_times(i,j-1), current_times(i,j+1));
                b = min(current_times(i-1,j), current_times(i+1,j));
                s = grid_spacing * current_slowness(i,j);

                if abs(a - b) >= s
                    candidate_time = min(a,b) + s;
                else
                    candidate_time = 0.5 * (a + b + sqrt(max(0, 2*s^2 - (a-b)^2)));
                end

                current_times(i,j) = min(current_times(i,j), candidate_time);
            end
        end
    end

    %% ------------------------------------------------------------
    %  Compute current loss
    %  ------------------------------------------------------------

    predicted_at_observation = interp2( ...
        grid_x, ...
        grid_y, ...
        current_times, ...
        observation_points(:,1), ...
        observation_points(:,2), ...
        "linear" ...
    );

    residuals = predicted_at_observation - observed_arrival_times;
    current_loss = mean(residuals.^2);

    %% ------------------------------------------------------------
    %  Estimate finite-difference gradient
    %  ------------------------------------------------------------

    gradient = zeros(num_basis_functions, 1);

    for gradient_index = 1:num_basis_functions

        % Perturb one weight
        perturbed_weights = weights;
        perturbed_weights(gradient_index) = perturbed_weights(gradient_index) + finite_difference_epsilon;

        % Build perturbed speed field
        perturbed_speed = base_speed * ones(size(grid_x));

        for basis_index = 1:num_basis_functions
            perturbed_speed = perturbed_speed + perturbed_weights(basis_index) * basis_functions(:,:,basis_index);
        end

        perturbed_speed = max(perturbed_speed, min_speed);

        % Solve perturbed arrival times
        perturbed_times = inf(size(grid_x));
        perturbed_times(source_mask) = 0;

        perturbed_slowness = 1 ./ perturbed_speed;

        for sweep_iteration = 1:num_fast_sweeping_iterations

            for i = 2:num_rows-1
                for j = 2:num_cols-1

                    if source_mask(i,j)
                        continue;
                    end

                    a = min(perturbed_times(i,j-1), perturbed_times(i,j+1));
                    b = min(perturbed_times(i-1,j), perturbed_times(i+1,j));
                    s = grid_spacing * perturbed_slowness(i,j);

                    if abs(a - b) >= s
                        candidate_time = min(a,b) + s;
                    else
                        candidate_time = 0.5 * (a + b + sqrt(max(0, 2*s^2 - (a-b)^2)));
                    end

                    perturbed_times(i,j) = min(perturbed_times(i,j), candidate_time);
                end
            end

            for i = 2:num_rows-1
                for j = num_cols-1:-1:2

                    if source_mask(i,j)
                        continue;
                    end

                    a = min(perturbed_times(i,j-1), perturbed_times(i,j+1));
                    b = min(perturbed_times(i-1,j), perturbed_times(i+1,j));
                    s = grid_spacing * perturbed_slowness(i,j);

                    if abs(a - b) >= s
                        candidate_time = min(a,b) + s;
                    else
                        candidate_time = 0.5 * (a + b + sqrt(max(0, 2*s^2 - (a-b)^2)));
                    end

                    perturbed_times(i,j) = min(perturbed_times(i,j), candidate_time);
                end
            end

            for i = num_rows-1:-1:2
                for j = 2:num_cols-1

                    if source_mask(i,j)
                        continue;
                    end

                    a = min(perturbed_times(i,j-1), perturbed_times(i,j+1));
                    b = min(perturbed_times(i-1,j), perturbed_times(i+1,j));
                    s = grid_spacing * perturbed_slowness(i,j);

                    if abs(a - b) >= s
                        candidate_time = min(a,b) + s;
                    else
                        candidate_time = 0.5 * (a + b + sqrt(max(0, 2*s^2 - (a-b)^2)));
                    end

                    perturbed_times(i,j) = min(perturbed_times(i,j), candidate_time);
                end
            end

            for i = num_rows-1:-1:2
                for j = num_cols-1:-1:2

                    if source_mask(i,j)
                        continue;
                    end

                    a = min(perturbed_times(i,j-1), perturbed_times(i,j+1));
                    b = min(perturbed_times(i-1,j), perturbed_times(i+1,j));
                    s = grid_spacing * perturbed_slowness(i,j);

                    if abs(a - b) >= s
                        candidate_time = min(a,b) + s;
                    else
                        candidate_time = 0.5 * (a + b + sqrt(max(0, 2*s^2 - (a-b)^2)));
                    end

                    perturbed_times(i,j) = min(perturbed_times(i,j), candidate_time);
                end
            end
        end

        % Evaluate perturbed loss
        perturbed_prediction = interp2( ...
            grid_x, ...
            grid_y, ...
            perturbed_times, ...
            observation_points(:,1), ...
            observation_points(:,2), ...
            "linear" ...
        );

        perturbed_residuals = perturbed_prediction - observed_arrival_times;
        perturbed_loss = mean(perturbed_residuals.^2);

        % Forward finite-difference derivative
        gradient(gradient_index) = ...
            (perturbed_loss - current_loss) / finite_difference_epsilon;
    end

    %% ------------------------------------------------------------
    %  Backtracking gradient step
    %  ------------------------------------------------------------

    learning_rate = initial_learning_rate;
    accepted_step = false;

    while learning_rate > 1e-6

        trial_weights = weights - learning_rate * gradient;

        % Build trial speed field
        trial_speed = base_speed * ones(size(grid_x));

        for basis_index = 1:num_basis_functions
            trial_speed = trial_speed + trial_weights(basis_index) * basis_functions(:,:,basis_index);
        end

        trial_speed = max(trial_speed, min_speed);

        % Solve trial arrival times
        trial_times = inf(size(grid_x));
        trial_times(source_mask) = 0;

        trial_slowness = 1 ./ trial_speed;

        for sweep_iteration = 1:num_fast_sweeping_iterations

            for i = 2:num_rows-1
                for j = 2:num_cols-1

                    if source_mask(i,j)
                        continue;
                    end

                    a = min(trial_times(i,j-1), trial_times(i,j+1));
                    b = min(trial_times(i-1,j), trial_times(i+1,j));
                    s = grid_spacing * trial_slowness(i,j);

                    if abs(a - b) >= s
                        candidate_time = min(a,b) + s;
                    else
                        candidate_time = 0.5 * (a + b + sqrt(max(0, 2*s^2 - (a-b)^2)));
                    end

                    trial_times(i,j) = min(trial_times(i,j), candidate_time);
                end
            end

            for i = 2:num_rows-1
                for j = num_cols-1:-1:2

                    if source_mask(i,j)
                        continue;
                    end

                    a = min(trial_times(i,j-1), trial_times(i,j+1));
                    b = min(trial_times(i-1,j), trial_times(i+1,j));
                    s = grid_spacing * trial_slowness(i,j);

                    if abs(a - b) >= s
                        candidate_time = min(a,b) + s;
                    else
                        candidate_time = 0.5 * (a + b + sqrt(max(0, 2*s^2 - (a-b)^2)));
                    end

                    trial_times(i,j) = min(trial_times(i,j), candidate_time);
                end
            end

            for i = num_rows-1:-1:2
                for j = 2:num_cols-1

                    if source_mask(i,j)
                        continue;
                    end

                    a = min(trial_times(i,j-1), trial_times(i,j+1));
                    b = min(trial_times(i-1,j), trial_times(i+1,j));
                    s = grid_spacing * trial_slowness(i,j);

                    if abs(a - b) >= s
                        candidate_time = min(a,b) + s;
                    else
                        candidate_time = 0.5 * (a + b + sqrt(max(0, 2*s^2 - (a-b)^2)));
                    end

                    trial_times(i,j) = min(trial_times(i,j), candidate_time);
                end
            end

            for i = num_rows-1:-1:2
                for j = num_cols-1:-1:2

                    if source_mask(i,j)
                        continue;
                    end

                    a = min(trial_times(i,j-1), trial_times(i,j+1));
                    b = min(trial_times(i-1,j), trial_times(i+1,j));
                    s = grid_spacing * trial_slowness(i,j);

                    if abs(a - b) >= s
                        candidate_time = min(a,b) + s;
                    else
                        candidate_time = 0.5 * (a + b + sqrt(max(0, 2*s^2 - (a-b)^2)));
                    end

                    trial_times(i,j) = min(trial_times(i,j), candidate_time);
                end
            end
        end

        % Compute trial loss
        trial_prediction = interp2( ...
            grid_x, ...
            grid_y, ...
            trial_times, ...
            observation_points(:,1), ...
            observation_points(:,2), ...
            "linear" ...
        );

        trial_residuals = trial_prediction - observed_arrival_times;
        trial_loss = mean(trial_residuals.^2);

        % Accept step only if it improves the loss
        if trial_loss < current_loss
            weights = trial_weights;
            current_loss = trial_loss;
            accepted_step = true;
            break;
        else
            learning_rate = learning_rate * 0.5;
        end
    end

    fprintf( ...
        "Iteration %3d / %3d | Loss = %.6f | Step accepted = %d | Learning rate = %.3e\n", ...
        optimization_iteration, ...
        max_optimization_iterations, ...
        current_loss, ...
        accepted_step, ...
        learning_rate ...
    );

    % If no improving step was found, stop early.
    if ~accepted_step
        fprintf("Stopping early because no improving step was found.\n");
        break;
    end
end

fprintf("Optimization complete. Final loss: %.4f\n", current_loss);

%% ================================================================
%  BUILD RECOVERED SPEED FIELD
%  ================================================================

recovered_speed = base_speed * ones(size(grid_x));

for basis_index = 1:num_basis_functions
    recovered_speed = recovered_speed + weights(basis_index) * basis_functions(:,:,basis_index);
end

recovered_speed = max(recovered_speed, min_speed);

%% ================================================================
%  SOLVE RECOVERED ARRIVAL TIMES
%  ================================================================

recovered_times = inf(size(grid_x));
recovered_times(source_mask) = 0;

recovered_slowness = 1 ./ recovered_speed;

for sweep_iteration = 1:num_fast_sweeping_iterations

    for i = 2:num_rows-1
        for j = 2:num_cols-1

            if source_mask(i,j)
                continue;
            end

            a = min(recovered_times(i,j-1), recovered_times(i,j+1));
            b = min(recovered_times(i-1,j), recovered_times(i+1,j));
            s = grid_spacing * recovered_slowness(i,j);

            if abs(a - b) >= s
                candidate_time = min(a,b) + s;
            else
                candidate_time = 0.5 * (a + b + sqrt(max(0, 2*s^2 - (a-b)^2)));
            end

            recovered_times(i,j) = min(recovered_times(i,j), candidate_time);
        end
    end

    for i = 2:num_rows-1
        for j = num_cols-1:-1:2

            if source_mask(i,j)
                continue;
            end

            a = min(recovered_times(i,j-1), recovered_times(i,j+1));
            b = min(recovered_times(i-1,j), recovered_times(i+1,j));
            s = grid_spacing * recovered_slowness(i,j);

            if abs(a - b) >= s
                candidate_time = min(a,b) + s;
            else
                candidate_time = 0.5 * (a + b + sqrt(max(0, 2*s^2 - (a-b)^2)));
            end

            recovered_times(i,j) = min(recovered_times(i,j), candidate_time);
        end
    end

    for i = num_rows-1:-1:2
        for j = 2:num_cols-1

            if source_mask(i,j)
                continue;
            end

            a = min(recovered_times(i,j-1), recovered_times(i,j+1));
            b = min(recovered_times(i-1,j), recovered_times(i+1,j));
            s = grid_spacing * recovered_slowness(i,j);

            if abs(a - b) >= s
                candidate_time = min(a,b) + s;
            else
                candidate_time = 0.5 * (a + b + sqrt(max(0, 2*s^2 - (a-b)^2)));
            end

            recovered_times(i,j) = min(recovered_times(i,j), candidate_time);
        end
    end

    for i = num_rows-1:-1:2
        for j = num_cols-1:-1:2

            if source_mask(i,j)
                continue;
            end

            a = min(recovered_times(i,j-1), recovered_times(i,j+1));
            b = min(recovered_times(i-1,j), recovered_times(i+1,j));
            s = grid_spacing * recovered_slowness(i,j);

            if abs(a - b) >= s
                candidate_time = min(a,b) + s;
            else
                candidate_time = 0.5 * (a + b + sqrt(max(0, 2*s^2 - (a-b)^2)));
            end

            recovered_times(i,j) = min(recovered_times(i,j), candidate_time);
        end
    end
end

%% ================================================================
%  FIGURE 1: GROUND TRUTH, RECOVERED SPEED, ARRIVAL-TIME ERROR
%  ================================================================

figure("Position", [100, 100, 1500, 500]);

% ------------------------------------------------
% Plot ground-truth speed
% ------------------------------------------------
subplot(1,3,1);
contourf(grid_x, grid_y, ground_truth_speed, 20, "LineColor", "none");
title("Ground Truth Speed");
xlabel("x");
ylabel("y");
colorbar;
axis equal tight;
hold on;

scatter( ...
    observation_points(:,1), ...
    observation_points(:,2), ...
    10, ...
    "r", ...
    "filled", ...
    "DisplayName", "Data points" ...
);

legend;

% ------------------------------------------------
% Plot recovered speed
% ------------------------------------------------
subplot(1,3,2);
contourf(grid_x, grid_y, recovered_speed, 20, "LineColor", "none");
title("Recovered Speed");
xlabel("x");
ylabel("y");
colorbar;
axis equal tight;

% ------------------------------------------------
% Plot absolute arrival-time error
% ------------------------------------------------
subplot(1,3,3);
arrival_time_error = abs(recovered_times - ground_truth_times);
contourf(grid_x, grid_y, arrival_time_error, 20, "LineColor", "none");
title("Recovered Arrival Time Error");
xlabel("x");
ylabel("y");
colorbar;
axis equal tight;

% Save figure
saveas(gcf, "eikonal_fit_result.png");

fprintf("Result saved to eikonal_fit_result.png\n");

%% ================================================================
%  FIGURE 2: MODEL VS DATA
%  ================================================================

figure("Position", [100, 100, 800, 600]);

title("Model vs Data");
xlabel("x");
ylabel("y");
hold on;

% Define color limits
vmin = 0;
vmax = max(observed_arrival_times) * 1.1;

% Define contour levels
levels = linspace(vmin, vmax, 26);

% Plot recovered arrival-time contours
contour( ...
    grid_x, ...
    grid_y, ...
    recovered_times, ...
    levels, ...
    "LineWidth", ...
    1.0 ...
);

% Plot observation points, colored by observed arrival time
scatter_handle = scatter( ...
    observation_points(:,1), ...
    observation_points(:,2), ...
    50, ...
    observed_arrival_times, ...
    "filled", ...
    "MarkerEdgeColor", ...
    "k", ...
    "DisplayName", ...
    "Spatiotemporal data (x,t)" ...
);

% Apply color scaling
clim([vmin, vmax]);

% Add colorbar
colorbar_handle = colorbar;
ylabel(colorbar_handle, "Arrival Time Model T(x)");

legend;

axis equal tight;

% Save figure
saveas(gcf, "arrival_time_summary.png");

fprintf("Summary saved to arrival_time_summary.png\n");