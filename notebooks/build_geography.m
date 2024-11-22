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

save(filename);


%% Weights Grid

w = cos(lat/90);

W = repmat(w',1,length(lon));

save([pwd '/data/prep/geography.mat'], 'W', '-append');

clear w


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

save(filename, 'potveg', '-append')


%% SAGE Land Suitability Data

disp('SAGE Suitability')

fn = 'data/raw/SAGE/land_suit/land_suit_0.50x0.50.nc';
ncid = netcdf.open(fn, 'WRITE');

data = netcdf.getVar(ncid,4);
data = data';
data = flipud(data);

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

acc = struct(...
    'lat', lat, ...
    'lon', lon, ...
    'data', acc, ...
    'source', 'HydroSHEDS 30s ACC (Riverflow Accumulation)');

save(filename', 'acc', '-append')


%% Pre-1500 Caloric Suitability Index (Galor and Özak 2016)

disp('Galor and Ozak CSI')

fn = 'data/raw/csi/pre1500OptCalories.tif';

data = imread(fn);

% Actual delta
delta_act = 1/12;

delta_rel = delta/delta_act;
csidata = nan(round(delta_rel*length(lat)), round(delta_rel*length(lon)));
csidata(round(delta_rel*length(lat)-size(data,1)+1):end,:) = data;

if delta ~= delta_act
    csidata = imresize(csidata, [length(lat) length(lon)]);
end

csidata(csidata == -9) = 0;

csidata = flipud(csidata);

save(filename, 'csidata', '-append')


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