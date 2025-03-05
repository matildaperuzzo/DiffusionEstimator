function plot_map(parameters,errors, adjust_scale, A_result)

    if nargin > 3
        A = A_result;
    else
        A = parameters.A;
    end
    pinhasi_active = parameters.dataset_idx;
    land = shaperead('landareas.shp', 'UseGeoCoords', true);

    R = georefcells(parameters.lat, parameters.lon, ...
        size(parameters.X{1}));
    loc = 10;
    fwidth = 20;
    tic
    f = figure('Units','inches','Position',[loc loc fwidth fwidth/2.2], ...
    'PaperPosition',[.25 .25 8 6]);
    hold on;

    latlim = parameters.lat;
    lonlim = parameters.lon;

    worldmap(latlim, lonlim)
    
    axis xy

    % color map with A
    % geoshow(sum(A,3), R, 'DisplayType', 'texturemap')
    %make sea white
    
    geoshow(fliplr([land.Lat]),fliplr([land.Lon]),'DisplayType', ...
        'Polygon', 'FaceColor', 'white', 'FaceAlpha', 0.5)

    framem('FLineWidth', 1, 'FontSize', 7)
    [size_x size_y size_t] = size(A);
    predictions = size_t - pinhasi_active(:,3);
    
    % Define the three colors (RGB format):
    color1 = [30/255, 51/255, 110/255];   % Blue
    color2 = [235/255, 232/255, 198/255];   % White
    color3 = [110/255, 20/255, 30/255];   % Red

    % Number of points in your colormap:
    numColors = 256; 

    % Create a colormap by interpolating between these colors:
    cmap = interp1([1, 128, 256], [color1; color2; color3], linspace(1, 256, numColors));

    % addpath('cmaps');
    % colormap(flipud(brewermap([],'Spectral')))
    colormap(cmap)

    % Loop over each point and plot with the corresponding color
    scatterm(parameters.dataset_lat, parameters.dataset_lon, 20, errors, 'filled');
    cb = colorbar;
    ylabel(cb,'t_{data} - t_{sim}','FontSize',16);
    max_abs_value = max(abs(errors(:)));

    if nargin > 2
        if adjust_scale
            max_abs_value = max(abs(errors(:)));
            clim([-max_abs_value, max_abs_value]);
        else
            clim([min(errors(:)),max(errors(:))])
        end
        ylabel(' ')
    end


end
