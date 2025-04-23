%% Colors

% Define the three colors (RGB format):
color1 = [4/255, 29/255, 45/255];   % Blue
color2 = [104/255, 93/255, 39/255];   % White
color3 = [241/255, 180/255, 188/255];   % Red

% Number of points in your colormap:
numColors = 256; 

% Create a colormap by interpolating between these colors:
dusk = interp1([1, 128, 256], [color1; color2; color3], linspace(1, 256, numColors));

% Define the three colors (RGB format):
color0 = [1/255, 1/255, 1/255];
color1 = [5/255, 66/255, 92/255];   % Blue
color2 = [165/255, 154/255, 109/255];   % White
color3 = [254/255, 240/255, 85/255];   % Red

% Number of points in your colormap:
numColors = 256; 
% Create a colormap by interpolating between these colors:
pepper = interp1(linspace(1,256,4), [color0; color1; color2; color3], linspace(1, 256, numColors));

% Define the three colors (RGB format):
color0 = [62/255, 4/255, 22/255];
color1 = [148/255, 95/255, 4/255];   % Blue
color2 = [147/255, 159/255, 38/255];   % White
color3 = [51/255, 204/255, 25/255];   % Red

% Number of points in your colormap:
numColors = 256; 
% Create a colormap by interpolating between these colors:
eclipse = interp1(linspace(1,256,4), [color0; color1; color2; color3], linspace(1, 256, numColors));

% Define the three colors (RGB format):
color1 = [30/255, 51/255, 110/255];   % Blue
color2 = [235/255, 232/255, 198/255];   % White
color3 = [110/255, 20/255, 30/255];   % Red

% Number of points in your colormap:
numColors = 256; 

% Create a colormap by interpolating between these colors:
redblue = interp1([1, 128, 256], [color1; color2; color3], linspace(1, 256, numColors));

%% Diffusion plot
addpath('src');
addpath("cmaps")
[x,y,t] = get_dataset("cobo");

parameters = data_prep(1, [1 0 1 0 0 0 0 0], x, y, t);
result = run_model(parameters, [-1.87, 0.90]);
pinhasi_active = parameters.dataset_idx;
land = shaperead('landareas.shp', 'UseGeoCoords', true);

R = georefcells(parameters.lat, parameters.lon, ...
    size(parameters.X{1}));

tic
f = figure (1);
set(gcf, 'Color', 'White')
f.Position = [100 100 900 400];
% subplot(1,2,2)
hold on;

latlim = parameters.lat;
lonlim = parameters.lon;

worldmap(latlim, lonlim)
colormap(pepper)

title("Rice dataset", "FontSize", 12)
c = colorbar;
ylabel(c,'Year','FontSize',12);
axis xy

%make sea white

geoshow(fliplr([land.Lat]),fliplr([land.Lon]),'DisplayType', ...
    'Polygon', 'FaceColor', 'white', 'FaceAlpha', 0.5)

framem('FLineWidth', 1, 'FontSize', 7)

scatterm(parameters.dataset_lat, parameters.dataset_lon, 5, parameters.times(parameters.dataset_idx(:,3)), 'filled');


[x,y,t] = get_dataset("all_wheat");
clear parameters
clear result
parameters = data_prep(1, [1 0 1 0 0 0 0 0], x, y, t);
result = run_model(parameters, [-1.87, 0.90]);
pinhasi_active = parameters.dataset_idx;
land = shaperead('landareas.shp', 'UseGeoCoords', true);

R = georefcells(parameters.lat, parameters.lon, ...
    size(parameters.X{1}));
loc = 10;
fwidth = 20;
tic
subplot(1,2,1)

hold on;

latlim = parameters.lat;
lonlim = parameters.lon;

worldmap(latlim, lonlim)
colormap(pepper)

title("Wheat dataset", "FontSize", 12)
c = colorbar;
ylabel(c,'Year','FontSize',12);
axis xy

%make sea white

geoshow(fliplr([land.Lat]),fliplr([land.Lon]),'DisplayType', ...
    'Polygon', 'FaceColor', 'white', 'FaceAlpha', 0.5)

framem('FLineWidth', 1, 'FontSize', 7)

scatterm(parameters.dataset_lat, parameters.dataset_lon, 5, parameters.times(parameters.dataset_idx(:,3)), 'filled');
print(f, 'saved_plots/Diffusive_data.pdf', '-depsc')

%% Model figure plots

addpath('src');
addpath("generated_data\")
%%
[x,y,t] = get_dataset("all_wheat");
active_layers = [0 0 0 0 0 1 0 0]; %prec
parameters = data_prep(1, active_layers, x, y, t);
%%
[nx,ny] = size(parameters.X{1});
X = linspace(parameters.lat(1), parameters.lat(2), nx);
Y = linspace(parameters.lon(1), parameters.lon(2), ny);
f = figure(1);
pepper_bright = brighten(pepper, 0.3);
f.Position = [100 100 700 400];
set(gcf, 'Color', 'White', 'Alphamap',0)
[X,Y] = meshgrid(X,Y);
s = mesh(X,Y,parameters.X{1}');
s.FaceColor = 'flat';
s.FaceAlpha = 1;
view([45 60])
xlim([min(X(:)), max(X(:))])
ylim([min(Y(:)), max(Y(:))])
colormap(pepper_bright)
ax = gca;
ax.FontSize = 16; 
xlabel("Latitude", 'Rotation', -25, "FontSize",16)
ylabel("Longitude", 'Rotation', 25, "FontSize",16)
zlabel("Mean temperature", "FontSize",16)
grid off
saveas(gcf,"saved_plots/tmean_layer.pdf")

%% %% Plot objective function
load("model_plot_sweep_small.mat")
[X,Y] = meshgrid(theta_prec,theta_tmean);
points = [[2.28 -0.16 1.61543+0.07]; [2.92 -0.56 1.02808+0.05];  [3.16 -0.72 0.721299+0.05]; [3.24 -0.96 0.475222+0.05]; [3.24 -1.04 0.4348+0.05]; [3.2 -1.12 0.413622+0.05]];

f = figure(1)
hold on
f.Position = [100 100 700 400];
set(gcf, 'Color', 'White', 'Alphamap',0)
plot_errors = log(errors/1e6);
s = mesh(X,Y,plot_errors');
% Plot lines between points
lineColor = [110/255, 20/255, 30/255];
plot3(points(:,1), points(:,2), points(:,3), ...
    '-', 'LineWidth', 2.5, 'Color', lineColor);

% Plot points as scatter3
scatter3(points(:,1), points(:,2), points(:,3), ...
    50, lineColor, 'filled');
s.FaceColor = 'flat';
s.FaceAlpha = 1;
view([55 0])
xlim([2,3.5])
ylim([-2.,-0.])
pepper_bright = brighten(pepper, 0.3);
colormap(flipud(pepper_bright))
view([180-70 30])
ax = gca;
ax.FontSize = 16; 
xlabel("\theta_{prec}", 'Rotation', 55, "FontSize",16)
ylabel("\theta_{tmean}", 'Rotation', -5, "FontSize",16)
zlabel("Objective function (a.u.)", "FontSize",16)

saveas(gcf,"saved_plots/Obj_func.pdf")

%% Bar chart results plot
addpath("src")

load('C:\Users\matil\OneDrive\Documents\Work\AlanTuring_Oxford\bottlenecks\generated_data\filename_database.mat')

load('C:\Users\matil\OneDrive\Documents\Work\AlanTuring_Oxford\bottlenecks\generated_data\all_wheat_av_100av_2025-03-24_11-09.mat')
labels_w = {};
labels_w{1} = "av";
sq_errors_w = [result.squared_error];
yr_errors_w = [sqrt(result.squared_error)];
sq_errorbar_w = [0];

load('C:\Users\matil\OneDrive\Documents\Work\AlanTuring_Oxford\bottlenecks\generated_data\cobo_av100_2025-03-10_14-02.mat')
result = run_model(parameters, theta_optim);
labels_r = {};
labels_r{1} = "av";
sq_errors_r = [result.squared_error];
yr_errors_r = [sqrt(result.squared_error)];
sq_errorbar_r = [0];

for i=1:length(database)
    if (length(database{i}.layers) == 2)
        if ~all(ismember('sea', database{i}.layers{2}))
            continue
        end
    end
    if (length(database{i}.layers) == 2) & ismember('wheat', database{i}.dataset)
        disp(database{i}.layers)
        labels_w{length(labels_w)+1} = database{i}.layers{1};
        load(database{i}.file)
        sq_errors_w = [sq_errors_w result.squared_error];
        yr_errors_w = [yr_errors_w mean(spread_errors_shuffle)];
        sq_errorbar_w = [sq_errorbar_w std(spread_errors_shuffle)];
    elseif (length(database{i}.layers) == 2) & ismember('rice', database{i}.dataset)
        disp(database{i}.layers)
        labels_r{length(labels_r)+1} = database{i}.layers{1};
        load(database{i}.file)
        sq_errors_r = [sq_errors_r result.squared_error];
        yr_errors_r = [yr_errors_r mean(spread_errors_shuffle)];
        sq_errorbar_r = [sq_errorbar_r std(spread_errors_shuffle)];
    end
end


[yr, w_idx] = sort(sq_errors_w);
w_idx = fliplr(w_idx);

yr_errors = [yr_errors_w(w_idx); yr_errors_r(w_idx)];
sq_errors = [sq_errors_w(w_idx); sq_errors_r(w_idx)];
sq_errorbar = [sq_errorbar_w(w_idx); sq_errorbar_r(w_idx)];

%%

f = figure(1);
f.Position = [100 100 400 300];
hold on
b2 = bar([0 1], sq_errors/1e6);
% set(gca,'XTickLabel', {"wheat", "rice"})

x_errorbar = [-2 -1 0 1 2].*0.15;
% e1 = errorbar(x_errorbar, sq_errors_w(w_idx)/1e6,sq_errorbar_w/1e6, "LineStyle","none", 'CapSize',12, 'Color', 'k', "LineWidth",1);
% e2 = errorbar(x_errorbar + 1, sq_errors_r(w_idx)/1e6,sq_errorbar_r/1e6, "LineStyle","none", 'CapSize',12, 'Color', 'k', "LineWidth",1);
xticks([0 1])
xticklabels({"wheat", "rice"})
cmap = pepper(1:end-60,:);
ylim([0, 3.2])

layer_names = {"",'asymmetry','crop suitability','river size','precipitation','mean temperature'};
for k = 1:length(yr_errors_r)
    b2(k).FaceColor = cmap(int16((k)*length(cmap)/(length(yr_errors_r)+1)),:);
    xpos = b2(k).XEndPoints;  % Get x-position of bars
    ypos = b2(k).YEndPoints+0.02;  % Get y-position of bars
    text(xpos, ypos, layer_names{w_idx(k)}, ...
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'middle', ...
        'FontSize', 8,'Interpreter','latex','Rotation',90);
    text(xpos, zeros(size(xpos))+0.05, layer_names{w_idx(k)}, ...
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'middle', ...
        'FontSize', 9,'Interpreter','latex','Rotation',90, 'Color','w');
end 
ylabel("Obj. Function",'Interpreter','latex')
% title("With sea layer",'Interpreter','latex')
grid on
set(gca,"TickLabelInterpreter",'latex')
set(gcf, 'Color', 'White', 'Alphamap',0)

saveas(gcf,"saved_plots/results_bar_chart.pdf")

%% horizontal bar chart
w_idx = fliplr(w_idx);

f = figure(1);
f.Position = [100 100 800 180];
tiledlayout(1,2, 'Padding', 'none', 'TileSpacing', 'compact'); 
for p = 1:2
    nexttile    
    hold on
    b2 = barh([0], fliplr(sq_errors(p,:))/1e6);
    cmap = pepper(end-60:-1:1,:);
    if p == 1
        yticks([])
        ylabel({"layer"},'Interpreter','latex', "FontSize",8, 'Rotation',90)
        title("Wheat",'Interpreter','latex')
    elseif p == 2
        yticks([])
        ylabel({"layer"},'Interpreter','latex', "FontSize",8, 'Rotation',90)
        title("Rice",'Interpreter','latex')
    end
    
    % Gradient coloring
    
    layer_names = {"baseline",'asymmetry','crop suitability','river size','precipitation','mean temperature'};
    for k = 1:length(yr_errors_r)
        b2(k).FaceColor = cmap(int16((k)*length(cmap)/(length(yr_errors_r)+1)),:);
        ypos = b2(k).XEndPoints;  % Get x-position of bars
        xpos = b2(k).YEndPoints+0.02;  % Get y-position of bars
        % text(xpos, ypos, layer_names{w_idx(k)}, ...
        %     'HorizontalAlignment', 'left', ...
        %     'VerticalAlignment', 'middle', ...
        %     'FontSize', 8,'Interpreter','latex','Rotation',0);
        text(zeros(size(ypos))+0.05, ypos, layer_names{w_idx(k)}, ...
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 8,'Interpreter','latex','Rotation',0, 'Color','w');
    end 
    xlabel("Obj. Function","FontSize", 8,'Interpreter','latex')
    set(gca,"TickLabelInterpreter",'latex')
    grid on
end

set(gcf, 'Color', 'White', 'Alphamap',0)

saveas(gcf,"saved_plots/results_horizontal_bar_chart.pdf")
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
    x = parameters.dataset_idx(:,3)*parameters.dt+parameters.start_time;
    y = result.errors;
    [x, x_ind] = sort(x);
    y = y(x_ind);
    yMin = min(y);
    yMax = max(y);
    yRange = max(abs(yMin), abs(yMax)); % Use the larger absolute bound for symmetry
    y_norm = round((y + yRange) / (2 * yRange) * (numColors - 1)) + 1; % Map y to [1, 256]
    c = cmap(y_norm,:);
end
f = figure();
f.Position = [100 100 800 300];
tiledlayout(2,2, 'Padding', 'none', 'TileSpacing', 'compact'); 

nexttile
load('C:\Users\matil\OneDrive\Documents\Work\AlanTuring_Oxford\bottlenecks\generated_data\all_wheat_av_100av_2025-03-24_11-09.mat')
[x,y,colors] = get_plot_coords(parameters, result);
hold on;
for i = 1:length(x)
    line([x(i), x(i)], [0, y(i)], 'Color', colors(i, :), 'LineWidth', 1);
end
% Plot the points with color corresponding to y-values
s = scatter(x, y, 5, colors, 'filled'); % 100 is the marker size, adjust as needed
ylim([-5000,5000])
xlabel("Year",'Interpreter','latex', 'FontSize',8)
ylabel("Error (years)",'Interpreter','latex', 'FontSize',8)
title("Wheat - baseline",'Interpreter','latex', 'FontSize',10)
set(gca,"TickLabelInterpreter",'latex')
grid on
yticks([-5000,-2500,0,2500,5000])

nexttile
load('C:\Users\matil\OneDrive\Documents\Work\AlanTuring_Oxford\bottlenecks\generated_data\cobo_av_100av_2025-03-24_10-59.mat')
[x,y,colors] = get_plot_coords(parameters, result);
hold on;
for i = 1:length(x)
    line([x(i), x(i)], [0, y(i)], 'Color', colors(i, :), 'LineWidth', 1);
end

% Plot the points with color corresponding to y-values
s = scatter(x, y, 5, colors, 'filled'); % 100 is the marker size, adjust as needed
ylim([-5000,5000])
xlabel("Year",'Interpreter','latex', 'FontSize',8)
ylabel("Error (years)",'Interpreter','latex', 'FontSize',8)
title("Rice - baseline",'Interpreter','latex', 'FontSize',10)
set(gca,"TickLabelInterpreter",'latex')
grid on
yticks([-5000,-2500,0,2500,5000])
nexttile
load('C:\Users\matil\OneDrive\Documents\Work\AlanTuring_Oxford\bottlenecks\generated_data\all_wheat_av_prec_sea_100av_2025-03-28_14-02.mat')
[x,y,colors] = get_plot_coords(parameters, result);
hold on;
for i = 1:length(x)
    line([x(i), x(i)], [0, y(i)], 'Color', colors(i, :), 'LineWidth', 1);
end

% Plot the points with color corresponding to y-values
s = scatter(x, y, 5, colors, 'filled'); % 100 is the marker size, adjust as needed
ylim([-5000,5000])
xlabel("Year",'Interpreter','latex', 'FontSize',8)
ylabel("Error (years)",'Interpreter','latex', 'FontSize',8)
title("Wheat - sea and precipitation",'Interpreter','latex', 'FontSize',10)
set(gca,"TickLabelInterpreter",'latex')
grid on
yticks([-5000,-2500,0,2500,5000])

nexttile
load('C:\Users\matil\OneDrive\Documents\Work\AlanTuring_Oxford\bottlenecks\generated_data\cobo_av_prec_sea_100av_2025-03-28_14-04.mat')
[x,y,colors] = get_plot_coords(parameters, result);
hold on;
for i = 1:length(x)
    line([x(i), x(i)], [0, y(i)], 'Color', colors(i, :), 'LineWidth', 1);
end

% Plot the points with color corresponding to y-values
s = scatter(x, y, 5, colors, 'filled'); % 100 is the marker size, adjust as needed
ylim([-5000,5000])
xlabel("Year",'Interpreter','latex', 'FontSize',8)
ylabel("Error (years)",'Interpreter','latex', 'FontSize',8)
title("Rice - sea and precipitation",'Interpreter','latex', 'FontSize',10)

set(gca,"TickLabelInterpreter",'latex')
set(gcf, 'Color', 'White', 'Alphamap',0)
grid on
yticks([-5000,-2500,0,2500,5000])

saveas(gcf,"saved_plots/results_error_plots.pdf")

%% map plot
addpath("src")
f = figure();
f.Position = [100 100 800 200];
tiledlayout(1,2, 'Padding', 'none', 'TileSpacing', 'compact'); 

nexttile
load('C:\Users\matil\OneDrive\Documents\Work\AlanTuring_Oxford\bottlenecks\generated_data\all_wheat_av_prec_sea_100av_2025-03-28_14-02.mat')
simulation = parameters.end_time - mean(result.A, 3)*(parameters.end_time-parameters.start_time);
[~, ~, t_max] = size(result.A);
plot_map(parameters, parameters.dataset_bp, false, simulation);
colormap(pepper)
title("Wheat - sea and precipitation",'Interpreter','latex')

nexttile
load('C:\Users\matil\OneDrive\Documents\Work\AlanTuring_Oxford\bottlenecks\generated_data\cobo_av_prec_sea_100av_2025-03-28_14-04.mat')
simulation = parameters.end_time - mean(result.A, 3)*(parameters.end_time-parameters.start_time);
[~, ~, t_max] = size(result.A);
plot_map(parameters, parameters.dataset_bp, false, simulation);
colormap(pepper)

title("Rice - sea and precipitation",'Interpreter','latex', 'FontSize',10)
set(gcf, 'Color', 'White', 'Alphamap',0)

saveas(gcf,"saved_plots/maps_and_errors.pdf")


%% 

custom_colors = [0 0 0;      
                0.5 0.5 0.5;  
                0.6 0 0];
size_pt = 7;
subplot(2,1,1)
hold on
load('C:\Users\matil\OneDrive\Documents\Work\AlanTuring_Oxford\bottlenecks\generated_data\all_wheat_av_100av_2025-03-24_11-09.mat')
[min_time, min_time_idx] = min(parameters.dataset_bp);


dist = sqrt((parameters.dataset_lat-parameters.dataset_lat(min_time_idx)).^2 + (parameters.dataset_lon-parameters.dataset_lon(min_time_idx)).^2);
dist_km = deg2km(dist);

[max_time, max_time_idx] = max(dist_km);
[~, ~, t_max] = size(result.A);

s1 = scatter(parameters.dataset_bp, dist_km, "filled");
s1.SizeData = size_pt;
s1.MarkerFaceColor = custom_colors(1,:);
s1.MarkerFaceAlpha = 0.8;

simulation_times = parameters.start_time - result.times/t_max*(parameters.start_time-parameters.end_time);
A= [simulation_times(min_time_idx) simulation_times(max_time_idx)];
B=[dist_km(min_time_idx) dist_km(max_time_idx)];
s2 = line(A,B);
s2.LineWidth = 2;
s2.Color = custom_colors(2,:);

load('C:\Users\matil\OneDrive\Documents\Work\AlanTuring_Oxford\bottlenecks\generated_data\all_wheat_av_prec_sea_100av_2025-03-28_14-02.mat')
simulation_times = parameters.start_time - result.times/t_max*(parameters.start_time-parameters.end_time);
s3 = scatter(simulation_times, dist_km, 'filled');
s3.MarkerFaceColor = custom_colors(3,:);
s3.SizeData = size_pt;
s3.MarkerFaceAlpha = 0.8;

pt = scatter([A(1)],[B(1)]);
pt.SizeData = 200;
pt.LineWidth = 1.5;
pt.MarkerEdgeColor = 'k';
text(A(1),B(1)+1000, "origin",'HorizontalAlignment', 'center', 'Interpreter','latex','FontSize', 8)

legend(["Original dataset",  "Average simulation", "Full simulation"], "Location", "northwest",'Interpreter','latex')
xlabel("Time (yr)",'Interpreter','latex')
ylabel("Absolute distance (deg)",'Interpreter','latex')
title("Wheat", "FontSize",14,'Interpreter','latex')

ylim([-1000,7000])
set(gca,"TickLabelInterpreter",'latex')

%%
subplot(2,1,2)

hold on
load('C:\Users\matil\OneDrive\Documents\Work\AlanTuring_Oxford\bottlenecks\generated_data\cobo_av_100av_2025-03-24_10-59.mat')
[min_time, min_time_idx] = min(parameters.dataset_bp);
dist = sqrt((parameters.dataset_lat-parameters.dataset_lat(min_time_idx)).^2 + (parameters.dataset_lon-parameters.dataset_lon(min_time_idx)).^2);
dist_km = deg2km(dist);


[~, ~, t_max] = size(result.A);

s1 = scatter(parameters.dataset_bp, dist_km, "filled");
s1.SizeData = size_pt;
s1.MarkerFaceColor = custom_colors(1,:);
s1.MarkerFaceAlpha = 0.8;

simulation_times = parameters.start_time - result.times/t_max*(parameters.start_time-parameters.end_time);
[max_time, max_time_idx] = max(simulation_times);
A= [simulation_times(min_time_idx) simulation_times(max_time_idx)];
B=[dist_km(min_time_idx) dist_km(max_time_idx)];
s2 = line(A,B);
s2.LineWidth = 2;
s2.Color = custom_colors(2,:);

second_dist = dist_km;
second_dist(second_dist<4250) = nan;
second_times = simulation_times;
second_times(second_dist<4250) = nan;
[min_time, min_time_idx] = min(second_dist);
[max_time, max_time_idx] = max(second_dist);
A2= [second_times(min_time_idx) second_times(max_time_idx)];
B2=[second_dist(min_time_idx) second_dist(max_time_idx)];
s22 = line(A2,B2);
s22.LineWidth = 2;
s22.Color = custom_colors(2,:);


load('C:\Users\matil\OneDrive\Documents\Work\AlanTuring_Oxford\bottlenecks\generated_data\cobo_av_prec_sea_100av_2025-03-28_14-04.mat')
simulation_times = parameters.start_time - result.times/t_max*(parameters.start_time-parameters.end_time);
s3 = scatter(simulation_times, dist_km, 'filled');
s3.MarkerFaceColor = custom_colors(3,:);
s3.SizeData = size_pt;
s3.MarkerFaceAlpha = 0.8;

xlabel("Time (yr)",'Interpreter','latex')
ylabel("Absolute distance (deg)",'Interpreter','latex')
title("Rice", "FontSize",14,'Interpreter','latex')

set(gca,"TickLabelInterpreter",'latex')
set(gcf, 'Color', 'White', 'Alphamap',0)

saveas(gcf,"saved_plots/dist_vs_time.pdf")
