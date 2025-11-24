clear
clc


% Add the directory containing run_model.m to the MATLAB path
addpath('src');
rng(12) % set random seed
n_averages = [1,5,10,50,100,200,500,1000,1000]; 

theta_0 = 0.0;
theta_1 = 0.0;
theta_2 = linspace(0.1,0.5,51);
active_layers = [1 1 1 0];

errors = zeros(length(n_averages),length(theta_2));

for n=1:length(n_averages)
    disp("Starting test with "+string(n_averages(n))+" averages")
    % choose whether to load pinhasi dataset or create a dataset
    parameters = data_prep(n_averages(n), active_layers);
    % theory_theta = [0.15 0.05 0.1];
    % parameters = create_dataset(theory_theta, 20, [53.0627, 43.6865]);
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
    errors_single = [];
    for th_2 = 1:length(theta_2)
        theta = [theta_0, theta_1, theta_2(th_2)];

        result = run_model(parameters, theta);
        error(n,th_2) = result.squared_error;

    end

end

%% Plots

figure;
hold on;

% Create a colormap with as many colors as there are lines to plot
cmap = copper(length(n_averages));

% Loop through each n and plot with corresponding color
for n = 1:length(n_averages)
    plot(theta_2, error(n, :), 'Color', cmap(n, :), 'DisplayName', ['N_{av} ' num2str(n_averages(n))]);
end

% Add legend
legend('show', 'Location', 'best');

% Optional: Add labels and a title
xlabel('\theta_2');
ylabel('Error');
title('Error vs \theta_2 for different averages');

hold off;

%%

errors = error-error(length(n_averages),:);

figure
hold on;
semilogx(n_averages, mean(abs(errors')))
semilogx(n_averages, mean(abs(errors')),'.')
xlim([1,1000])
xlabel("n_{av}")
ylabel("mean absolute error")