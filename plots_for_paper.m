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
color1 = [5/255, 66/255, 92/255];   
color2 = [165/255, 154/255, 109/255];  
color3 = [254/255, 240/255, 85/255];   


% Number of points in your colormap:
numColors = 256; 
% Create a colormap by interpolating between these colors:
pepper = interp1(linspace(1,256,4), [color0; color1; color2; color3], linspace(1, 256, numColors));

% Define the three colors (RGB format):
colors = [[0,0,0]; [5,66,92]/255; [165,154,109]/255; [239, 209, 101]/255; [254, 240, 85]/255; [255,252,209]/255];

% Number of points in your colormap:
numColors = 256; 
% Create a colormap by interpolating between these colors:
eclipse = interp1(linspace(1,256,length(colors)), colors, linspace(1, 256, numColors));

% Define the three colors (RGB format):
color1 = [30/255, 51/255, 110/255];   % Blue
color2 = [235/255, 232/255, 198/255];   % White
color3 = [110/255, 20/255, 30/255];   % Red

% Number of points in your colormap:
numColors = 256; 

% Create a colormap by interpolating between these colors:
redblue = interp1([1, 128, 256], [color1; color2; color3], linspace(1, 256, numColors));

colors = [[0.0196078431372549,0.0392156862745098,0.6745098039215687]; [0.2196078431372549,0.2901960784313726,0.8235294117647058]; 
    [0.41568627450980394,0.5372549019607843,0.9686274509803922]; [0.7450980392156863,0.7450980392156863,0.7450980392156863]; 
    [0.9019607843137255,0.5686274509803921,0.35294117647058826]; [0.8,0.3058823529411765,0.23137254901960785];
    [0.6980392156862745,0.0392156862745098,0.10980392156862745]];
redblue_detailed = interp1(linspace(1,256,length(colors)), colors, linspace(1, 256, numColors));

%% Diffusion plot
addpath('src');
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
cmap = slanCM('romao'); 
colormap(cmap)

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
colormap(cmap)

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
colormap(cmap)

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


colormap(cmap)

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
% load('generated_data\all_wheat_av_tmean_sea_100av_2026-01-06_09-02.mat')
load("C:\Users\mperuzzo\OneDrive - Nexus365\Documents\bottlenecks\generated_data\all_wheat_av_prec_sea_100av_2026-01-06_08-37.mat")

%%
[nx,ny] = size(parameters.X{1});
X = linspace(parameters.lat(1), parameters.lat(2), nx);
Y = linspace(parameters.lon(1), parameters.lon(2), ny);
f = figure(1);
pepper_bright = fliplr(cmap);
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
% saveas(gcf,"saved_plots/prec_layer.pdf")
exportgraphics(gcf,'saved_plots/prec_layer.pdf','ContentType','vector')

%% %% Plot objective function
load("generated_data/all_wheat_obj.mat")
cmap = slanCM('romao');
[X,Y] = meshgrid(theta_0,theta_1);
points = [[2.28 -0.16 1.61543+0.07]; [2.92 -0.56 1.02808+0.05];  [3.16 -0.72 0.721299+0.05]; [3.24 -0.96 0.475222+0.05]; [3.24 -1.04 0.4348+0.05]; [3.2 -1.12 0.413622+0.05]];

f = figure(1)
hold on
f.Position = [100 100 700 400];
set(gcf, 'Color', 'White', 'Alphamap',0)
plot_errors = log10(all_errors/1e6);
s = mesh(X,Y,plot_errors');
% Plot lines between points
lineColor = [110/255, 20/255, 30/255];

[min_err, id] = min(plot_errors(:));
[idx,idy] = ind2sub(size(plot_errors),id);

points_xy = [[3.2 -1.7];[3.1 -1.4];[2.9 -1.2];[2.75 -1.0];[2.71 -0.9];[2.69 -0.82]];
points = [];

for i=1:length(points_xy)
    [~, id_0] = min(abs(points_xy(i,1)-theta_0));
    [~, id_1] = min(abs(points_xy(i,2)-theta_1));
    points = [points; theta_0(id_0), theta_1(id_1), plot_errors(id_0,id_1)+0.1];
end

plot3(points(:,1), points(:,2), points(:,3), ...
    '-', 'LineWidth', 1.5, 'Color', lineColor);

% Plot points as scatter3
scatter3(points(:,1), points(:,2), points(:,3), ...
    20, lineColor, 'filled');
s.FaceColor = 'flat';
s.FaceAlpha = 1;

clim([0.15,1.])
colormap(cmap)
view([180-70 40])
ax = gca;
ax.FontSize = 16; 
xlabel("$\theta_{prec}$", 'Rotation', 55, "FontSize",16)
ylabel("$\theta_{tmean}$", 'Rotation', -5, "FontSize",16)
zlabel("Objective function (a.u.)", "FontSize",16)

% saveas(gcf,"saved_plots/Obj_func.pdf")
exportgraphics(gcf,'saved_plots/Obj_func.pdf','ContentType','vector')
%% Bar chart results plot
addpath("src")

load('generated_data\filename_database.mat')

load('generated_data\all_wheat_av_100av_2026-01-06_01-26.mat')
if exist('bs_errors')
    errors = bs_errors;
elseif exist('spread_sq_errors_boot')
    errors = spread_sq_errors_boot;
else
    errors = [result.squared_error];
end
labels_w = {};
labels_w{1} = "av";
sq_errors_w = [mean(errors)];
yr_errors_w = [mean(errors.^0.5)];
yr_errorbar_w = [std(errors.^0.5)];
clear bs_errors spread_sq_errors_boot errors

load('generated_data\cobo_av_100av_2026-01-05_08-27.mat')
if exist('bs_errors')
    errors = bs_errors;
elseif exist('spread_sq_errors_boot')
    errors = spread_sq_errors_boot;
else
    errors = [result.squared_error];
end
% result = run_model(parameters, theta_optim);
labels_r = {};
labels_r{1} = "av";
sq_errors_r = [mean(errors)];
yr_errors_r = [mean(errors.^0.5)];
yr_errorbar_r = [std(errors.^0.5)];
clear bs_errors spread_sq_errors_boot errors

load('generated_data\maize_av_100av_2026-01-29_10-10.mat')
if exist('bs_errors')
    errors = bs_errors;
elseif exist('spread_sq_errors_boot')
    errors = spread_sq_errors_boot;
else
    errors = [result.squared_error];
end
% result = run_model(parameters, theta_optim);
labels_m = {};
sq_errors_m = [mean(errors)];
yr_errors_m = [mean(errors.^0.5)];
yr_errorbar_m = [std(errors.^0.5)];
clear bs_errors spread_sq_errors_boot errors

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
        if exist('bs_errors')
            errors = bs_errors;
        elseif exist('spread_sq_errors_boot')
            errors = spread_sq_errors_boot;
        else
            errors = [result.squared_error];
        end
        sq_errors_w = [sq_errors_w mean(errors)];
        yr_errors_w = [yr_errors_w mean(errors.^0.5)];
        yr_errorbar_w = [yr_errorbar_w std(errors.^0.5)];
        clear bs_errors spread_sq_errors_boot errors

    elseif ismember('rice', database{i}.dataset)
        disp(database{i}.layers)
        labels_r{length(labels_r)+1} = database{i}.layers{1};
        load(database{i}.file)
        if exist('bs_errors')
                errors = bs_errors;
        elseif exist('spread_sq_errors_boot')
            errors = spread_sq_errors_boot;
        else
            errors = [result.squared_error];
        end
        sq_errors_r = [sq_errors_r mean(errors)];
        yr_errors_r = [yr_errors_r mean(errors.^0.5)];
        yr_errorbar_r = [yr_errorbar_r std(errors.^0.5)];
        clear bs_errors spread_sq_errors_boot errors

    elseif ismember('maize',database{i}.dataset)
        disp(database{i}.layers)
        labels_m{length(labels_m)+1} = database{i}.layers{1};
        load(database{i}.file)
        if exist('bs_errors')
            errors = bs_errors;
        elseif exist('spread_sq_errors_boot')
            errors = spread_sq_errors_boot;
        else
            errors = [result.squared_error];
        end
        sq_errors_m = [sq_errors_m mean(errors)];
        yr_errors_m = [yr_errors_m mean(errors.^0.5)];
        yr_errorbar_m = [yr_errorbar_m std(errors.^0.5)];
        clear bs_errors spread_sq_errors_boot errors

    end

    clear bs_errors

end

[yr, w_idx] = sort(sq_errors_w, 'descend');
% w_idx = [1 4 3 7 6 2 5];
w_idx = [1 7 4 2 3 6 5]
yr_errors = [yr_errors_w(w_idx); yr_errors_r(w_idx); yr_errors_m(w_idx)];
sq_errors = [sq_errors_w(w_idx); sq_errors_r(w_idx); sq_errors_m(w_idx)];
yr_errorbar = [yr_errorbar_w(w_idx); yr_errorbar_r(w_idx); yr_errorbar_m(w_idx)];

%% horizontal bar chart
f = figure(1);
f.Position = [100 100 800 180];
x_errorbar = [-3 -2 -1 0 1 2 3].*0.115;
tiledlayout(1,3, 'Padding', 'none', 'TileSpacing', 'compact'); 
for p = 1:3
    nexttile    
    hold on
    b2 = barh([0], fliplr(yr_errors(p,:))/1e3, 0.95);
    cmap = slanCM('romao');
    yticks([])
    ylabel({"Geographical layer"},'Interpreter','latex', "FontSize",8, 'Rotation',90, 'Color','k')
    if p == 1
        title("Wheat",'Interpreter','latex', 'Color','k')
        e1 = errorbar(yr_errors_w(fliplr(w_idx))/1e3, x_errorbar,yr_errorbar_w(fliplr(w_idx))/1e3, 'horizontal', "LineStyle","none", 'CapSize',6, 'Color', 'k', "LineWidth",1);
    elseif p == 2
        title("Rice",'Interpreter','latex', 'Color','k')
        e2 = errorbar(yr_errors_r(fliplr(w_idx))/1e3, x_errorbar,yr_errorbar_r(fliplr(w_idx))/1e3, 'horizontal', "LineStyle","none", 'CapSize',6, 'Color', 'k', "LineWidth",1);
    elseif p == 3
        title("Maize",'Interpreter','latex', 'Color','k')
        e2 = errorbar(yr_errors_m(fliplr(w_idx))/1e3, x_errorbar,yr_errorbar_m(fliplr(w_idx))/1e3, 'horizontal', "LineStyle","none", 'CapSize',6, 'Color', 'k', "LineWidth",1);
    end
    
    % Gradient coloring
    
    layer_names = {"Baseline",'Anisotropy','Crop suitability','River size','Precipitation','Mean temperature',"Sea only"};
    for k = 1:length(yr_errors_r)
        b2(k).FaceColor = cmap(int16((k)*(length(cmap))/(length(yr_errors_r)+1)),:);
        b2(k).EdgeAlpha = 0;
        ypos = b2(k).XEndPoints;  % Get x-position of bars
        xpos = b2(k).YEndPoints+0.02;  % Get y-position of bars
        text(zeros(size(ypos))+0.02, ypos, layer_names{w_idx(length(yr_errors_r)-k+1)}, ...
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 8,'Interpreter','latex','Rotation',0, 'Color','w');
    end 
    xlabel("Average error (kyears)","FontSize", 8,'Interpreter','latex', 'Color','k')
    xlim([0,1.8])
    set(gca,"TickLabelInterpreter",'latex', 'Color','k')
    set(gcf, 'Color', 'White', 'Alphamap', 1)
    set(gca, 'Color', 'White', 'Alphamap', 1)
    set(gca, 'XColor', [0, 0, 0])
    set(gca, 'YColor', [0, 0, 0])
    grid on
end

set(gcf, 'Color', 'White', 'Alphamap',1)

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
    cmap = slanCM('romao'); %interp1([1, 128, 256], [color1; color2; color3], linspace(1, 256, numColors));
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
load('generated_data\all_wheat_av_100av_2026-01-06_01-26.mat')
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
load('generated_data\cobo_av_100av_2026-01-05_08-27.mat')
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
load('generated_data\maize_av_100av_2026-01-29_10-10.mat')
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
load('generated_data\all_wheat_av_prec_sea_100av_2026-01-06_08-37.mat')
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
load('generated_data\cobo_av_prec_sea_100av_2026-01-07_02-03.mat')
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
load('generated_data\maize_av_prec_sea_100av_2026-01-15_14-16.mat')
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
title("Maize - sea and precipitation",'Interpreter','latex', 'FontSize',10)
set(gca,"TickLabelInterpreter",'latex')
grid on
yticks([-5,-2.5,0,2.5,5])
yticklabels([])

% saveas(gcf,"saved_plots/results_error_plots.pdf")
exportgraphics(gcf,'saved_plots/results_error_plots.pdf','ContentType','vector')

%% map plot 1 x 2
addpath("src")
c_map = slanCM('romao');
% c_map = eclipse;
% best: fall, coolwarm, eclipse(mine), romao

f = figure();
f.Position = [100 100 800 500];
load('generated_data\all_wheat_av_prec_sea_100av_2026-01-06_08-37.mat')
simulation = (parameters.end_time - mean(result.A, 3)*(parameters.end_time-parameters.start_time))/1000;
[~, ~, t_max] = size(result.A);
plot_map_flat(parameters, parameters.dataset_bp/1000, false, simulation);
colormap(c_map)
title("Wheat - sea and precipitation",'Interpreter','latex', 'FontSize',8*2, 'Color','k')
set(gcf, 'Color', 'White', 'Alphamap', 0)
yticks([])
ylabel([])
xticks([])
xlabel([])
exportgraphics(gcf,'saved_plots/maps_and_errors_wheat.svg','ContentType','vector')

f = figure();
f.Position = [100 100 700 500];
load('generated_data\cobo_av_prec_sea_100av_2026-01-07_02-03.mat')
simulation = (parameters.end_time - mean(result.A, 3)*(parameters.end_time-parameters.start_time))/1000;
[~, ~, t_max] = size(result.A);
plot_map_flat(parameters, parameters.dataset_bp/1000, false, simulation, [1 .9 1]);
colormap(c_map)
title("Rice - sea and precipitation",'Interpreter','latex', 'FontSize',8*2, 'Color','k')
yticks([])
ylabel([])
xticks([])
xlabel([])
set(gcf, 'Color', 'White', 'Alphamap',0)
exportgraphics(gcf,'saved_plots/maps_and_errors_rice.svg','ContentType','vector')

f = figure();
f.Position = [100 100 500 500];
load('generated_data\maize_av_prec_sea_100av_2026-01-15_14-16.mat')
simulation = (parameters.end_time - mean(result.A, 3)*(parameters.end_time-parameters.start_time))/1000;
[~, ~, t_max] = size(result.A);
plot_map_flat(parameters, parameters.dataset_bp/1000, false, simulation);
colormap(c_map)
title("Maize - sea and precipitation",'Interpreter','latex', 'FontSize',8*2, 'Color','k')
set(gcf, 'Color', 'White', 'Alphamap',0)
yticks([])
ylabel([])
xticks([])
xlabel([])
exportgraphics(gcf,'saved_plots/maps_and_errors_maize.svg','ContentType','vector')

% saveas(gcf,"saved_plots/maps_and_errors.pdf")
%% dist vs time
cmap = slanCM('romao');
custom_colors = [cmap(160,:);     %origin data 
                [0 0 0];    %line
                cmap(20,:)];   % simulation

size_pt = 7;
f = figure();
f.Position = [100 100 500 380];
tiledlayout(3,1, 'Padding', 'none', 'TileSpacing', 'compact'); 
% WHEAT
nexttile
hold on
load('generated_data\all_wheat_av_100av_2026-01-06_01-26.mat')
[min_time, min_time_idx] = min(parameters.dataset_bp);

wgs84 = wgs84Ellipsoid("m");
dist = distance(parameters.dataset_lat, parameters.dataset_lon, parameters.dataset_lat(min_time_idx), parameters.dataset_lon(min_time_idx), wgs84);
dist_km = dist/1000;

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

load('generated_data\all_wheat_av_prec_sea_100av_2026-01-06_08-37.mat')
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
pt.LineWidth = 1.;
pt.MarkerEdgeColor = 'k';
text(A(1),B(1)+2000, "origin",'HorizontalAlignment', 'center', 'Interpreter','latex','FontSize', 8)

% legend(["Original dataset",  "Average simulation", "Full simulation"], "Location", "northeast",'Interpreter','latex')
% xlabel("Time (yr)",'Interpreter','latex')
ylabel("Distance (km)",'Interpreter','latex')
title("Wheat", "FontSize",10,'Interpreter','latex')

ylim([-1000,7000])
xlim([-12000,2000])
set(gca,"TickLabelInterpreter",'latex')

% RICE 

nexttile
hold on
load('generated_data\cobo_av_100av_2026-01-06_08-00.mat')
[min_time, min_time_idx] = min(parameters.dataset_bp);
dist = distance(parameters.dataset_lat, parameters.dataset_lon, parameters.dataset_lat(min_time_idx), parameters.dataset_lon(min_time_idx), wgs84);
dist_km = dist/1000;

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

s2 = line(A,B, 'LineWidth', 1.);
s2.LineWidth = 1.;
s2.Color = custom_colors(2,:);

pt = scatter([A(1)],[B(1)]);
pt.SizeData = 200;
pt.LineWidth = 1.;
pt.MarkerEdgeColor = 'k';
text(A(1) + 150,B(1) + 2000, "origin 1",'HorizontalAlignment', 'center', 'Interpreter','latex','FontSize', 8)

second_dist = dist_km(dist_km>3500);
second_times = simulation_times(dist_km>3500);
[min_time, min_time_idx] = min(second_times);
[max_time, max_time_idx] = max(second_dist);
A2= [second_times(min_time_idx) second_times(max_time_idx)];
B2=[second_dist(min_time_idx) second_dist(max_time_idx)];
s22 = line(A2,B2);
s22.LineWidth = 1;
s22.Color = custom_colors(2,:);

pt = scatter([A2(1)],[B2(1)]);
pt.SizeData = 200;
pt.LineWidth = 1.;
pt.MarkerEdgeColor = 'k';
text(A2(1)-200,B2(1) + 2000, "origin 2",'HorizontalAlignment', 'center', 'Interpreter','latex','FontSize', 8)

ylim([-1000, 7000])
xlim([-12000,2000])


load('generated_data\cobo_av_prec_sea_100av_2026-01-07_02-03.mat')
simulation_times = parameters.start_time - result.times/t_max*(parameters.start_time-parameters.end_time);
s3 = scatter(simulation_times, dist_km, 'filled');
s3.MarkerFaceColor = custom_colors(3,:);
s3.SizeData = size_pt;
s3.MarkerFaceAlpha = 0.8;

% xlabel("Time (year)",'Interpreter','latex')
ylabel("Distance (km)",'Interpreter','latex')
title("Rice", "FontSize",10,'Interpreter','latex')
set(gca,"TickLabelInterpreter",'latex')

% MAIZE
nexttile
hold on
load('generated_data\maize_av_100av_2026-01-29_10-10.mat')
[min_time, min_time_idx] = min(parameters.dataset_bp);

dist = distance(parameters.dataset_lat, parameters.dataset_lon, parameters.dataset_lat(min_time_idx), parameters.dataset_lon(min_time_idx), wgs84);
dist_km = dist/1000;

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

load('generated_data\maize_av_prec_sea_100av_2026-01-15_14-16.mat')
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
pt.LineWidth = 1.;
pt.MarkerEdgeColor = 'k';
text(A(1),B(1)+2000, "origin",'HorizontalAlignment', 'center', 'Interpreter','latex','FontSize', 8)

xlabel("Time (yr)",'Interpreter','latex')
ylabel("Distance (km)",'Interpreter','latex')
title("Maize", "FontSize",10,'Interpreter','latex')


ylim([-1000,7000])
xlim([-12000,2000])
legend(["Original dataset", "Simulation with geography", "Baseline estimate"], "Location", "southwest",'Interpreter','latex')

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