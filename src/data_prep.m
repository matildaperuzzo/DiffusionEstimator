function parameters = data_prep(n_averages, active_layers, lats, lons, years)

    parameters = struct();
    % load build
    load('data/prep/geography_0p5deg.mat',"lat","lon","W");

    parameters.dataset_lat = lats;
    parameters.dataset_lon = lons;
    parameters.dataset_bp = years;

    % restrict to Europe/Iran range
    padding = 5;
    topleft = [max(lats), min(lons)] + [padding -padding];
    bottomright = [min(lats), max(lons)] + [-padding padding];
    % topleft = [60, -17.19];
    % bottomright = [15, 65.07];

    latidx = lat <= topleft(1) & lat >= bottomright(1);
    lonidx = lon >= topleft(2) & lon <= bottomright(2);

    latp = lat(latidx);
    lonp = lon(lonidx);
    parameters.lat = [latp(1) latp(end)];
    parameters.lon = [lonp(1) lonp(end)];

    % define time array
    parameters.dt = 40; % time step in years
    parameters.start_time = floor(min(years)/parameters.dt)*parameters.dt;
    parameters.end_time = ceil(max(years)/parameters.dt)*parameters.dt + 1000; % add 1000 years to end_time
    parameters.T = round((parameters.end_time - parameters.start_time)/parameters.dt + 1);

    parameters.times = parameters.start_time:parameters.dt:parameters.end_time;

    % create matrix storing x,y,t indices coordinates of pinhasi sites
    parameters.dataset_idx = zeros(length(lats),3);
    for event_index = 1:length(lats)
        lat_event = lats(event_index);
        lon_event = lons(event_index);
        [~, index_x] = min(abs(latp - lat_event));
        [~, index_y] = min(abs(lonp - lon_event));
 
        [~, index_t] = min(abs(parameters.times - years(event_index)));
        parameters.dataset_idx(event_index,:) = [index_x, index_y, index_t];
    end

    % create the X vector
    X = {};
    % csi layer
    if length(active_layers)>=3
        if active_layers(3)
            load('data/prep/geography_0p5deg.mat',"csidata");
            % add csi data
            csidata = csidata(latidx,lonidx);
            X{length(X)+1} = csidata;
            clear csidata
        end
    end

    % river layer
    if length(active_layers)>=4
        if active_layers(4)
            load('data/prep/geography_0p5deg.mat',"acc");
            hydro = acc.data;
            clear acc
            hydro = hydro(latidx,lonidx);
            X{length(X)+1} = hydro;
            clear hydro
        end
    end
    % mean precipitation
    if length(active_layers)>=5
        if active_layers(5)
            load('data/prep/geography_0p5deg.mat',"trace");
            trace_dat = trace.prec;
            time_mask = (trace.time >= parameters.start_time) & (trace.time <= parameters.end_time);
            clear trace
            selected_data = trace_dat(:, :, time_mask);
            trace_dat = mean(selected_data,3);
            trace_dat = trace_dat(latidx,lonidx);
            X{length(X)+1} = trace_dat;
            clear trace_dat
        end
    end

    % mean surface temperature
    if length(active_layers)>=6
        if active_layers(6)
            load('data/prep/geography_0p5deg.mat',"trace");
            trace_dat = trace.temp;
            time_mask = (trace.time >= parameters.start_time) & (trace.time <= parameters.end_time);
            clear trace
            selected_data = trace_dat(:, :, time_mask);
            trace_dat = mean(selected_data,3);
            trace_dat = trace_dat(latidx,lonidx);
            X{length(X)+1} = trace_dat;
            clear trace_dat
        end
    end

    if length(active_layers)>=7
        if active_layers(7)
            load('data/prep/geography_0p5deg.mat',"sea");
            data = sea.data;
            data = data(latidx,lonidx);
            X{length(X)+1} = data;
            clear sea
            clear data
        end
    end

    if length(active_layers)>=8
        if active_layers(8)
            load('data/prep/geography_0p5deg.mat',"crop_data");
            data = crop_data{1}.data;
            data = data(latidx,lonidx);
            X{length(X)+1} = data;
        end
    end
    
    if length(active_layers)>=9
        if active_layers(9)
            load('data/prep/geography_0p5deg.mat',"crop_data");
            data = crop_data{2}.data;
            data = data(latidx,lonidx);
            X{length(X)+1} = data;
        end
    end

    if length(active_layers)>=10
        if active_layers(10)
            load('data/prep/geography_0p5deg.mat',"crop_data");
            data = crop_data{3}.data;
            data = data(latidx,lonidx);
            X{length(X)+1} = data;
        end
    end

    parameters.X = X;

    % initialize A
    parameters.A = false(length(latp), length(lonp), parameters.T);
    [~, earliest_event] = min(parameters.dataset_idx(:,3));
    parameters.A(parameters.dataset_idx(earliest_event,1), parameters.dataset_idx(earliest_event,2), 1) = true;
    % add second start point
   
    % set a seed and define matrix of random numbers

    % parameters.U = rand([size(parameters.A) n_averages]);
    parameters.n = n_averages;
    W = W(latidx,lonidx);
    parameters.W = W/max(W(:));
    parameters.active_layers = active_layers;
    

end