active_layers = [1 0 1  0 0 1 0 0];
% load pinhasi
pinhasi = readtable( ...
    'data/raw/pinhasi/Neolithic_timing_Europe_PLOS.xls');

pinhasi = pinhasi(pinhasi.Var1 == "SITE",:); %% keep only site rows

pinhasi = renamevars(pinhasi, {'Latitude', 'Longitude', 'CALC14BP'}, ...
    {'lat', 'lon', 'bp'});

pinhasi = pinhasi(:,{'lat', 'lon', 'bp'});
pinhasi.bp = 2000 - pinhasi.bp; % from BP to year

x = pinhasi.lat;
y = pinhasi.lon;
t = pinhasi.bp;
parameters = data_prep(50, active_layers, x,y,t);


theta = [-1.8200   -0.4600    2.3000];


result = run_model(parameters, theta);

[min_time, min_idx] = min(parameters.dataset_idx(:,3));

%%


function [x,y,c] = get_plot_coords(parameters, result)
    % Define the three colors (RGB format):
    color1 = [30/255, 51/255, 110/255];   % Blue
    color2 = [235/255, 232/255, 198/255];   % White
    color3 = [110/255, 20/255, 30/255];   % Red
    
    % Number of points in your colormap:
    numColors = 256; 
    
    % Create a colormap by interpolating between these colors:
    cmap = interp1([1, 128, 256], [color1; color2; color3], linspace(1, 256, numColors));
    x = parameters.dataset_idx(:,3)+parameters.start_time;
    y = result.errors;
    [x, x_ind] = sort(x);
    y = y(x_ind);
    yMin = min(y);
    yMax = max(y);
    yRange = max(abs(yMin), abs(yMax)); % Use the larger absolute bound for symmetry
    y_norm = round((y + yRange) / (2 * yRange) * (numColors - 1)) + 1; % Map y to [1, 256]
    c = cmap(y_norm,:);
end


[x,y,colors] = get_plot_coords(parameters, result);
figure;
hold on;
for i = 1:length(x)
    line([x(i), x(i)], [0, y(i)/1000], 'Color', colors(i, :), 'LineWidth', 2);
end

% Plot the points with color corresponding to y-values
s = scatter(x, y/1000, 10, colors, 'filled'); % 100 is the marker size, adjust as needed
% Customize the plot
xlabel('Activation year', 'FontSize',14);
ylabel('Error (kyrs)','FontSize',14);

grid on;

%% Color palette

subplot(3, 1, 1); % Activate the first subplot
x = pinhasi.lat;
y = pinhasi.lon;
t = pinhasi.bp;
active_layers_1 = [1 0 0 0 0];
theta_1 = [-0.69];

parameters_1 = data_prep(50, active_layers_1, x,y,t);
result_1 = run_model(parameters_1, theta_1);
[x,y,colors] = get_plot_coords(parameters_1, result_1);
hold on;
for i = 1:length(x)
    line([x(i), x(i)], [0, y(i)/1000], 'Color', colors(i, :), 'LineWidth', 1);
end


scatter(x, y/1000, 10, colors, 'filled');
ylim([-5,5])
grid on;
ylabel('Error (kyrs)','FontSize',14);
title('av')

subplot(3, 1, 2); % Activate the second subplot
x = pinhasi.lat;
y = pinhasi.lon;
t = pinhasi.bp;
active_layers_2 = [1 0 1 0 0];
theta_2 = [-1.34, 0.45];

parameters_2 = data_prep(50, active_layers_2, x,y,t);
result_2 = run_model(parameters_2, theta_2);

[x,y,colors] = get_plot_coords(parameters_2, result_2);
hold on;
for i = 1:length(x)
    line([x(i), x(i)], [0, y(i)/1000], 'Color', colors(i, :), 'LineWidth', 1);
end
scatter(x, y/1000, 10, colors, 'filled');
ylim([-5000/1000,5000/1000])
grid on;
ylabel('Error (kyrs)','FontSize',14);
title('av, csi')

subplot(3, 1, 3); % Activate the first subplot
x = pinhasi.lat;
y = pinhasi.lon;
t = pinhasi.bp;
active_layers_3 = [1 0 1 0 0 1];
theta_3 = [-1.5345,0.0028,4.4800];

parameters_3 = data_prep(50, active_layers_3, x,y,t);
result_3 = run_model(parameters_3, theta_3);

[x,y,colors] = get_plot_coords(parameters_3, result_3);
hold on;
for i = 1:length(x)
    line([x(i), x(i)], [0, y(i)/1000], 'Color', colors(i, :), 'LineWidth', 1);
end
scatter(x, y/1000, 10, colors, 'filled');
ylim([-5000/1000,5000/1000])
grid on;
xlabel('Activation year', 'FontSize',14);
ylabel('Error (kyrs)','FontSize',14);
title('av, csi, sea')

%%
% hold on;
% plot(result_1.times, parameters_1.dataset_idx(:,3),'.')
% plot(result_2.times, parameters_2.dataset_idx(:,3),'.')
% plot(result_3.times, parameters_3.dataset_idx(:,3),'.')

figure
x = 1:3;
y = [result_1.squared_error, result_2.squared_error, result_3.squared_error];


bar(x, y, 'FaceColor', [0.2, 0.6, 0.8]); % Plot the bar chart with a custom color
xticklabels({'1', '2', '3'}); % Label x-axis ticks
xlabel('num layers', 'FontSize',14)
ylabel('Squared error', 'FontSize',14)
title('Wheat', 'FontSize',16)

parameters_all = [parameters_1, parameters_2, parameters_3];
results_all = [result_1, result_2, result_3];

figure;
hold on;

for i = 1:3
x = parameters_all(i).dataset_idx(:,3);
y = results_all(i).times;
[x, x_ind] = sort(x);
y = y(x_ind);

% Calculate the confidence interval for the fit
[~, S] = polyfit(x, y, 1); % Get the error structure
[y_fit, delta] = polyval(p, x, S); % Evaluate fit and confidence interval

% Plot the data, fit, and error band

% plot(x, y, 'ko', 'MarkerFaceColor', 'k', 'DisplayName', 'Data'); % Plot data points
plot(x, y_fit, 'r-', 'LineWidth', 2, 'DisplayName', 'Linear Fit'); % Plot linear fit
patch([x; flip(x)], [y_fit + delta; flip(y_fit - delta)], 'r', 'EdgeColor', 'none', 'FaceAlpha', 0.3, 'DisplayName', 'Error Band'); % Plot error band

% Plot the x = y line
plot(x, x, 'b--', 'LineWidth', 2, 'DisplayName', 'x = y Line'); % Plot x = y line
end
% Customize the plot
xlabel('X-axis');
ylabel('Y-axis');
title('Linear Fit with Error Band and x = y Line');
grid on;
hold off;

%% Plot csi

x = pinhasi.lat;
y = pinhasi.lon;
t = pinhasi.bp;

theta = [-1.792, 0.448];
active_layers = [1 0 1 0 0 0 0 0];
parameters = data_prep(50, active_layers, x,y,t);
result = run_model(parameters,theta);

%%
data = readtable('data/raw/prune_data/Table S1.xlsx');
x = data.Latitude;
y = data.Longitude;
t = data.Est_AverageDateBCE_CE;
active_layers = [1 0 0 0 0 0 0];
loc = 10;
fwidth = 20;
f = figure('Units','inches','Position',[loc loc fwidth fwidth/2.2], ...
    'PaperPosition',[.25 .25 8 6]);
R = georefcells(parameters.lat, parameters.lon, ...
        size(parameters.X{1}));
latlim = parameters.lat;
lonlim = parameters.lon;
worldmap(latlim, lonlim)
axis xy
land = shaperead('landareas.shp', 'UseGeoCoords', true);
geoshow(fliplr([land.Lat]),fliplr([land.Lon]),'DisplayType', ...
        'Polygon', 'FaceColor', 'white', 'FaceAlpha', 0.5)
% geoshow(parameters.X{1}, R, 'DisplayType', 'texturemap')
sizes = max(parameters.dataset_idx(:,3)) - parameters.dataset_idx(:,3)+1;
scatterm(parameters.dataset_lat, parameters.dataset_lon, sizes, parameters.dataset_idx(:,3), 'filled');

%%

t = parameters.times(parameters.dataset_idx(:,3));
[min_t, min_t_idx] = min(t);
dist_x = parameters.dataset_lat - parameters.dataset_lat(min_t_idx);
dist_y = parameters.dataset_lon - parameters.dataset_lon(min_t_idx);
dist = sqrt(dist_x.^2 + dist_y.^2);
categories = [data.PrunusPersica, data.PrunusArmeniaca, data.PrunusSpinosa, data.PrunusCerasifera, data.domestica_type, data.insititia_type, data.PrunusSp_];
figure
hold on 
% Number of colors you want to extract
num_colors = length(categories(1,:));
cmap = colormap('jet'); % Replace 'parula' with your desired colormap
color_indices = linspace(1, size(cmap, 1), num_colors); % Linearly spaced indices
color_indices = round(color_indices); % Round to nearest integer
colors = cmap(color_indices, :); % Extract the colors

for i = 1:length(categories(1,:))-1
    t_c = t(~isnan(categories(:,i)));
    dist_c = dist(~isnan(categories(:,i)));

    scatter(t_c,dist_c,'MarkerEdgeColor',colors(i,:), 'MarkerFaceColor', colors(i,:))

end
xlabel("year (BP)")
ylabel("distance from oldest point")

%%
f = figure('Units','inches','Position',[loc loc fwidth fwidth/2.2], ...
    'PaperPosition',[.25 .25 8 6]);
R = georefcells(parameters.lat, parameters.lon, ...
        size(parameters.X{1}));
latlim = parameters.lat;
lonlim = parameters.lon;
worldmap(latlim, lonlim)
axis xy
land = shaperead('landareas.shp', 'UseGeoCoords', true);
geoshow(fliplr([land.Lat]),fliplr([land.Lon]),'DisplayType', ...
        'Polygon', 'FaceColor', 'white', 'FaceAlpha', 0.5)
% geoshow(parameters.X{1}, R, 'DisplayType', 'texturemap')

for i = 1:length(categories(1,:))-1
    x = parameters.dataset_lat(~isnan(categories(:,i)));
    y = parameters.dataset_lon(~isnan(categories(:,i)));
    scatterm(x,y, 20, colors(i,:), 'filled');
end