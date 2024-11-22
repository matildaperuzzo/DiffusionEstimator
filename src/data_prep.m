function parameters = data_prep(n_averages, active_layers)

    parameters = struct();
    % load build
    load('data/prep/geography_0p5deg.mat');
    
    
    % load pinhasi
    pinhasi = readtable( ...
        'data/raw/pinhasi/Neolithic_timing_Europe_PLOS.xls');

    pinhasi = pinhasi(pinhasi.Var1 == "SITE",:); %% keep only site rows

    pinhasi = renamevars(pinhasi, {'Latitude', 'Longitude', 'CALC14BP'}, ...
        {'lat', 'lon', 'bp'});

    pinhasi = pinhasi(:,{'lat', 'lon', 'bp'});
    pinhasi.bp = 2000 - pinhasi.bp; % from BP to year

    parameters.dataset_lat = pinhasi.lat;
    parameters.dataset_lon = pinhasi.lon;
    parameters.dataset_bp = pinhasi.bp;

    % restrict to Europe/Iran range
    topleft = [60, -17.19];
    bottomright = [15, 65.07];

    latidx = lat <= topleft(1) & lat >= bottomright(1);
    lonidx = lon >= topleft(2) & lon <= bottomright(2);

    latp = lat(latidx);
    lonp = lon(lonidx);
    parameters.lat = [latp(1) latp(end)];
    parameters.lon = [lonp(1) lonp(end)];


    % define time array
    parameters.dt = 40; % time step in years
    parameters.start_time = floor(min(pinhasi.bp)/parameters.dt)*parameters.dt;
    parameters.end_time = ceil(max(pinhasi.bp)/parameters.dt)*parameters.dt + 500; % add 1000 years to end_time
    parameters.T = round((parameters.end_time - parameters.start_time)/parameters.dt + 1);

    parameters.times = parameters.start_time:parameters.dt:parameters.end_time;

    % create matrix storing x,y,t indices coordinates of pinhasi sites
    parameters.dataset_idx = zeros(length(pinhasi.lat),3);
    for event_index = 1:length(pinhasi.lat)
        lat_event = pinhasi.lat(event_index);
        lon_event = pinhasi.lon(event_index);
        [~, index_x] = min(abs(latp - lat_event));
        [~, index_y] = min(abs(lonp - lon_event));
 
        [~, index_t] = min(abs(parameters.times - pinhasi.bp(event_index)));
        parameters.dataset_idx(event_index,:) = [index_x, index_y, index_t];
    end

    % create the X vector
    X = {};
    if active_layers(3)
        % add csi data
        csidata = csidata(latidx,lonidx);
        csi_mean = mean(csidata(:));
        csi_std = std(csidata(:));
        csidata = (csidata-csi_mean)./csi_std;
        X{length(X)+1} = csidata;
    end
    if active_layers(4)
        hydro = acc.data;
        hydro = hydro(latidx,lonidx);
        hydro(isnan(hydro)) = 0;
        hydro_mean = mean(hydro(:));
        hydro_std = std(hydro(:));
        hydro = (hydro-hydro_mean)/hydro_std;
        X{length(X)+1} = hydro;
    end

    if length(active_layers) > 4
        for i = 5:length(active_layers)
            if active_layers(i)
                layer = potveg(i-4).pot_veg_data;
                layer = layer(latidx,lonidx);
                X{length(X)+1} = layer;
            end
        end
    end

    parameters.X = X;

    % initialize A
    parameters.A = false(length(latp), length(lonp), parameters.T);
    [~, earliest_event] = min(parameters.dataset_idx(:,3));
    parameters.A(parameters.dataset_idx(earliest_event,1), parameters.dataset_idx(earliest_event,2), 1) = true;
    % set a seed and define matrix of random numbers
    % rng(12);
    % U = rand(length(latp), length(lonp), parameters.T, n_averages);
    parameters.n = n_averages;
    parameters.active_layers = active_layers;

end