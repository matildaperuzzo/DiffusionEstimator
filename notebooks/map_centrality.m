%{
project: BottleNecks
title: map centrality
purpose: make a map of centrality
input: centrality.mat
output: 
author: DS
created: 2024-06-03

DESCRIPTION OF PROCESS

1. load centrality data
%}

clear
clc

cd '~/Dropbox/Research/BottleNecks'

%% load

load('data/prep/geography.mat');
load('data/prep/centrality.mat');
load('data/prep/seshat.mat');


%% map

loc = 10;
fwidth = 20;
f = figure('Units','inches','Position',[loc loc fwidth fwidth/2.2], ...
    'PaperPosition',[.25 .25 8 6]);

tiledlayout(f, 1, 1, 'padding', 'tight');
ax = nexttile;

axesm('MapProjection','robinson','MapLatLimit',[-60 90], ...
    'MapLonLimit', [-180 180]);

hold on;

% land areas background
land = shaperead('landareas.shp', 'UseGeoCoords', true);
geoshow(land, 'FaceColor', [0.8 0.8 0.8], 'EdgeAlpha', 0)

% centrality
idx = wbc > prctile(wbc, 95);
h1 = scatterm(gy(idx), gx(idx), 1, 'filled');

idx = wbc > prctile(wbc, 98);
h2 = scatterm(gy(idx), gx(idx), 2, 'filled');

idx = wbc > prctile(wbc, 99);
h3 = scatterm(gy(idx), gx(idx), 5, 'filled');

idx = wbc > prctile(wbc, 99.5);
h4 = scatterm(gy(idx), gx(idx), 10, 'filled');

% % Seshat
% ngatbl.earlystate
% for j = 1:height(ngatbl)
%     if ngatbl.state(j)
%         h3 = geoshow(ngatbl.blat{j}, ngatbl.blon{j}, ...
%             'DisplayType', 'Polygon', 'FaceColor', [0 0 1], ...
%             'FaceAlpha', .2);
%     else
%         h4 = geoshow(ngatbl.blat{j}, ngatbl.blon{j}, ...
%             'DisplayType', 'Polygon', 'FaceColor', [1 .5 0], ...
%             'FaceAlpha', .4);
%     end
% end

framem('FLineWidth', 1, 'MapLatLimit', [-60 90])
box off
axis off
axis tight
%%
exportgraphics(f, 'figures/map_centrality.pdf')
close all