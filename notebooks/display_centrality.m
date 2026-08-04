%{
project: BottleNecks
title: display centrality
purpose: various figures of centrality and Seshat
input: centrality.mat
output: 
author: DS
created: 2024-06-23

DESCRIPTION OF PROCESS

1. load centrality data
%}

clear
clc

cd '~/Dropbox/Research/BottleNecks'

addpath ~/Dropbox/Documents/matlab

%% load

load('data/prep/geography.mat');
load('data/prep/centrality.mat');
load('data/prep/seshat.mat');


%% map of Seshat complexity

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

for j = 1:height(ngatbl)
    if ngatbl.complex(j) == "Early"
        h1 = geoshow(ngatbl.blat{j}, ngatbl.blon{j}, ...
            'DisplayType', 'Polygon', 'FaceColor', [0 0 1], ...
            'FaceAlpha', .2);
    elseif ngatbl.complex(j) == "Middle"
        h2 = geoshow(ngatbl.blat{j}, ngatbl.blon{j}, ...
            'DisplayType', 'Polygon', 'FaceColor', [1 .5 0], ...
            'FaceAlpha', .4);
    elseif ngatbl.complex(j) == "Late"
        h3 = geoshow(ngatbl.blat{j}, ngatbl.blon{j}, ...
            'DisplayType', 'Polygon', 'FaceColor', [0 1 .5], ...
            'FaceAlpha', .4);
    end
end

[l,lgd] = legend(ax,[h1 h2 h3], 'Early Complexity', ...
    'Middle Complexity', ...
    'Late Complexity', ...
    'FontSize', 14);

legend boxoff
l.Position = [.1 .13 .14 .16];


% ensure PDF print preserves size of figure
f.Units = 'centimeters';
f.PaperUnits = 'centimeters';
f.PaperSize = f.Position(3:4);

framem('FLineWidth', 1, 'MapLatLimit', [-60 90])
box off
axis off
axis tight


exportgraphics(f, 'figures/map_complexity.pdf')
close all


%% map of Naismith weights

% prepare Naismith weights without restriction to [-60,+60] lat
naismith = 25/3; % each vertical km adds 25/3 time to each horizontal km
nw = (1 + naismith*tri/1e6)*deg2km(delta)*1e-3;

% make map
loc = 10;
fwidth = 20;
f = figure('Units','inches','Position',[loc loc fwidth fwidth/2.2], ...
    'PaperPosition',[.25 .25 8 6]);

tiledlayout(f, 1, 1, 'padding', 'tight');
ax = nexttile;

axesm('MapProjection','robinson','MapLatLimit',[-60 90], ...
    'MapLonLimit', [-180 180]);

hold on;

% Naismith weights display
R = [1/delta max(lat) min(lon)];
geoshow(nw, R, 'DisplayType', 'TextureMap')

% coast outline
geoshow('landareas.shp', ...
    'FaceAlpha', 0, 'EdgeColor', 'black')

colormap('autumn')
cmap = colormap(flipud(colormap));
cmap = [1 1 1; cmap];
colormap(cmap)

c = colorbar;
c.FontSize = 12;
c.Label.String = 'Traversal cost';
c.Label.FontSize = 16;
c.Position = [.12 .03 .01 .2];


% ensure PDF print preserves size of figure
f.Units = 'centimeters';
f.PaperUnits = 'centimeters';
f.PaperSize = f.Position(3:4);

framem('FLineWidth', 1, 'MapLatLimit', [-60 90])
box off
axis off
axis tight

exportgraphics(f, 'figures/map_naismith.pdf')
close all


%% boxplot of centrality by Seshat complexity

loc = 8;
fwidth = 8;
f = figure('Units','inches','Position',[loc loc fwidth fwidth/2.2], ...
    'PaperPosition',[.25 .25 8 6]);

tiledlayout(f, 1, 2, 'TileSpacing', 'tight', 'Padding', 'Tight')

% centrality
nexttile

b = boxplot(ngatbl.wbcmtx, ngatbl.complex, 'GroupOrder', ...
    {'Early', 'Middle', 'Late'});
ylabel('Centrality')
xlabel('Complexity')

box off
set(gcf, 'Color', 'w')
set(gca,'FontSize', 12,'LooseInset',get(gca,'TightInset'))


% distance to centrality
nexttile

boxplot(ngatbl.wbcdist, ngatbl.complex, 'GroupOrder', ...
    {'Early', 'Middle', 'Late'})
ylabel('Distance to high centrality')
xlabel('Complexity')

box off
set(gcf, 'Color', 'w')
set(gca,'FontSize', 12,'LooseInset',get(gca,'TightInset'))

exportgraphics(f, 'figures/boxplot_centrality_complex.pdf', ...
    'Resolution',300)
close all


%% scatter plot of earliest polity and distance to migratory route

for j = 1:height(ngatbl)
    
    % find earliest polity with hierarchy >= 3 in each NGA
    pnga = polity(strcmp(polity.NGA, ngatbl.name(j)),:);
    
    idx = pnga.hierarchy >= 3;
    if any(idx)
        ngatbl.earliestpolity(j) = min(pnga.yearstart(idx));
    end
end

p = polyfit(ngatbl.wbcdist, ngatbl.earliestpolity, 2);
x = linspace(0, 60);
y = polyval(p, x);

loc = 8;
fwidth = 8;
f = figure('Units','inches','Position',[loc loc fwidth fwidth/2.2], ...
    'PaperPosition',[.25 .25 8 6]);

tiledlayout(f, 1, 1, 'TileSpacing', 'tight', 'Padding', 'Tight')

% highlight some NGAs
ngahl = {'Southern Mesopotamia', 'Sogdiana', 'Garo Hills', ...
    'Kachi Plain', 'Middle Yellow River Valley', 'Finger Lakes', ...
    'Chuuk Islands'};
idx = ismember(ngatbl.name, ngahl);
%idx = true(height(ngatbl),1);

hold on;
plot(x, y, 'Color', 'b')

scatter(ngatbl.wbcdist, ngatbl.earliestpolity, 'filled', ...
    'MarkerFaceAlpha', .5, 'MarkerEdgeColor', 'blue')

text(ngatbl.wbcdist(idx)+.5, ngatbl.earliestpolity(idx)+100, ...
    ngatbl.name(idx), 'HorizontalAlignment', 'left')

xlabel('Distance to high centrality')
ylabel('First appearance of high hierarchy')

box off
set(gcf, 'Color', 'w')
set(gca,'FontSize', 12,'LooseInset',get(gca,'TightInset'))

exportgraphics(f, ...
    'figures/scatter_centralitydist_earliesthierarchy.pdf', ...
    'Resolution',300)
close all


%% scatter plot of earliest polity and distance to migratory route

for j = 1:height(ngatbl)
    
    % find earliest polity with hierarchy >= 3 in each NGA
    pnga = polity(strcmp(polity.NGA, ngatbl.name(j)),:);
    
    idx = pnga.bureaucrats | pnga.govbuildings;
    if any(idx)
        ngatbl.earliestpolity(j) = min(pnga.yearstart(idx));
    end
end

p = polyfit(ngatbl.wbcdist, ngatbl.earliestpolity, 2);
x = linspace(0, 60);
y = polyval(p, x);

loc = 8;
fwidth = 8;
f = figure('Units','inches','Position',[loc loc fwidth fwidth/2.2], ...
    'PaperPosition',[.25 .25 8 6]);

tiledlayout(f, 1, 1, 'TileSpacing', 'tight', 'Padding', 'Tight')

% highlight some NGAs
ngahl = {'Southern Mesopotamia', 'Sogdiana', 'Garo Hills', ...
    'Kachi Plain', 'Middle Yellow River Valley', 'Finger Lakes', ...
    'Chuuk Islands'};
idx = ismember(ngatbl.name, ngahl);
%idx = true(height(ngatbl),1);

hold on;
plot(x, y, 'Color', 'b')

scatter(ngatbl.wbcdist, ngatbl.earliestpolity, 'filled', ...
    'MarkerFaceAlpha', .5, 'MarkerEdgeColor', 'blue')

text(ngatbl.wbcdist(idx)+.5, ngatbl.earliestpolity(idx)+100, ...
    ngatbl.name(idx), 'HorizontalAlignment', 'left')

xlabel('Distance to high centrality')
ylabel('First appearance of high hierarchy')

box off
set(gcf, 'Color', 'w')
set(gca,'FontSize', 12,'LooseInset',get(gca,'TightInset'))

exportgraphics(f, ...
    'figures/scatter_centralitydist_earlystates.pdf', ...
    'Resolution',300)
close all


%% reg table

mdl = fitlm(ngatbl, 'state ~ wbcdist');