function [x,y,t] = get_dataset(dataset)
    if strcmp(dataset,'pinhasi')
        % load pinhasi
        pinhasi = readtable( ...
            'data/raw/pinhasi/Neolithic_timing_Europe_PLOS.xls');
    
        pinhasi = pinhasi(pinhasi.Var1 == "SITE",:); %% keep only site rows
    
        pinhasi = renamevars(pinhasi, {'Latitude', 'Longitude', 'CALC14BP'}, ...
            {'lat', 'lon', 'bp'});
    
        pinhasi = pinhasi(:,{'lat', 'lon', 'bp'});
        pinhasi.bp = 2000 - pinhasi.bp; % from BP to year
    
        x = pinhasi.lat;
        y = pinhasi.lon;
        t = pinhasi.bp;
    
    elseif strcmp(dataset,'desouza')
        desouza = readtable('data/raw/de_souza_wheat_data/dates.csv');
        x = desouza.Latitude;
        y = desouza.Longitude;
        t = 2000 - desouza.bp;

    elseif strcmp(dataset,'all_wheat')
        pinhasi = readtable( ...
            'data/raw/pinhasi/Neolithic_timing_Europe_PLOS.xls');
    
        pinhasi = pinhasi(pinhasi.Var1 == "SITE",:); %% keep only site rows
    
        pinhasi = renamevars(pinhasi, {'Latitude', 'Longitude', 'CALC14BP'}, ...
            {'lat', 'lon', 'bp'});
    
        pinhasi = pinhasi(:,{'lat', 'lon', 'bp'});
        pinhasi.bp = 2000 - pinhasi.bp; % from BP to year
    
        x = pinhasi.lat;
        y = pinhasi.lon;
        t = pinhasi.bp;
    
        desouza = readtable('data/raw/de_souza_wheat_data/dates.csv');
        
        x = [x; desouza.Latitude];
        y = [y; desouza.Longitude];
        t = [t; 2000 - desouza.bp];
    
    elseif strcmp(dataset,'cobo')
        % LOAD COBO et al
    
        cobo = readtable( ...
             'data/raw/cobo_etal/cobo_etal_data.xlsx');
    
        x = cobo.Latitude;
        y = cobo.Longitude;
        t = cobo.Est_DateMean_BC_AD_;
    else
        disp('dataset unknown')
    
    end
    

end