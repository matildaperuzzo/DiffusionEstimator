%{
project: BottleNecks
title: explore dispersion
purpose: explore Pinhasi and Cobo crop dispersion data
input: centrality.mat
output: 
author: DS
created: 2024-06-23

DESCRIPTION OF PROCESS

1. load data
2. make maps
3. show speed of dispersion
%}

clear
clc

cd '~/Dropbox/Research/BottleNecks'

%% load data

% load pinhasi

pinhasi = readtable( ...
    'data/raw/pinhasi/Neolithic_timing_Europe_PLOS.xls');

pinhasi = pinhasi(pinhasi.Var1 == "SITE",:); %% keep only site rows

pinhasi = renamevars(pinhasi, {'Latitude', 'Longitude', 'CALC14BP'}, ...
    {'lat', 'lon', 'bp'});

pinhasi = pinhasi(:,{'lat', 'lon', 'bp'});

pinhasi.bp = 1950 - pinhasi.bp; % from BP to year


% load cobo

cobo = readtable( ...
    'data/raw/cobo_etal/cobo_etal_data.xlsx');

cobo = renamevars(cobo, ...
    {'Latitude', 'Longitude', 'Est_DateMean_BC_AD_'}, ...
    {'lat', 'lon', 'bp'});

cobo = cobo(:,{'lat', 'lon', 'bp'});


%% make maps

%% Pinhasi et al

loc = 10;
fwidth = 20;
f = figure('Units','inches','Position',[loc loc fwidth fwidth/2.2], ...
    'PaperPosition',[.25 .25 8 6]);

tiledlayout(f, 1, 1, 'padding', 'tight');
ax = nexttile;

worldmap(["Ireland", "Iran"])

geoshow('landareas.shp','FaceColor',[.9 .9 .9], 'EdgeAlpha', 0)

s = scatterm(pinhasi.lat, pinhasi.lon, 10, pinhasi.bp, 'filled');
s.Children.MarkerEdgeColor = [.4 .4 .4];
s.Children.MarkerFaceAlpha = .7;
s.Children.MarkerEdgeAlpha = .4;

box off
set(gcf, 'Color', 'w')

framem('FLineWidth', 1, 'FontSize', 7)

colormap('jet')
c = colorbar('North');
c.Label.String = 'Year of Neolithic Transition';
c.FontSize = 14;
c.Position = [0.23 0.13 0.25 0.03];
c.Label.Position(2) = 2.3;

% ensure PDF print preserves size of figure
f.Units = 'centimeters';
f.PaperUnits = 'centimeters';
f.PaperSize = f.Position(3:4);

box off
axis off
axis tight
%%
exportgraphics(f, 'figures/map_pinhasi.pdf')
close all


%% Cobo et al

loc = 10;
fwidth = 20;
f = figure('Units','inches','Position',[loc loc fwidth fwidth/2.2], ...
    'PaperPosition',[.25 .25 8 6]);

tiledlayout(f, 1, 1, 'padding', 'tight');
ax = nexttile;

worldmap(["India", "Japan"])

geoshow('landareas.shp','FaceColor',[.9 .9 .9], 'EdgeAlpha', 0)

s = scatterm(cobo.lat, cobo.lon, 10, cobo.bp, 'filled');
s.Children.MarkerEdgeColor = [.4 .4 .4];
s.Children.MarkerFaceAlpha = .7;
s.Children.MarkerEdgeAlpha = .4;

box off
set(gcf, 'Color', 'w')

framem('FLineWidth', 1, 'FontSize', 7)

colormap('jet')
c = colorbar('North');
c.Label.String = 'Year of Neolithic Transition';
c.FontSize = 14;
c.Position = [0.23 0.76 0.25 0.03];
c.Label.Position(2) = 2.3;

% ensure PDF print preserves size of figure
f.Units = 'centimeters';
f.PaperUnits = 'centimeters';
f.PaperSize = f.Position(3:4);

box off
axis off
axis tight
%%
exportgraphics(f, 'figures/map_cobo.pdf')
close all


%% dispersion graphs

loc = 5;
fwidth = 10;
f = figure('Units','inches','Position',[loc loc fwidth fwidth/2.2], ...
    'PaperPosition',[.25 .25 8 6]);

tiledlayout(f, 1, 2, 'padding', 'tight');

% pinhasi
nexttile 

idx = find(pinhasi.bp == min(pinhasi.bp));

pinhasi.dist = deg2km(distance(pinhasi.lat, pinhasi.lon, ...
    pinhasi.lat(idx), pinhasi.lon(idx)));

mdl = fitlm(pinhasi, 'bp ~ dist');

speed = round(mdl.Coefficients.Estimate(mdl.CoefficientNames == "dist"),2);

scatter(pinhasi.dist, pinhasi.bp, 5, [.8 .8 .8], 'filled')
%b = bscatter(pinhasi.dist, pinhasi.bp, 20);
%b.MarkerFaceColor = [0 .5 0];
lsline

text(200, -3200, [num2str(abs(speed)) 'km per year'])

xlabel('Distance from earliest Neolithic site in km')
ylabel('Years BP')

ylim([-9000 -3000])

% cobo
nexttile

idx = find(cobo.bp == min(cobo.bp));

cobo.dist = deg2km(distance(cobo.lat, cobo.lon, ...
    cobo.lat(idx), cobo.lon(idx)));

mdl = fitlm(cobo, 'bp ~ dist');

speed = round(mdl.Coefficients.Estimate(mdl.CoefficientNames == "dist"),2);

scatter(cobo.dist, cobo.bp, 5, [.8 .8 .8], 'filled')
%b = bscatter(pinhasi.dist, cobo.bp, 20);
%b.MarkerFaceColor = [0 .5 0];
lsline

text(200, 1400, [num2str(abs(speed)) 'km per year'])

xlabel('Distance from earliest Neolithic site in km')
ylabel('Years BP')

ylim([-5000 1500])

% ensure PDF print preserves size of figure
f.Units = 'centimeters';
f.PaperUnits = 'centimeters';
f.PaperSize = f.Position(3:4);

exportgraphics(f, 'figures/scatter_dispersions.pdf')
close all