function parameters = create_dataset(theta, n_averages, start_point)
    parameters = struct();
    load('data/prep/geography.mat', 'lat', 'lon', 'csidata');
    
    land = shaperead('landareas.shp', 'UseGeoCoords', true);
    
    topleft = [60, -17.19];
    bottomright = [15, 65.07];
    
    % skip every other element of longitude and latitude
    skip = 2;
    lat = lat(1,1:skip:end);
    lon = lon(1,1:skip:end);
    csidata = csidata(1:skip:end,1:skip:end);
    
    latidx = lat <= topleft(1) & lat >= bottomright(1);
    lonidx = lon >= topleft(2) & lon <= bottomright(2);
    
    latp = lat(latidx);
    lonp = lon(lonidx);
    csidata = csidata(latidx,lonidx);
    % add terrain data
    parameters.terrain = csidata;
    parameters.terrain = parameters.terrain/max(parameters.terrain(:));
    parameters.terrain = parameters.terrain-mean(parameters.terrain(:))/std(parameters.terrain(:));
    
    parameters.lat = [latp(1) latp(end)];
    parameters.lon = [lonp(1) lonp(end)];
    
    
    % define time array
    parameters.dt = 20; % time step in years
    parameters.start_time = - 10000;
    parameters.end_time = 2000;
    parameters.T = round((parameters.end_time - parameters.start_time)/parameters.dt + 1);
    
    parameters.times = parameters.start_time:parameters.dt:parameters.end_time;
    
    % select 100 points on land with random lat and lon
    % and plot them
    n = 1000;
    dataset_lat = zeros(n,1);
    dataset_lon = zeros(n,1);
    dataset_lat(1) = start_point(1);
    dataset_lon(1) = start_point(2);
    for i = 2:n
    
        dataset_lat(i) = topleft(1) + (bottomright(1) - topleft(1) ) * rand;
        dataset_lon(i) = topleft(2) + (bottomright(2) - topleft(2) ) * rand;
        
        % check if point is on land or in ocean
        isOnLand = inpolygon(dataset_lon(i), dataset_lat(i), [land.Lon], [land.Lat]);
        % check distance to starting point
        distance = sqrt((dataset_lat(i) - dataset_lat(1))^2 + (dataset_lon(i) - dataset_lon(1))^2);

        % if point is in ocean, generate new random coordinates
        while (~isOnLand || distance > 30)
            dataset_lat(i) = topleft(1) + (bottomright(1) - topleft(1) ) * rand;
            dataset_lon(i) = topleft(2) + (bottomright(2) - topleft(2) ) * rand;
            isOnLand = inpolygon(dataset_lon(i), dataset_lat(i), [land.Lon], [land.Lat]);
            distance = sqrt((dataset_lat(i) - dataset_lat(1))^2 + (dataset_lon(i) - dataset_lon(1))^2);
        end
    end
    
    
    parameters.dataset_lat = dataset_lat;
    parameters.dataset_lon = dataset_lon;
    
    % create matrix storing x,y,t indices coordinates of pinhasi sites
    parameters.dataset_idx = ones(n,3);
    parameters.A = false(length(latp), length(lonp), parameters.T);
    [~, start_idx_x] = min(abs(latp - dataset_lat(1)));
    [~, start_idx_y] = min(abs(lonp - dataset_lon(1)));
    parameters.dataset_idx(1,:) = [start_idx_x, start_idx_y, 1];
    
    for event_index = 1:n
    
        [~, index_x] = min(abs(latp - dataset_lat(event_index)));
        [~, index_y] = min(abs(lonp - dataset_lon(event_index)));
    
        parameters.dataset_idx(event_index,1:2) = [index_x, index_y];
    end

    parameters.A(start_idx_x, start_idx_y, 1) = true;
    parameters.n = n_averages;
    load("data/U_mat.mat","U");
    parameters.U = U(:,:,:,1:n_averages);
    result = run_model(parameters, theta);
    parameters.dataset_idx(:,3) = result.times; 
    % Define the three colors (RGB format):
    color1 = [23/255, 42/255, 80/255];   % Blue
    color2 = [235/255, 232/255, 198/255];   % White
    color3 = [80/255, 13/255, 23/255];   % Red

    % Number of points in your colormap:
    numColors = 256; 

    % % Create a colormap by interpolating between these colors:
    % cmap = interp1([1, 128, 256], [color1; color2; color3], linspace(1, 256, numColors));
    % 
    % colormap(cmap)
    % loc = 10;
    % fwidth = 20;
    % % plot dataset sites colored by time
    % figure('Units','inches','Position',[loc loc fwidth fwidth/2.2], ...
    % 'PaperPosition',[.25 .25 8 6]);
    % hold on;
    % 
    % worldmap(["Ireland", "Iran"])
    % axis xy
    % geoshow(fliplr([land.Lat]),fliplr([land.Lon]),'DisplayType', ...
    %     'Polygon', 'FaceColor', 'white', 'FaceAlpha', 0.5)
    % scatterm(parameters.dataset_lat, parameters.dataset_lon, 10, parameters.dataset_idx(:,3), 'filled');
    % cb = colorbar;
    % ylabel(cb,'t_{data} (years)','FontSize',16);
    % title("Dataset sites colored by time")

    
end