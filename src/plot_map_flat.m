function plot_map_flat(parameters, errors, adjust_scale, A_result, aspect)
    % Load data and setup parameters
    if nargin > 3
        A = A_result;
    else
        A = parameters.A;
    end
    pinhasi_active = parameters.dataset_idx;
    land = shaperead('landareas.shp', 'UseGeoCoords', true);
    
    % Calculate aspect ratio for square plot
    lat_range = parameters.lat;
    lon_range = parameters.lon;
    aspect_ratio = .75*(lon_range(2)-lon_range(1))/(lat_range(2) - lat_range(1) );
    
    % Create axes with equal aspect ratio
    hold on;
    
    % Create geographic reference
    R = georefcells(parameters.lat, parameters.lon, size(parameters.A(:,:,1)));
    
    % Plot base map
    if nargin > 3
        imagesc(parameters.lon, parameters.lat, A, [min(errors) max(errors)]);
    end
    axis xy;
    
    % Overlay land areas
    geoshow(fliplr([land.Lat]), fliplr([land.Lon]), 'DisplayType', ...
           'Polygon', 'FaceColor', 'white', 'FaceAlpha', 0.5, "LineWidth", 0.1);
    
    % Create custom colormap
    color1 = [30/255, 51/255, 110/255];   % Blue
    color2 = [235/255, 232/255, 198/255]; % White
    color3 = [110/255, 20/255, 30/255];   % Red
    cmap = interp1([1, 128, 256], [color1; color2; color3], linspace(1, 256, 256));
    colormap(cmap);
    
    % Plot error points
    s = scatter(parameters.dataset_lon, parameters.dataset_lat, 8, errors, 'filled', 'MarkerEdgeColor', [0.2, 0.2, 0.2], 'LineWidth', .05);
    s.MarkerEdgeAlpha = 0.2;
    % Set color limits
    if nargin > 2 && adjust_scale
        max_abs_value = max(abs(errors(:)));
        clim([-max_abs_value, max_abs_value]);
    else
        clim([min(errors(:)), max(errors(:))]);
    end
    
    % Add colorbar
    cb = colorbar;
    cb.FontSize = 8;
    cb.Location = "southoutside";
    set(cb, 'TickLabelInterpreter', 'latex', 'FontSize', 8*2);
    ylabel(cb, '$\hat{Y}_\ell, Y_\ell$ (kyears)', 'FontSize', 8*2, 'Interpreter', 'latex', 'Rotation',0, 'Color','k');
    % tickLabels = cb.TickLabels; % Get current tick labels
    % for i = 1:length(tickLabels)
    %     tickLabels{i} = ['\textcolor{black}{', tickLabels{i}, '}']; % Wrap in color command
    % end
    % cb.TickLabels = tickLabels;
    cb.TickLabelInterpreter = 'latex';
    cb.Color = 'k';
    cb
    
    % Adjust axes
    xlim([min(parameters.lon) max(parameters.lon)]);
    ylim([min(parameters.lat) max(parameters.lat)]);
    xlabel('Longitude', 'FontSize', 8, 'Interpreter', 'latex');
    ylabel('Latitude', 'FontSize', 8, 'Interpreter', 'latex');
    set(gca,"TickLabelInterpreter",'latex')
    grid on;
    box on;
    
    if nargin > 4
        % Equal aspect ratio
        daspect(aspect);
    end
end