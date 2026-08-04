function [x,y,t] = get_dataset(dataset)
    if strcmp(dataset,'pinhasi')
        % load pinhasi
        pinhasi = readtable( ...
            'data/raw/pinhasi/Neolithic_timing_Europe_PLOS.xls');
    
        pinhasi = pinhasi(pinhasi.Var1 == "SITE",:); %% keep only site rows
    %...'CALC14BP'},
        pinhasi = renamevars(pinhasi, {'Latitude', 'Longitude', 'CALC14BP'}, ...
            {'lat', 'lon', 'bp'});
    
        pinhasi = pinhasi(:,{'lat', 'lon', 'bp'});
        pinhasi.bp = 1950 - pinhasi.bp; % from BP to year
    
        x = pinhasi.lat;
        y = pinhasi.lon;
        t = pinhasi.bp;
    
    elseif strcmp(dataset,'desouza')
        desouza = readtable('data/raw/de_souza_wheat_data/dates.csv');
        x = desouza.Latitude;
        y = desouza.Longitude;
        t = 1950 - desouza.bp;

    elseif strcmp(dataset,'all_wheat')
        pinhasi = readtable( ...
            'data/raw/pinhasi/Neolithic_timing_Europe_PLOS.xls');
    
        pinhasi = pinhasi(pinhasi.Var1 == "SITE",:); %% keep only site rows
    
        pinhasi = renamevars(pinhasi, {'Latitude', 'Longitude', 'CALC14BP'}, ...
            {'lat', 'lon', 'bp'});
    
        pinhasi = pinhasi(:,{'lat', 'lon', 'bp'});
        pinhasi.bp = 1950 - pinhasi.bp; % from BP to year
    
        x = pinhasi.lat;
        y = pinhasi.lon;
        t = pinhasi.bp;
    
        desouza = readtable('data/raw/de_souza_wheat_data/dates.csv');
        
        x = [x; desouza.Latitude];
        y = [y; desouza.Longitude];
        t = [t; 1950 - desouza.bp];
    
    elseif strcmp(dataset,'cobo')
        % LOAD COBO et al
    
        cobo = readtable( ...
             'data/raw/cobo_etal/cobo_etal_data.xlsx');
    
        x = cobo.Latitude;
        y = cobo.Longitude;
        t = cobo.Est_DateMean_BC_AD_;

    elseif strcmp(dataset, "maize_simple")
        maize = readtable("data\raw\hart_maize\Maize Arrival Times and Locations in Ancient Civilizations - Table 1.csv");
        x = maize.Latitude;
        y = maize.Longitude;
        t = maize.YearOfArrival;
        

    elseif strcmp(dataset,'maize')

        maize = readtable("data/raw/hart_maize/MaizeDataset_cleaned.xlsx");
        x = maize.Latitude;
        y = maize.Longitude;
        t = maize.Year;

        new_maize_data = readtable("data/raw/hart_maize/p3k14c_2022.06.csv");
        taxa = new_maize_data.Taxa;
        maize_ind = [];
        for i=1:length(taxa)
            if contains(lower(taxa{i}), 'zea mays')
                maize_ind = [maize_ind; i]; % Store the index of matching taxa
            end
        end
        
        age = 1950 - new_maize_data.Age(maize_ind);
        lon = new_maize_data.Long(maize_ind);
        lat = new_maize_data.Lat(maize_ind);

        nan_ind = isnan(age) | isnan(lat) | isnan(lon);

        age = age(~nan_ind);
        lon = lon(~nan_ind);
        lat = lat(~nan_ind);
        
        % find set of unique lat,lon coordinates
        uniqueCoords = unique([lat, lon], 'rows'); % Find unique latitude and longitude pairs
        new_x = uniqueCoords(:, 1);
        new_y = uniqueCoords(:, 2);
        % find earliest t for each 

        % Find the earliest t for each unique coordinate
        earliestT = zeros(size(new_x));
        for j = 1:length(new_x)
            idx = find(lat == new_x(j) & lon == new_y(j));
            earliestT(j) = min(age(idx));
        end
        
        % Append the new data to the existing dataset
        x = [x; new_x];
        y = [y; new_y];
        t = [t; earliestT];
    

    else
        disp('dataset unknown')
    
    end
    

end