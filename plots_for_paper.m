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
[x,y,t] = get_dataset("all_wheat");

parameters = data_prep(1, [1 0 1 0 0 0 0 0], x, y, t);
result = run_model(parameters, [-1.87, 0.90]);
pinhasi_active = parameters.dataset_idx;
land = shaperead('landareas.shp', 'UseGeoCoords', true);

R = georefcells(parameters.lat, parameters.lon, ...
    size(parameters.X{1}));
set(0, 'DefaultFigureRenderer', 'zbuffer'); %// this line added
set(0, 'defaulttextinterpreter', 'latex');
tic
f = figure (1);
set(gcf, 'Color', 'White')
f.Position = [100 100 300 150];
% subplot(1,2,2)
hold on;

latlim = parameters.lat;
lonlim = parameters.lon;

worldmap(latlim, lonlim)
colormap(pepper)

c = colorbar;
ylabel(c,'Year','FontSize',12);
axis xy

%make sea white

geoshow(fliplr([land.Lat]),fliplr([land.Lon]),'DisplayType', ...
    'Polygon', 'FaceColor', 'white', 'FaceAlpha', 0.5)

scatterm(parameters.dataset_lat, parameters.dataset_lon, 5, parameters.times(parameters.dataset_idx(:,3)), 'filled');


[x,y,t] = get_dataset("all_wheat");

parameters = data_prep(1, [1 0 1 0 0 0 0 0], x, y, t);
result = run_model(parameters, [-1.87, 0.90]);
pinhasi_active = parameters.dataset_idx;
land = shaperead('landareas.shp', 'UseGeoCoords', true);

R = georefcells(parameters.lat, parameters.lon, ...
    size(parameters.X{1}));
loc = 10;
fwidth = 20;
tic

hold on;

latlim = parameters.lat;
lonlim = parameters.lon;

worldmap(latlim, lonlim)
colormap(pepper)

axis xy

cb = colorbar;
cb.FontSize = 8;
set(cb,'TickLabelInterpreter','latex','FontSize',6)
ylabel(cb,'Year of arrival, $Y_\ell$','FontSize',8,'Interpreter','latex', 'Rotation',-90);
%make sea white

geoshow(fliplr([land.Lat]),fliplr([land.Lon]),'DisplayType', ...
    'Polygon', 'FaceColor', 'white', 'FaceAlpha', 0.5)
framem('FLineWidth', 1, 'FontSize', 4)
scatterm(parameters.dataset_lat, parameters.dataset_lon, 3, parameters.times(parameters.dataset_idx(:,3)), 'filled');

% saveas(gcf, 'saved_plots/Diffusive_data.pdf')
exportgraphics(gcf,'saved_plots/Diffusive_data.pdf','ContentType','vector')


%% simulation plot
f = figure (1);
set(gcf, 'Color', 'White')
f.Position = [100 100 300 150];
% subplot(1,2,2)
hold on;

parameters = data_prep(20, [1 0 1 0 0 0 0 0], x, y, t);
result = run_model(parameters, [-1.87, 0.90]);

latlim = parameters.lat;
lonlim = parameters.lon;

worldmap(latlim, lonlim)
colormap(pepper)

c = colorbar;
ylabel(c,'Year','FontSize',12);
axis xy

R = georefcells(parameters.lat, parameters.lon, ...
    size(parameters.X{1}));

simulation = parameters.end_time - mean(result.A, 3)*(parameters.end_time-parameters.start_time);
geoshow(simulation, R, 'DisplayType', 'texturemap')

geoshow(fliplr([land.Lat]),fliplr([land.Lon]),'DisplayType', ...
    'Polygon', 'FaceColor', 'white', 'FaceAlpha', 0.5)


[x,y,t] = get_dataset("all_wheat");
pinhasi_active = parameters.dataset_idx;
land = shaperead('landareas.shp', 'UseGeoCoords', true);


loc = 10;
fwidth = 20;
tic

hold on;

latlim = parameters.lat;
lonlim = parameters.lon;


colormap(pepper)

axis xy

cb = colorbar;
cb.FontSize = 8;
set(cb,'TickLabelInterpreter','latex','FontSize',6)
ylabel(cb,'Simulated year of arrival, $\hat{Y}_\ell$','FontSize',8,'Interpreter','latex', 'Rotation',-90);
%make sea white

geoshow(fliplr([land.Lat]),fliplr([land.Lon]),'DisplayType', ...
    'Polygon', 'FaceColor', 'white', 'FaceAlpha', 0.5)
framem('FLineWidth', 1, 'FontSize', 4)



% saveas(gcf, 'saved_plots/Simulated_data.pdf', 'pdf')
exportgraphics(gcf,'saved_plots/Simulated_data.pdf','ContentType','vector')

clear parameters
clear result

%% Model figure plots

addpath('src');
addpath("generated_data\")
%%
[x,y,t] = get_dataset("all_wheat");
% active_layers = [0 0 0 0 1 0 0 0]; %prec
% parameters = data_prep(1, active_layers, x, y, t);
load('generated_data\all_wheat_av_prec_100av_2025-04-08_06-09.mat')

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
zlabel("Precipitation", "FontSize",16)
grid off
set(gca,"TickLabelInterpreter",'latex')
saveas(gcf,"saved_plots/prec_layer.pdf")
% exportgraphics(gcf,'saved_plots/tmean_layer.pdf','ContentType','vector')

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

% saveas(gcf,"saved_plots/Obj_func.pdf")
exportgraphics(gcf,'saved_plots/Obj_func.pdf','ContentType','vector')
%% Bar chart results plot
addpath("src")

load('generated_data\filename_database.mat')

load('generated_data\all_wheat_av_100av_2025-06-14_02-27.mat')
labels_w = {};
labels_w{1} = "av";
sq_errors_w = [mean(spread_errors_shuffle)^2];
yr_errors_w = [mean(spread_errors_shuffle)];
yr_errorbar_w = [std(spread_errors_shuffle)];

load('generated_data\cobo_av_100av_2025-07-10_15-10.mat')
result = run_model(parameters, theta_optim);
labels_r = {};
labels_r{1} = "av";
sq_errors_r = [mean(spread_errors_shuffle)^2];
yr_errors_r = [mean(spread_errors_shuffle)];
yr_errorbar_r = [std(spread_errors_shuffle)];

load('generated_data\maize_av_100av_2025-06-16_09-06.mat')
result = run_model(parameters, theta_optim);
labels_m = {};
sq_errors_m = [mean(spread_errors_shuffle)^2];
yr_errors_m = [mean(spread_errors_shuffle)];
yr_errorbar_m = [std(spread_errors_shuffle)];

for i=1:length(database)
    if (length(database{i}.layers) == 2)
        if ~(ismember('sea', database{i}.layers))
            continue
        end
    elseif (length(database{i}.layers) == 1)
        if ~(ismember('sea', database{i}.layers))
            continue
        end
    end
    
    
    if ismember('wheat', database{i}.dataset)
        disp(database{i}.layers)
        labels_w{length(labels_w)+1} = database{i}.layers{1};
        load(database{i}.file)
        sq_errors_w = [sq_errors_w result.squared_error];
        % yr_errors_w = [yr_errors_w sqrt(result.squared_error)];
        % yr_errorbar_w = [yr_errorbar_w 0];
        yr_errors_w = [yr_errors_w mean(spread_errors_shuffle)];
        yr_errorbar_w = [yr_errorbar_w std(spread_errors_shuffle)];
    elseif ismember('rice', database{i}.dataset)
        disp(database{i}.layers)
        labels_r{length(labels_r)+1} = database{i}.layers{1};
        load(database{i}.file)
        sq_errors_r = [sq_errors_r result.squared_error];
        yr_errors_r = [yr_errors_r mean(spread_errors_shuffle)];
        yr_errorbar_r = [yr_errorbar_r std(spread_errors_shuffle)];
        % yr_errors_r = [yr_errors_r sqrt(result.squared_error)];
        % yr_errorbar_r = [yr_errorbar_r 0];
    elseif ismember('maize',database{i}.dataset)
        disp(database{i}.layers)
        labels_m{length(labels_m)+1} = database{i}.layers{1};
        load(database{i}.file)
        sq_errors_m = [sq_errors_m result.squared_error];
        yr_errors_m = [yr_errors_m mean(spread_errors_shuffle)];
        yr_errorbar_m = [yr_errorbar_m std(spread_errors_shuffle)];
        % yr_errors_m = [yr_errors_m sqrt(result.squared_error)];
        % yr_errorbar_m = [yr_errorbar_m 0];
    end

    clear result
    clear spread_errors_boot
end


[yr, w_idx] = sort(sq_errors_w);
w_idx = fliplr(w_idx);

yr_errors = [yr_errors_w(w_idx); yr_errors_r(w_idx); yr_errors_m(w_idx)];
sq_errors = [sq_errors_w(w_idx); sq_errors_r(w_idx); sq_errors_m(w_idx)];
yr_errorbar = [yr_errorbar_w(w_idx); yr_errorbar_r(w_idx); yr_errorbar_m(w_idx)];

%%

f = figure(1);
f.Position = [100 100 400 300];
hold on
b2 = bar([0 1 2], yr_errors/1e3);
% set(gca,'XTickLabel', {"wheat", "rice"})

x_errorbar = [-3 -2 -1 0 1 2 3].*0.115;
e1 = errorbar(x_errorbar, yr_errors_w(w_idx)/1e3,yr_errorbar_w/1e3, "LineStyle","none", 'CapSize',10, 'Color', 'k', "LineWidth",1);
e2 = errorbar(x_errorbar + 1, yr_errors_r(w_idx)/1e3,yr_errorbar_r/1e3, "LineStyle","none", 'CapSize',10, 'Color', 'k', "LineWidth",1);
e3 = errorbar(x_errorbar + 2, yr_errors_m(w_idx)/1e3, yr_errorbar_m/1e3, "LineStyle","none", 'CapSize',10, 'Color', 'k', "LineWidth",1);
xticks([0 1 2])
xticklabels({"wheat", "rice", "maize"})
cmap = pepper(1:end-60,:);
% ylim([0, 3.2])

layer_names = {"baseline",'asymmetry','river size','precipitation','mean temperature','crop suitability','sea'};
for k = 1:length(yr_errors_r)
    % b2(k).FaceColor = cmap(int16((k)*length(cmap)/(length(yr_errors_r)+1)),:);
    xpos = b2(k).XEndPoints;  % Get x-position of bars
    ypos = b2(k).YEndPoints+0.02;  % Get y-position of bars
    % text(xpos, ypos, layer_names{w_idx(k)}, ...
    %     'HorizontalAlignment', 'left', ...
    %     'VerticalAlignment', 'middle', ...
    %     'FontSize', 8,'Interpreter','latex','Rotation',90);
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
f = figure(1);
f.Position = [100 100 800 180];
tiledlayout(1,3, 'Padding', 'none', 'TileSpacing', 'compact'); 
for p = 1:3
    nexttile    
    hold on
    b2 = barh([0], fliplr(yr_errors(p,:))/1e3);
    cmap = pepper(end-60:-1:1,:);
    yticks([])
    ylabel({"Geographical layer"},'Interpreter','latex', "FontSize",8, 'Rotation',90)
    if p == 1
        title("Wheat",'Interpreter','latex')
        e1 = errorbar(yr_errors_w(fliplr(w_idx))/1e3, x_errorbar,yr_errorbar_w(fliplr(w_idx))/1e3, 'horizontal', "LineStyle","none", 'CapSize',8, 'Color', 'k', "LineWidth",1);
    elseif p == 2
        title("Rice",'Interpreter','latex')
        e2 = errorbar(yr_errors_r(fliplr(w_idx))/1e3, x_errorbar,yr_errorbar_r(fliplr(w_idx))/1e3, 'horizontal', "LineStyle","none", 'CapSize',8, 'Color', 'k', "LineWidth",1);
    elseif p == 3
        title("Maize",'Interpreter','latex')
        e2 = errorbar(yr_errors_m(fliplr(w_idx))/1e3, x_errorbar,yr_errorbar_m(fliplr(w_idx))/1e3, 'horizontal', "LineStyle","none", 'CapSize',8, 'Color', 'k', "LineWidth",1);
    end
    
    % Gradient coloring
    
    layer_names = {"Baseline",'Anisotropy','River size','Precipitation','Mean temperature','Crop suitability',"Sea only"};
    for k = 1:length(yr_errors_r)
        b2(k).FaceColor = cmap(int16((k)*length(cmap)/(length(yr_errors_r)+1)),:);
        ypos = b2(k).XEndPoints;  % Get x-position of bars
        xpos = b2(k).YEndPoints+0.02;  % Get y-position of bars
        text(zeros(size(ypos))+0.02, ypos, layer_names{w_idx(length(yr_errors_r)-k+1)}, ...
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 8,'Interpreter','latex','Rotation',0, 'Color','w');
    end 
    xlabel("Average error (kyears)","FontSize", 8,'Interpreter','latex')
    set(gca,"TickLabelInterpreter",'latex')
    grid on
end

set(gcf, 'Color', 'White', 'Alphamap',0)

% saveas(gcf,"saved_plots/results_horizontal_bar_chart.pdf")
exportgraphics(gcf,'saved_plots/results_horizontal_bar_chart.pdf','ContentType','vector')
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
    x = parameters.dataset_bp;%parameters.dataset_idx(:,3)*parameters.dt+parameters.start_time;
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
tiledlayout(2,3, 'Padding', 'none', 'TileSpacing', 'compact'); 

nexttile
load('generated_data\all_wheat_av_100av_2025-06-14_02-27.mat')
[x,y,colors] = get_plot_coords(parameters, result);
hold on;
for i = 1:length(x)
    line([x(i), x(i)], [0, y(i)/1e3], 'Color', colors(i, :), 'LineWidth', 0.5);
end
% Plot the points with color corresponding to y-values
s = scatter(x, y/1e3, 5, colors, 'filled'); % 100 is the marker size, adjust as needed
ylim([-5,5])
% xlabel("Year",'Interpreter','latex', 'FontSize',8)
ylabel("Error (kyears)",'Interpreter','latex', 'FontSize',8)
title("Wheat - baseline",'Interpreter','latex', 'FontSize',10)
set(gca,"TickLabelInterpreter",'latex')
grid on
yticks([-5,-2.5,0,2.5,5])
xticklabels([])

nexttile
load('generated_data\cobo_av_100av_2025-07-10_15-10.mat')
[x,y,colors] = get_plot_coords(parameters, result);
hold on;
for i = 1:length(x)
    line([x(i), x(i)], [0, y(i)/1e3], 'Color', colors(i, :), 'LineWidth', 0.5);
end

% Plot the points with color corresponding to y-values
s = scatter(x, y/1e3, 5, colors, 'filled'); % 100 is the marker size, adjust as needed
ylim([-5,5])
% xlabel("Year",'Interpreter','latex', 'FontSize',8)
% ylabel("Error (kyears)",'Interpreter','latex', 'FontSize',8)
title("Rice - baseline",'Interpreter','latex', 'FontSize',10)
set(gca,"TickLabelInterpreter",'latex')
grid on
yticks([-5,-2.5,0,2.5,5])
yticklabels([])
xticklabels([])
% suptitle('\textbf{b.} Baseline model','Interpreter','latex','FontSize',10)


nexttile
load('generated_data\maize_av_100av_2025-06-16_09-06.mat')
[x,y,colors] = get_plot_coords(parameters, result);
hold on;
for i = 1:length(x)
    line([x(i), x(i)], [0, y(i)/1e3], 'Color', colors(i, :), 'LineWidth', 0.5);
end
% Plot the points with color corresponding to y-values
s = scatter(x, y/1e3, 5, colors, 'filled'); % 100 is the marker size, adjust as needed
ylim([-5,5])
% xlabel("Year",'Interpreter','latex', 'FontSize',8)
% ylabel("Error (kyears)",'Interpreter','latex', 'FontSize',8)
title("Maize - baseline",'Interpreter','latex', 'FontSize',10)
set(gca,"TickLabelInterpreter",'latex')
grid on
yticks([-5,-2.5,0,2.5,5])
yticklabels([])
xticklabels([])

nexttile
load('generated_data\all_wheat_av_prec_sea_100av_2025-06-08_07-44.mat')
[x,y,colors] = get_plot_coords(parameters, result);
hold on;
for i = 1:length(x)
    line([x(i), x(i)], [0, y(i)/1e3], 'Color', colors(i, :), 'LineWidth', 0.5);
end

% Plot the points with color corresponding to y-values
s = scatter(x, y/1e3, 5, colors, 'filled'); % 100 is the marker size, adjust as needed
ylim([-5,5])
xlabel("Year",'Interpreter','latex', 'FontSize',8)
ylabel("Error (kyears)",'Interpreter','latex', 'FontSize',8)
title("Wheat - sea and precipitation",'Interpreter','latex', 'FontSize',10)
set(gca,"TickLabelInterpreter",'latex')
grid on
yticks([-5,-2.5,0,2.5,5])

nexttile
load('generated_data\cobo_av_prec_sea_100av_2025-06-16_06-15.mat')
[x,y,colors] = get_plot_coords(parameters, result);
hold on;
for i = 1:length(x)
    line([x(i), x(i)], [0, y(i)/1e3], 'Color', colors(i, :), 'LineWidth', 0.5);
end

% Plot the points with color corresponding to y-values
s = scatter(x, y/1e3, 5, colors, 'filled'); % 100 is the marker size, adjust as needed
ylim([-5,5])
xlabel("Year",'Interpreter','latex', 'FontSize',8)
% ylabel("Error (kyears)",'Interpreter','latex', 'FontSize',8)
title("Rice - sea and precipitation",'Interpreter','latex', 'FontSize',10)
set(gca,"TickLabelInterpreter",'latex')
set(gcf, 'Color', 'White', 'Alphamap',0)
grid on
yticks([-5,-2.5,0,2.5,5])
yticklabels([])
% suptitle('\textbf{c.} Best fitting model','Interpreter','latex','FontSize',10)

nexttile
load('generated_data\maize_av_prec_sea_100av_2025-06-18_05-15.mat')
[x,y,colors] = get_plot_coords(parameters, result);
hold on;
for i = 1:length(x)
    line([x(i), x(i)], [0, y(i)/1e3], 'Color', colors(i, :), 'LineWidth', 0.5);
end
% Plot the points with color corresponding to y-values
s = scatter(x, y/1e3, 5, colors, 'filled'); % 100 is the marker size, adjust as needed
ylim([-5,5])
xlabel("Year",'Interpreter','latex', 'FontSize',8)
% ylabel("Error (kyears)",'Interpreter','latex', 'FontSize',8)
title("Maize - sea and crop suitability",'Interpreter','latex', 'FontSize',10)
set(gca,"TickLabelInterpreter",'latex')
grid on
yticks([-5,-2.5,0,2.5,5])
yticklabels([])

% saveas(gcf,"saved_plots/results_error_plots.pdf")
exportgraphics(gcf,'saved_plots/results_error_plots.pdf','ContentType','vector')
%% map plot
addpath("src")
f = figure();
f.Position = [100 100 800 200];
tiledlayout(1,3, 'Padding', 'none', 'TileSpacing', 'compact'); 

nexttile
load('generated_data\all_wheat_av_prec_sea_100av_2025-06-08_07-44.mat')
simulation = (parameters.end_time - mean(result.A, 3)*(parameters.end_time-parameters.start_time))/1000;
[~, ~, t_max] = size(result.A);
plot_map_flat(parameters, parameters.dataset_bp/1000, false, simulation);
colormap(pepper)
title("Wheat - sea and precipitation",'Interpreter','latex')

nexttile
load('generated_data\cobo_av_prec_sea_100av_2025-06-16_06-15.mat')
simulation = (parameters.end_time - mean(result.A, 3)*(parameters.end_time-parameters.start_time))/1000;
[~, ~, t_max] = size(result.A);
plot_map_flat(parameters, parameters.dataset_bp/1000, false, simulation);
colormap(pepper)
title("Rice - sea and precipitation",'Interpreter','latex', 'FontSize',10)

nexttile
load('generated_data\maize_av_prec_sea_100av_2025-06-18_05-15.mat')
simulation = (parameters.end_time - mean(result.A, 3)*(parameters.end_time-parameters.start_time))/1000;
[~, ~, t_max] = size(result.A);
plot_map_flat(parameters, parameters.dataset_bp/1000, false, simulation);
colormap(pepper)
title("Maize - sea and precipitation",'Interpreter','latex', 'FontSize',10)


set(gcf, 'Color', 'White', 'Alphamap',0)

% saveas(gcf,"saved_plots/maps_and_errors.pdf")
exportgraphics(gcf,'saved_plots/maps_and_errors.pdf','ContentType','vector')

%% map plot 1 x 2
addpath("src")

f = figure();
f.Position = [100 100 1000 500];
load('generated_data\all_wheat_av_prec_sea_100av_2025-06-08_07-44.mat')
simulation = (parameters.end_time - mean(result.A, 3)*(parameters.end_time-parameters.start_time))/1000;
[~, ~, t_max] = size(result.A);
plot_map_flat(parameters, parameters.dataset_bp/1000, false, simulation);
colormap(pepper)
title("Wheat - sea and precipitation",'Interpreter','latex', 'FontSize',8*2, 'Color','k')
set(gcf, 'Color', 'White', 'Alphamap', 0)
yticks([])
ylabel([])
xticks([])
xlabel([])
exportgraphics(gcf,'saved_plots/maps_and_errors_wheat.pdf','ContentType','vector')

f = figure();
f.Position = [100 100 580 500];
load('generated_data\cobo_av_prec_sea_100av_2025-06-16_06-15.mat')
simulation = (parameters.end_time - mean(result.A, 3)*(parameters.end_time-parameters.start_time))/1000;
[~, ~, t_max] = size(result.A);
plot_map_flat(parameters, parameters.dataset_bp/1000, false, simulation);
colormap(pepper)
title("Rice - sea and precipitation",'Interpreter','latex', 'FontSize',8*2, 'Color','k')
yticks([])
ylabel([])
xticks([])
xlabel([])
set(gcf, 'Color', 'White', 'Alphamap',0)
exportgraphics(gcf,'saved_plots/maps_and_errors_rice.pdf','ContentType','vector')

f = figure();
f.Position = [100 100 480 500];
load('generated_data\maize_av_prec_sea_100av_2025-06-18_05-15.mat')
simulation = (parameters.end_time - mean(result.A, 3)*(parameters.end_time-parameters.start_time))/1000;
[~, ~, t_max] = size(result.A);
plot_map_flat(parameters, parameters.dataset_bp/1000, false, simulation);
colormap(pepper)
title("Maize - sea and precipitation",'Interpreter','latex', 'FontSize',8*2, 'Color','k')
set(gcf, 'Color', 'White', 'Alphamap',0)
yticks([])
ylabel([])
xticks([])
xlabel([])
exportgraphics(gcf,'saved_plots/maps_and_errors_maize.pdf','ContentType','vector')

% saveas(gcf,"saved_plots/maps_and_errors.pdf")
%% dist vs time

custom_colors = [pepper(200,:);      
                pepper(5,:);  
                pepper(100,:)];

size_pt = 7;

% WHEAT
subplot(3,1,1)
hold on
load('generated_data\all_wheat_av_100av_2025-06-14_02-27.mat')
[min_time, min_time_idx] = min(parameters.dataset_bp);


dist = sqrt((parameters.dataset_lat-parameters.dataset_lat(min_time_idx)).^2 + (parameters.dataset_lon-parameters.dataset_lon(min_time_idx)).^2);
dist_km = deg2km(dist);

[max_time, max_time_idx] = max(dist_km);
[~, ~, t_max] = size(result.A);

s1 = scatter(parameters.dataset_bp, dist_km, 'Marker', '+');
s1.SizeData = size_pt;
s1.MarkerFaceColor = custom_colors(1,:);
s1.MarkerEdgeColor = custom_colors(1,:);
s1.MarkerFaceAlpha = 0.8;

simulation_times = parameters.start_time - result.times/t_max*(parameters.start_time-parameters.end_time);
A= [simulation_times(min_time_idx) simulation_times(max_time_idx)];
B=[dist_km(min_time_idx) dist_km(max_time_idx)];
s2 = line(A,B, 'LineWidth',1);
s2.Color = custom_colors(2,:);

load('generated_data\all_wheat_av_prec_sea_100av_2025-06-08_07-44.mat')
simulation_times = parameters.start_time - result.times/t_max*(parameters.start_time-parameters.end_time);
s3 = scatter(simulation_times, dist_km);
s3.MarkerFaceColor = custom_colors(3,:);
s3.MarkerEdgeAlpha = 0;
s3.SizeData = size_pt;
s3.MarkerFaceAlpha = 0.8;

s2 = line(A,B);
s2.LineWidth = 1;
s2.Color = custom_colors(2,:);

pt = scatter([A(1)],[B(1)]);
pt.SizeData = 200;
pt.LineWidth = 1.5;
pt.MarkerEdgeColor = 'k';
text(A(1),B(1)+2000, "origin",'HorizontalAlignment', 'center', 'Interpreter','latex','FontSize', 8)

% legend(["Original dataset",  "Average simulation", "Full simulation"], "Location", "northeast",'Interpreter','latex')
% xlabel("Time (yr)",'Interpreter','latex')
ylabel("Distance (km)",'Interpreter','latex')
title("\textbf{a.} Wheat", "FontSize",10,'Interpreter','latex')

ylim([-1000,7000])
xlim([-12000,2000])
set(gca,"TickLabelInterpreter",'latex')

% RICE 

subplot(3,1,2)

hold on
load('generated_data\cobo_av_100av_2025-07-10_15-10.mat')
[min_time, min_time_idx] = min(parameters.dataset_bp);
dist = sqrt((parameters.dataset_lat-parameters.dataset_lat(min_time_idx)).^2 + (parameters.dataset_lon-parameters.dataset_lon(min_time_idx)).^2);
dist_km = deg2km(dist);


[~, ~, t_max] = size(result.A);

s1 = scatter(parameters.dataset_bp, dist_km, 'Marker', '+');
s1.SizeData = size_pt;
s1.MarkerFaceColor = custom_colors(1,:);
s1.MarkerEdgeColor = custom_colors(1,:);
s1.MarkerFaceAlpha = 0.8;

simulation_times = parameters.start_time - result.times/t_max*(parameters.start_time-parameters.end_time);
[max_time, max_time_idx] = max(simulation_times);
A= [simulation_times(min_time_idx) simulation_times(max_time_idx)];
B=[dist_km(min_time_idx) dist_km(max_time_idx)];

s2 = line(A,B, 'LineWidth', 1);
s2.LineWidth = 2;
s2.Color = custom_colors(2,:);

pt = scatter([A(1)],[B(1)]);
pt.SizeData = 200;
pt.LineWidth = 1.5;
pt.MarkerEdgeColor = 'k';
text(A(1) + 150,B(1) + 2000, "origin 1",'HorizontalAlignment', 'center', 'Interpreter','latex','FontSize', 8)

second_dist = dist_km(dist_km>4000);
second_times = simulation_times(dist_km>4000);
[min_time, min_time_idx] = min(second_times);
[max_time, max_time_idx] = max(second_dist);
A2= [second_times(min_time_idx) second_times(max_time_idx)];
B2=[second_dist(min_time_idx) second_dist(max_time_idx)];
s22 = line(A2,B2);
s22.LineWidth = 2;
s22.Color = custom_colors(2,:);

pt = scatter([A2(1)],[B2(1)]);
pt.SizeData = 200;
pt.LineWidth = 1.5;
pt.MarkerEdgeColor = 'k';
text(A2(1)-200,B2(1) + 2000, "origin 2",'HorizontalAlignment', 'center', 'Interpreter','latex','FontSize', 8)

ylim([-1000, 7000])
xlim([-12000,2000])


load('generated_data\cobo_av_prec_sea_100av_2025-06-16_06-15.mat')
simulation_times = parameters.start_time - result.times/t_max*(parameters.start_time-parameters.end_time);
s3 = scatter(simulation_times, dist_km, 'filled');
s3.MarkerFaceColor = custom_colors(3,:);
s3.SizeData = size_pt;
s3.MarkerFaceAlpha = 0.8;

% xlabel("Time (year)",'Interpreter','latex')
ylabel("Distance (km)",'Interpreter','latex')
title("\textbf{b.} Rice", "FontSize",10,'Interpreter','latex')
set(gca,"TickLabelInterpreter",'latex')

% MAIZE
subplot(3,1,3)
hold on
load('generated_data\maize_av_100av_2025-06-16_09-06.mat')
[min_time, min_time_idx] = min(parameters.dataset_bp);


dist = sqrt((parameters.dataset_lat-parameters.dataset_lat(min_time_idx)).^2 + (parameters.dataset_lon-parameters.dataset_lon(min_time_idx)).^2);
dist_km = deg2km(dist);

[max_time, max_time_idx] = max(dist_km);
[~, ~, t_max] = size(result.A);

s1 = scatter(parameters.dataset_bp, dist_km, 'Marker' ,'+');
s1.SizeData = size_pt;
s1.MarkerEdgeColor = custom_colors(1,:);
s1.MarkerFaceColor = custom_colors(1,:);
s1.MarkerFaceAlpha = 0.8;

simulation_times = parameters.start_time - result.times/t_max*(parameters.start_time-parameters.end_time);
A= [simulation_times(min_time_idx) simulation_times(max_time_idx)];
B=[dist_km(min_time_idx) dist_km(max_time_idx)];

load('generated_data\maize_av_prec_sea_100av_2025-06-18_05-15.mat')
dist = sqrt((parameters.dataset_lat-parameters.dataset_lat(min_time_idx)).^2 + (parameters.dataset_lon-parameters.dataset_lon(min_time_idx)).^2);
dist_km = deg2km(dist);
simulation_times = parameters.start_time - result.times/t_max*(parameters.start_time-parameters.end_time);
s3 = scatter(simulation_times, dist_km, 'filled');
s3.MarkerFaceColor = custom_colors(3,:);
s3.SizeData = size_pt;
s3.MarkerFaceAlpha = 0.8;

s2 = line(A,B,'LineWidth',1);
s2.Color = custom_colors(2,:);

pt = scatter([A(1)],[B(1)]);
pt.SizeData = 200;
pt.LineWidth = 1.5;
pt.MarkerEdgeColor = 'k';
text(A(1),B(1)+2000, "origin",'HorizontalAlignment', 'center', 'Interpreter','latex','FontSize', 8)

xlabel("Time (yr)",'Interpreter','latex')
ylabel("Distance (km)",'Interpreter','latex')
title("\textbf{c.} Maize", "FontSize",10,'Interpreter','latex')


ylim([-1000,7000])
xlim([-12000,2000])
legend(["Original dataset",  "Average simulation", "Full simulation"], "Location", "southwest",'Interpreter','latex')

set(gca,"TickLabelInterpreter",'latex')

set(gca,"TickLabelInterpreter",'latex')
set(gcf, 'Color', 'White', 'Alphamap',0)

exportgraphics(gcf,"saved_plots/dist_vs_time.pdf", 'ContentType', 'vector')

%% Table

load('generated_data\filename_database.mat')

% Initialize LaTeX table
latex_table = sprintf('\\begin{table}[ht]\n');
latex_table = [latex_table sprintf('\\centering\n')];
latex_table = [latex_table sprintf('\\caption{Performance Comparison}\n')];
latex_table = [latex_table sprintf('\\label{tab:results}\n')];
latex_table = [latex_table sprintf('\\begin{tabular}{@{}c@{}}\n')]; % Single column wrapper
latex_table = [latex_table sprintf('\\toprule\n')];

% Process wheat data
wheat_table = sprintf('\\textbf{Wheat Dataset}\\\\\n');
wheat_table = [wheat_table sprintf('\\begin{tabular}{cccccc}\n')]; % Added column
wheat_table = [wheat_table sprintf('\\toprule\n')];
wheat_table = [wheat_table sprintf('Layers & $\\theta$ values & Avg error & Prob. diff. & Velocity diff. \\\\ \n')]; % New header
wheat_table = [wheat_table sprintf('\\midrule\n')];

% Process rice data
rice_table = sprintf('\\textbf{Rice Dataset}\\\\\n');
rice_table = [rice_table sprintf('\\begin{tabular}{cccccc}\n')]; % Added column
rice_table = [rice_table sprintf('\\toprule\n')];
rice_table = [rice_table sprintf('Layers & $\\theta$ values & Avg error & Prob. diff. & Velocity diff. \\\\ \n')]; % New header
rice_table = [rice_table sprintf('\\midrule\n')];

% Process maize data
maize_table = sprintf('\\textbf{Maize Dataset}\\\\\n');
maize_table = [maize_table sprintf('\\begin{tabular}{cccccc}\n')]; % Added column
maize_table = [maize_table sprintf('\\toprule\n')];
maize_table = [maize_table sprintf('Layers & $\\theta$ values & Avg error & Prob. diff. & Velocity diff. \\\\ \n')]; % New header
maize_table = [maize_table sprintf('\\midrule\n')];

for d = 1:length(database)
    % Skip entries that don't match criteria
    if (length(database{d}.layers) == 2)
        if ~(ismember('sea', database{d}.layers))
            continue
        end
    elseif length(database{d}.layers) == 1
        if ~(ismember({'sea'}, database{d}.layers)) && ~(ismember({'av'}, database{d}.layers))
            continue
        end
    end
    
    % Format data
    if strcmp(database{d}.layers{1},'av')
        layers_str = database{d}.layers{1};
        thetas_str = sprintf('%.2f',database{d}.theta);
    else
        layers_str = strjoin(database{d}.layers, ', ');
        thetas_str = strjoin(cellfun(@(x) sprintf('%.2f', x), num2cell(database{d}.theta), 'UniformOutput', false), ', ');
        thetas_str = sprintf('%.2f',database{d}.theta(2));
    end
    vmax = 110.567/4;
    load(database{d}.file)
    if length(theta_optim) > 1
        prob_diff = 1/(1+exp(theta_optim(1)+theta_optim(2))) - 1/(1+exp(theta_optim(1)));
        % Calculate velocity difference (example calculation - replace with your actual formula)
        velocity_diff = prob_diff*vmax; 
    else
        prob_diff = 1;
        velocity_diff = prob_diff*vmax; % Default value when no velocity difference available
    end
    
    % Add to appropriate subtable
    if contains(database{d}.dataset, 'wheat', 'IgnoreCase', true)
        wheat_table = [wheat_table sprintf('%s & %s & %.0f & %.2f & %.2f \\\\ \n', ...
            layers_str, thetas_str, sqrt(result.squared_error), prob_diff, velocity_diff)];
    elseif contains(database{d}.dataset, 'rice', 'IgnoreCase', true)
        rice_table = [rice_table sprintf('%s & %s & %.0f & %.2f & %.2f \\\\ \n', ...
            layers_str, thetas_str, sqrt(result.squared_error), prob_diff, velocity_diff)];
    elseif contains(database{d}.dataset, 'maize', 'IgnoreCase', true)
        maize_table = [maize_table sprintf('%s & %s & %.0f & %.2f & %.2f \\\\ \n', ...
            layers_str, thetas_str, sqrt(result.squared_error), prob_diff, velocity_diff)];
    end
end

% Close subtables
wheat_table = [wheat_table sprintf('\\bottomrule\n')];
wheat_table = [wheat_table sprintf('\\end{tabular}\n')];
rice_table = [rice_table sprintf('\\bottomrule\n')];
rice_table = [rice_table sprintf('\\end{tabular}\n')];
maize_table = [maize_table sprintf('\\bottomrule\n')];
maize_table = [maize_table sprintf('\\end{tabular}\n')];

% Combine tables with spacing
latex_table = [latex_table wheat_table];
latex_table = [latex_table sprintf('\\\\[2ex]\n')]; % Vertical space between tables
latex_table = [latex_table rice_table];
latex_table = [latex_table sprintf('\\\\[2ex]\n')]; % Vertical space between tables
latex_table = [latex_table maize_table];
latex_table = [latex_table sprintf('\\bottomrule\n')];
latex_table = [latex_table sprintf('\\end{tabular}\n')];
latex_table = [latex_table sprintf('\\end{table}\n')];



% Write to file
fid = fopen('results_table.tex', 'w');
fprintf(fid, '%s', latex_table);
fclose(fid);
disp('LaTeX table saved to results_table.tex');