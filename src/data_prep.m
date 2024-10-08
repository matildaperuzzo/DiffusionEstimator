function parameters = data_prep()

    parameters = struct();
    % load build
    load('data/prep/geography.mat', 'lat', 'lon', 'csidata');
    
    
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
    parameters.lat = [latp(1) latp(end)];
    parameters.lon = [lonp(1) lonp(end)];
    

    % define time array
    parameters.dt = 20; % time step in years
    parameters.start_time = floor(min(pinhasi.bp)/parameters.dt)*parameters.dt;
    parameters.end_time = ceil(max(pinhasi.bp)/parameters.dt)*parameters.dt + 5000; % add 5000 years to end_time
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

    % add terrain data
    parameters.terrain = csidata;
    parameters.terrain = parameters.terrain/max(parameters.terrain(:));

    % initialize A
    parameters.A = false(length(latp), length(lonp), parameters.T);
    [~, earliest_event] = min(parameters.dataset_idx(:,3));
    parameters.A(parameters.dataset_idx(earliest_event,1), parameters.dataset_idx(earliest_event,2), 1) = true;
end