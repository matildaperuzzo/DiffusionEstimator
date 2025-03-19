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

%% Prepare Template Raster

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
time = 2000 + netcdf.getVar(ncid,3)*1000;

fn = 'data/raw/trace/TraCE-21K-II.ann.PRECT.nc';
ncid = netcdf.open(fn);
data = netcdf.getVar(ncid,1);
data = data(lon_indices,:,:);
[old_lon_grid, old_lat_grid] = meshgrid(data_lon, data_lat);
[new_lon_grid, new_lat_grid] = meshgrid(lon, lat);

interp_data = zeros(length(lat), length(lon), length(time));
for i = 1:length(time)
    dat = data(:,:,i)';
    interp_data(:,:,i) = (interp2(old_lon_grid, old_lat_grid, dat, new_lon_grid, new_lat_grid,'spline'));
end

interp_data_mean = mean(interp_data(:));
interp_data_std = std(interp_data(:));
interp_data = (interp_data-interp_data_mean)/interp_data_std;

trace = struct( ...
    'data', interp_data, ...
    'lat', lat, ...
    'lon', lon, ...
    'time', time);

save(filename, 'trace', '-append')

%% SAGE Potential Vegetation NetCDF Data

disp('SAGE Potential Vegetation NetCDF Data')

fn = 'data/raw/SAGE/glpotveg/potveg_nc/vegtype_5min.nc';
ncid = netcdf.open(fn);

data = netcdf.getVar(ncid,4);
data = data';
data = flipud(data);
data(data > 100) = 0;

% Actual delta of GAEZ data
delta_act = 1/12;

% Compute latitude and longitude limits
latlim = [min(lat), max(lat)];
lonlim = [min(lon), max(lon)];

% Use the limits in georefcells
R = georefcells(latlim, lonlim, size(data));

if delta ~= delta_act
    disp("Here");
    skip = int16(delta/delta_act);

    % data = data(1:skip:end, 1:skip:end);
end

pot_veg_data = {};
if delta ~= delta_act
    for i = 0:16
        dat = data == i;
        pot_veg_data{length(pot_veg_data)+1} = imresize(dat, [length(lat) length(lon)]);
    end
end

potveg = struct(...
    'lat', lat, ...
    'lon', lon, ...
    'data', data, ...
    'pot_veg_data', pot_veg_data, ...
    'source', 'SAGE Potential Vegetation NetCDF Data');

sea_layer = pot_veg_data{1};
save(filename, 'potveg', '-append')


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

%imagesc(lon, lat, flipud(landsuit.data))

save(filename, 'landsuit', '-append')


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

%% tmean

folder = 'data/raw/wc2.1_30s_tavg'; % Replace with your folder path

% Get a list of all .tif files in the folder
file_list = dir(fullfile(folder, '*.tif'));

% Check if there are any .tif files in the folder
if isempty(file_list)
    error('No .tif files found in the specified folder.');
end

% Initialize variables
num_files = length(file_list); % Number of .tif files
first_image = imread(fullfile(folder, file_list(1).name)); % Read the first image to get dimensions
image_sum = double(first_image); % Initialize the sum with the first image

% Loop through the remaining files and accumulate the sum
for i = 2:num_files
    % Read the current image
    current_image = imread(fullfile(folder, file_list(i).name));
    
    % Add the current image to the sum
    image_sum = image_sum + double(current_image);
end

% Compute the average image
average_image = image_sum / num_files;

% Convert the average image back to the original data type (e.g., uint8)
average_image = cast(average_image, class(first_image));
[size_image, ~] = size(average_image);
[target_size, ~] = size(latmtx);
delta = target_size/size_image;
image = average_image;
% remove sea data
image(average_image<-100) = NaN;
block_size = [1/delta, 1/delta]; 
resized_size = floor(size(image) ./ block_size);
% Initialize the resized image
resized_image = zeros(resized_size);
% in order to preserve coastline take meadian of each block rather than
% average
for i = 1:resized_size(1)
    for j = 1:resized_size(2)
        % Define the row and column indices for the current block
        row_range = (1:block_size(1)) + (i-1)*block_size(1);
        col_range = (1:block_size(2)) + (j-1)*block_size(2);
        
        % Extract the current block
        current_block = image(row_range, col_range);
        
        % Compute the median of the block and assign it to the resized image
        if length(current_block(isnan(current_block)))>length(current_block(~isnan(current_block)))
            value = NaN;
        else
            value = mean(current_block(~isnan(current_block)));
        end
        resized_image(i, j) = value;
    end
end

resized_image = flipud(resized_image);
resized_image(isnan(resized_image)) = 0;
ri_m = mean(resized_image(~sea_layer));
ri_s = std(resized_image(~sea_layer));
resized_image = (resized_image-ri_m)/ri_s;
resized_image(sea_layer) = 0;
tmean = struct('data', resized_image);

save(filename,'tmean','-append')


%% Slope and TRI (Nunn and Puga)

disp('Slope and TRI (Nunn and Puga)')

fn = '../OOS/data/original_data/Nunn_Puga';

tic

slope = dlmread(strcat(fn, '/slope.txt'), ' ', 6, 1);
tri = dlmread(strcat(fn, '/tri.txt'), ' ', 6, 1);


% Actual delta of GAEZ data
delta_act = 1/120;

if delta ~= delta_act
    slope = flipud(resizem(slope, [length(lat) length(lon)]));
    tri = flipud(resizem(tri, [length(lat) length(lon)]));
end

save('data/prep/geography.mat', 'slope', 'tri', '-append')

clearvars -except delta lat lon latmxt lonmtx

toc


%% GSHHS shoreline

disp('GSHHS')

tic

filename = 'original_data/GSHHG/gshhg-shp-2.2.2/GSHHS_shp/c/GSHHS_c_L1';

coast = shaperead(['../OOS/data/' filename]);

% merge structure elements to vectors of lon and lat coordinates
coastlonvec = [];
coastlatvec = [];

for i = 1:length(coast)
    coastlonvec = [coastlonvec coast(i).X];
    coastlatvec = [coastlatvec coast(i).Y];
end

[coastmtx, R] = vec2mtx(coastlatvec, coastlonvec, ...
    1/delta, [-90 90], [-180 180], 'filled');

coastmtx = coastmtx == 1;

coast = struct(...
    'lat', -lat, ...
    'lon', lon, ...
    'density', 1/delta, ...
    'data', coastmtx, ...
    'source', 'GSHHS shoreline data');

save('data/prep/geography.mat', 'coast', '-append')

clearvars -except delta lat lon latmxt lonmtx


disp('Building geography finished!')