%{
project: BottleNecks
title: build geography
purpose: assemble various geographic datasets
input: various from OOS
output: geography.mat
author: DS
created: 2024-05-28

DESCRIPTION OF PROCESS

1. prepare template raster
2. weights grid
3. SAGE potential vegetation
4. SAGE land suitability
5. HydroSHEDS river accumulation
6. Galor and Ozak CSI
7. Nunn and Puga slope and TRI
%}

clear
clc

delta = 1/2;

clearvars -except delta

disp('Build geography data ...')

filename = 'data/prep/geography_0p5deg.mat';

%% Prepare Template Rater

disp('Prepare template grid')

% latitude and longitude axes
lat = -90+delta/2:delta:90-delta/2;
lon = -180+delta/2:delta:180-delta/2;

% latitude and longitude grids

[lonmtx, latmtx] = meshgrid(lon, lat);

save(filename,'-v7.3');


%% Weights Grid

w = cos(lat/90);

W = repmat(w',1,length(lon));

save(filename, 'W', '-append');

clear w
%% Trace data

disp('Trace Data')

fn = 'data/raw/trace/TraCE-21K-II.ann.TS.nc';
ncid = netcdf.open(fn);
data_lat = netcdf.getVar(ncid,1);
data_lat(1) = lat(1);
data_lat(end) = lat(end);
data_lon = netcdf.getVar(ncid,2);
data_lon(data_lon>180) = data_lon(data_lon>180)-360;
data_lon(1) = lon(1);
data_lon(length(data_lon)/2) = lon(end);
[data_lon, lon_indices] = sort(data_lon);
time = 1950 + netcdf.getVar(ncid,3)*1000;
data_temp = netcdf.getVar(ncid,0);
data_temp = data_temp(lon_indices,:,:);

fn = 'data/raw/trace/TraCE-21K-II.ann.PRECT.nc';
ncid = netcdf.open(fn);
data_prec = netcdf.getVar(ncid,1);
data_prec = data_prec(lon_indices,:,:);
[old_lon_grid, old_lat_grid] = meshgrid(data_lon, data_lat);
[new_lon_grid, new_lat_grid] = meshgrid(lon, lat);

interp_data_temp = zeros(length(lat), length(lon), length(time));
interp_data_prec = zeros(length(lat), length(lon), length(time));
for i = 1:length(time)
    dat_t = data_temp(:,:,i)';
    dat_p = data_prec(:,:,i)';
    interp_data_temp(:,:,i) = (interp2(old_lon_grid, old_lat_grid, dat_t, new_lon_grid, new_lat_grid,'spline'));
    interp_data_prec(:,:,i) = (interp2(old_lon_grid, old_lat_grid, dat_p, new_lon_grid, new_lat_grid,'spline'));
end

interp_data_mean = mean(interp_data_temp(:));
interp_data_std = std(interp_data_temp(:));
interp_data_temp = (interp_data_temp-interp_data_mean)/interp_data_std;

interp_data_mean = mean(interp_data_prec(:));
interp_data_std = std(interp_data_prec(:));
interp_data_prec = (interp_data_prec-interp_data_mean)/interp_data_std;

trace = struct( ...
    'prec', interp_data_prec, ...
    'temp', interp_data_temp, ...
    'lat', lat, ...
    'lon', lon, ...
    'time', time);

save(filename, 'trace', '-append')

%% SAGE Land Suitability Data

disp('SAGE Suitability')

fn = 'data/raw/SAGE/land_suit/land_suit_0.50x0.50.nc';
ncid = netcdf.open(fn, 'WRITE');

data = netcdf.getVar(ncid,4);
data = data';
data = flipud(data);
sea_layer = data>100;
data(data > 100) = 0;

% Actual delta of SAGE data
delta_act = 1/2;

if delta ~= delta_act
    data = imresize(data, [length(lat) length(lon)]);
end

landsuit = struct(...
    'lat', lat, ...
    'lon', lon, ...
    'data', data, ...
    'source', 'SAGE Land Suitability NetCDF Data');
sea = struct('data', sea_layer);
%imagesc(lon, lat, flipud(landsuit.data))

save(filename, 'sea', '-append')


%% HydroSHEDS ACC (River Flow Accumulation Data)

disp('HydroSHEDS ACC')

filenames = {'af_acc_30s_bil/af_acc_30s', ...
    'as_acc_30s_bil/as_acc_30s', ...
    'au_acc_30s_bil/au_acc_30s', ...
    'ca_acc_30s_bil/ca_acc_30s', ...
    'eu_acc_30s_bil/eu_acc_30s', ...
    'na_acc_30s_bil/na_acc_30s', ...
    'sa_acc_30s_bil/sa_acc_30s'};
directory = 'data/raw/HydroSHEDS/ACC/';

acc = nan(length(lat),length(lon),length(filenames));

for f = 1:length(filenames)

    % prepare parameters for BIL file import
    fn = strcat(directory ,filenames{f}, '.bil');
    hdrfile = strcat(directory, filenames{f}, '.hdr');
    hdr = importdata(hdrfile, '\t');
    blwfile = strcat(directory, filenames{f}, '.blw');
    blw = importdata(blwfile);

    for k=1:length(hdr)
        hdr{k} = regexp(hdr{k},'\s+','split');
    end

    % import BIL file
    rowscols = [str2num(hdr{3}{2}) ...
        str2num(hdr{4}{2}) ...
        str2num(hdr{5}{2})]; % [NROWS NCOLS NBANDS]
    precision = strcat('int',hdr{6}{2}); % from NBITS and PIXEL TYPE = int
    offset = 0; % since the header is not included in this file
    interleave = 'bil'; % LAYOUT
    byteorder = 'ieee-le'; % BYTEORDER = I
    data = multibandread(fn, ...
        rowscols, precision, offset, interleave, byteorder);

    % Actual delta
    delta_act = 1/120;

    if delta ~= delta_act
        data = imresize(data, delta_act/delta, 'bilinear', delta/delta_act);
    end

    datasize = size(data);
    
    % Find location of data on global grid (acc)
    i = 1;
    xcoord = lon(1);
    while xcoord < blw(5)-blw(1)/2
        i = i+1;
        xcoord = lon(i);
    end
    x = i;

    i = 1;
    ycoord = lat(1);
    while ycoord < blw(6)-blw(1)/2
        i = i+1;
        ycoord = lat(i);
    end
    y = i;

    acc(y:-1:(y + 1 - datasize(1)),x:(x - 1 + datasize(2)),f) = data;
end

acc = max(acc,[],3);
acc(sea_layer) = 0;
acc(isnan(acc)) = 0;
acc_mean = mean(acc(~sea_layer));
acc_std = std(acc(~sea_layer));
acc = (acc-acc_mean)/acc_std;
acc(sea_layer) = 0;

acc = struct(...
    'lat', lat, ...
    'lon', lon, ...
    'data', acc, ...
    'source', 'HydroSHEDS 30s ACC (Riverflow Accumulation)');

save(filename, 'acc', '-append')


%% Pre-1500 Caloric Suitability Index (Galor and Özak 2016)

disp('Galor and Ozak CSI')

fn = 'data/raw/csi/pre1500OptCalories.tif';

data = imread(fn);

% Actual delta
delta_act = 1/12;

delta_rel = delta/delta_act;
csidata = zeros(round(delta_rel*length(lat)), round(delta_rel*length(lon)));
csidata(round(delta_rel*length(lat)-size(data,1)+1):end,:) = data;

if delta ~= delta_act
    csidata = imresize(csidata, [length(lat) length(lon)]);
end

csidata(csidata < 0) = 0;

csidata = flipud(csidata);

csidata_mean = mean(csidata(~sea_layer));
csidata_std = std(csidata(~sea_layer));
csidata = (csidata - csidata_mean)/csidata_std;
csidata(sea_layer) = 0;

save(filename, 'csidata', '-append')

%% Crop specific layers

disp("FAO layers")

folder = 'data/raw/individual_crops/';
file_prefix = {'ycHr0_','ycHg0_'};
wheat_files = {"brl",'fml','whe'};
rice_files = {"rcw"};
maize_files = {"mze"};

wheat_layer = zeros(length(lat), length(lon),length(wheat_files),2);
rice_layer = zeros(length(lat), length(lon),length(rice_files),2);
maize_layer = zeros(length(lat), length(lon),length(maize_files),2);

%
for k = 1:length(wheat_files)
    for i = 1:length(file_prefix)
        fn = strcat(folder, file_prefix{i}, wheat_files{k},'.tif');
        data = imread(fn);
        data = flipud(data);
        delta_act = 1/12;
        if delta ~= delta_act
            data = imresize(data, [length(lat) length(lon)]);
        end

        wheat_layer(:,:,k,i) = data;
    end
end

wheat_data = max(max(wheat_layer,[],4),[],3);
wheat_mean = mean(wheat_data(~sea_layer));
wheat_std = std(wheat_data(~sea_layer));
wheat_data = (wheat_data - wheat_mean)/wheat_std;
wheat_data(sea_layer) = 0;


for k = 1:length(rice_files)
    for i = 1:length(file_prefix)
        fn = strcat(folder, file_prefix{i}, rice_files{k},'.tif');
        data = imread(fn);
        data = flipud(data);
        delta_act = 1/12;
        if delta ~= delta_act
            data = imresize(data, [length(lat) length(lon)]);
        end

        rice_layer(:,:,k,i) = data;
    end
end

rice_data = max(max(rice_layer,[],4),[],3);
rice_mean = mean(rice_data(~sea_layer));
rice_std = std(rice_data(~sea_layer));
rice_data = (rice_data - wheat_mean)/wheat_std;
rice_data(sea_layer) = 0;


for k = 1:length(maize_files)
    for i = 1:length(file_prefix)
        fn = strcat(folder, file_prefix{i}, maize_files{k},'.tif');
        data = imread(fn);
        data = flipud(data);
        delta_act = 1/12;
        if delta ~= delta_act
            data = imresize(data, [length(lat) length(lon)]);
        end

        maize_layer(:,:,k,i) = data;
    end
end

maize_data = max(max(maize_layer,[],4),[],3);
maize_mean = mean(maize_data(~sea_layer));
maize_std = std(maize_data(~sea_layer));
maize_data = (maize_data - wheat_mean)/wheat_std;
maize_data(sea_layer) = 0;

crop_data = {};
crop_data{1} = struct('crop','wheat','data',wheat_data);
crop_data{2} = struct('crop','rice','data',rice_data);
crop_data{3} = struct('crop','maize','data',maize_data);

save(filename, 'crop_data', '-append')

disp('Building geography finished!')

