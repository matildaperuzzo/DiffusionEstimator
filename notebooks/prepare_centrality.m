%{
project: BottleNecks
title: prepare centrality
purpose: create centrality measure from geography data
input: geography.mat
output: centrality.mat
author: DS
created: 2024-05-28

DESCRIPTION OF PROCESS

1. load geography data
2. calculate centrality
%}

clear
clc

cd '~/Dropbox/Research/BottleNecks'

disp('Prepare data ...')

%% Open geography data

clearvars -except delta

load('data/prep/geography.mat');

%% Calculate centrality
%
disp('Calculating centrality measures...')

tic

% select network weights

% using ruggedness travel cost (Naismith 1892)
naismith = 25/3; % each vertical km adds 25/3 time to each horizontal km
nw = (1 + naismith*tri/1e6)*deg2km(delta)*1e-3;

nw(tri == 0 | latmtx < - 62 | latmtx > 60) = 0;

% Naismith weights in in SDs
nw = nw./std(nw(:));

% inverse of crop suitability (CSI) in SDs
prod = csidata./std(csidata(:), 'omitmissing');

% construct graph
[G,gx,gy,origseq] = gridnetwork(nw,lat,lon);

% compute betweenness centrality
tic
wbc = centrality(G,'betweenness','Cost',G.Edges.Weight);
toc

wbcvec(origseq) = wbc;

wbcmtx = reshape(wbcvec,length(lat),length(lon));

% smooth betweenness
CW_wbcmtx = cwnanmean(wbcmtx,10,1);

% distance to percentile migration corridors
oslatmtx = latmtx(origseq);
oslonmtx = lonmtx(origseq);

wbcpctiles = [95 99];

wbcdist = nan(length(lat), length(lon), length(wbcpctiles));
for k = 1:length(wbcpctiles)
    platvec = oslatmtx(wbc > prctile(wbc, wbcpctiles(k)));
    plonvec = oslonmtx(wbc > prctile(wbc, wbcpctiles(k)));
    wbcdist(:,:,k) = reshape(pdist2([plonvec platvec], ...
        [lonmtx(:) latmtx(:)], 'euclidean', 'Smallest', 1)', ...
        length(lat), length(lon));
end
%%
save('data/prep/centrality.mat', ...
    'G', 'gx', 'gy', 'wbc', 'wbcmtx', 'CW_wbcmtx', ...
    'wbcdist')

disp('Calculating centrality finished!')
toc
%}
