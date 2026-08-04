%{
project: OOS
title: explore_trace
purpose: explore TraCE precipitation data
input: seshat.mat
output: 
author: ds
created: 2023.03.08

table of contents
1. x
%}

clear
clc

addpath ~/Dropbox/Documents/matlab

cd ~/Dropbox/Research/OOS/data


%% load trace

filename = 'original_data/trace/TraCE-21K-II.ann.PRECT.nc';

ncdisp(filename)

data = ncread(filename, 'PRECT');
tlat = ncread(filename, 'lat');
tlon = ncread(filename, 'lon');
time = ncread(filename, 'time');

data = pagetranspose(data);

for t = 1:length(time)
    data(:,:,t) = [data(:,tlon >= 180,t) data(:,tlon < 180,t)];
end

tlon = [tlon(tlon >= 180)-360; tlon(tlon < 180)];

%% maps by century

%
times = -22:.1:0; % century steps in millenia

cdata = nan(length(tlat), length(tlon), length(times));

for c = 1:length(times)-1
    cdata(:,:,c) = mean(data(:,:,time >= times(c) & time < times(c+1)),3);
end
%%

figure('Position', [200 50 1200 600])
tiledlayout('flow')

for c = 1:10:length(times)-1
    
    nexttile
    
    imagesc(tlon,tlat,cdata(:,:,c))
    geoshow('landareas.shp', 'FaceAlpha', 0, 'EdgeColor', 'black')
    axis xy
    title(num2str(times(c)))
end
%cdata = nan;
%}

%% load seshat

load('prepared_data/seshat.mat')


%% load Yan et al water resource zones (WRZ)

L = 2;
rl = km2deg(5); % density reduction of WRZ shapefile in km

regions = {'af', 'as', 'au', 'eu', 'na', 'sa'}';

yanwrz = [];

tic
for j = 1:length(regions)
    
    disp(['region: ' regions{j}])
    
    filename = ['original_data/yanetal/river and wrz/' ...
        'Global Water Resources Zones L1 to L4/' regions{j} '/' ...
        regions{j} '_wrz' num2str(L) '.shp'];
    
    shp = shaperead(filename, 'UseGeoCoords', true);
    
    for i = 1:length(shp)
        if length(shp(i).Lon) > 1e3
            [latr, lonr] = reducem(shp(i).Lat', shp(i).Lon', rl);
            [shp(i).Lat] = latr;
            [shp(i).Lon] = lonr;
        end
        [shp(i).region] = regions{j};
    end
    
    yanwrz = [yanwrz; shp];
end
toc


%% local area

rad = 50; % radius around NGA centroid in kilometers

idx = strcmp(ngatbl.name, 'Upper Egypt');

[blat, blon] = bufferm(ngatbl.clat(idx), ngatbl.clon(idx), km2deg(rad),...
    'out', 30); % 30 points to draw circle (smoother than default 13)

[X,Y] = meshgrid(tlon, tlat);

%% map
%{
ax = axesm ('robinson', 'Frame', 'on', 'Grid', 'on', 'FLineWidth', 1);
geoshow('landareas.shp', 'FaceColor', [.8 .8 .8], 'EdgeAlpha', 0)

geoshow(blat, blon, 'DisplayType', 'Polygon', 'FaceAlpha', .5)
%}

%% precipitation in local area

[local_mtx, R] = vec2mtx(blat, blon, 1/3.75, [min(tlat) max(tlat)], ...
    [min(tlon)-3.75/2 max(tlon)+3.75/2], 'filled');

local_mtx = local_mtx <= 1;

%% map
%{
ax = axesm ('robinson', 'Frame', 'on', 'Grid', 'on', 'FLineWidth', 1);
geoshow(local_mtx, R, 'DisplayType', 'TextureMap')

geoshow('landareas.shp', 'FaceAlpha', 0)
geoshow(blat, blon, 'DisplayType', 'Polygon', 'FaceAlpha', .5)
geoshow(Y(:), X(:), 'DisplayType', 'Point')
axis xy
%}


%% find WRZs of local area

% find region
i = 0;
in = false;
while in == false
    i = i + 1;
    bb = yanwrz(i).BoundingBox;
    in = inpolygon(ngatbl.clon(idx), ngatbl.clat(idx), ...
    [bb(1,1) bb(2,1) bb(2,1) bb(1,1) bb(1,1)], ...
    [bb(1,2) bb(1,2) bb(2,2) bb(2,2) bb(1,2)]);
end

idxregion = yanwrz(i).region;
%%
bpoly = polyshape(blon, blat);

wrzids = [];
for i = 1:length(yanwrz)
    if strcmp(yanwrz(i).region, idxregion)
        wrzpoly = polyshape(yanwrz(i).Lon, yanwrz(i).Lat);
        if overlaps(wrzpoly, bpoly)
            wrzids = [wrzids; yanwrz(i).ID];
        end
    end
end

%% find upstream WRZs

L1ids = unique(floor(wrzids/1e4));

uswrzpoly = polyshape;

for k = 1:length(L1ids)
    nextL1wrz = (L1ids(k)+1)*1e4;
    minwrz = min(wrzids(floor(wrzids/1e4) == L1ids(k)));
    upstream = [yanwrz.ID] >= minwrz & [yanwrz.ID] < nextL1wrz;

    uswrz = dissolve(yanwrz(upstream)); % upstream WRZ

    % remove holes
    uswrzpoly_k = rmholes(polyshape([uswrz.Lon], [uswrz.Lat]));
    uswrzpoly = rmholes(union(uswrzpoly, uswrzpoly_k));
end

[uswrz.Lat] = uswrzpoly.Vertices(:,2);
[uswrz.Lon] = uswrzpoly.Vertices(:,1);

%% create raster of upstream WRZ

[upstream_mtx, R] = vec2mtx([uswrz.Lat], [uswrz.Lon], 1/3.75, ...
    [min(tlat) max(tlat)], [min(tlon)-3.75/2 max(tlon)+3.75/2], 'filled');

% ensure no overlap with local TraCE cells
upstream_mtx = upstream_mtx <= 1 & ~local_mtx;

%% map

loc = 10;
fwidth = 20;
f = figure('Units','inches','Position',[loc loc fwidth fwidth/2.2], ...
    'PaperPosition',[.25 .25 8 6]);
    hold on;

worldmap(["Morocco", "Kenya"])



geoshow(upstream_mtx + 2*local_mtx, R, 'DisplayType', 'TextureMap')

geoshow('landareas.shp', 'FaceAlpha', 0)
geoshow(blat, blon, 'DisplayType', 'Polygon', 'FaceAlpha', .5)
geoshow([uswrz.Lat], [uswrz.Lon], 'DisplayType', 'Polygon', ...
    'FaceAlpha', .5)
geoshow(Y(:), X(:), 'DisplayType', 'Point')
axis xy


%% time series of precipitation in local and upstream area

tslocal = nan(length(time),1);
tsupstream = nan(length(time),1);

for t = 1:length(time)
    tdata = data(:,:,t);
    tslocal(t) = mean(tdata(local_mtx));
    tsupstream(t) = sum(tdata(upstream_mtx));
end

holo = time >= -12; % last twelve millenia

yyaxis left
hold on;
l1 = plot(time(holo)+2, tslocal(holo));
l1.Color = [l1.Color .3];
plot(time(holo)+2, tslocal(holo));

yyaxis right
l2 = plot(time(holo)+2, tsupstream(holo));
l2.Color = [l2.Color .3];
plot(time(holo)+2, tsupstream(holo));

