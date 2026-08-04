%{
project: OOS
title: build_seshat
purpose: build SESHAT
input: seshat-20200518.csv, Combined_30_NGAs.shp, Beyond_WS30.shp, ...
       oos_data_c4.mat
output: 
author: ds
created: 2020.08.21

table of contents
1. load and prepare seshat shapefiles
2. load and prepare circumscription cell files
3. load and prepare seshat data
4. add agriculture dataset
5. assign polities across NGAs using SocialComplexity replication
6. build balanced panel

%}

clear
clc

addpath ~/Dropbox/Documents/matlab

cd ~/Dropbox/Research/BottleNecks

oosdata = '../OOS/data/original_data/seshat/';

srad = 278; % Seshat radius for computations
brad = 278; % radius in km for visualization and minimum distance b/w GAs
minsites = 5; % minimal number of sites to form additional GA

%% 1. load and prepare seshat shapefiles

% prepare World Sample 30
nga = shaperead([oosdata 'NGA_combined/NGA30_noZ.shp'], ...
    'UseGeoCoords', true);

nga = keepfield(nga, ...
    {'Geometry', 'BoundingBox', 'Lat', 'Lon', 'Id', 'Name'});

nga = renamefield(nga, {'Id', 'Name'}, {'id', 'name'});

% world region
nga(strcmp({nga.name}, 'Ghanaian Coast')).regions = 'Africa';
nga(strcmp({nga.name}, 'Niger Inland Delta')).regions = 'Africa';
nga(strcmp({nga.name}, 'Upper Egypt')).regions = 'Africa';
nga(strcmp({nga.name}, 'Iceland')).regions = 'Europe';
nga(strcmp({nga.name}, 'Paris')).regions = 'Europe';
nga(strcmp({nga.name}, 'Latium')).regions = 'Europe';
nga(strcmp({nga.name}, 'Lena Valley')).regions = 'Central Eurasia';
nga(strcmp({nga.name}, 'Orkhon Valley')).regions = 'Central Eurasia';
nga(strcmp({nga.name}, 'Sogdiana')).regions = 'Central Eurasia';
nga(strcmp({nga.name}, 'Yemen')).regions = 'Southwest Asia';
nga(strcmp({nga.name}, 'Konya')).regions = 'Southwest Asia';
nga(strcmp({nga.name}, 'Susiana')).regions = 'Southwest Asia';
nga(strcmp({nga.name}, 'Garo Hills')).regions = 'South Asia';
nga(strcmp({nga.name}, 'Deccan')).regions = 'South Asia';
nga(strcmp({nga.name}, 'Kachi')).regions = 'South Asia';
nga(strcmp({nga.name}, 'Kapusai Basin')).regions = 'Southeast Asia';
nga(strcmp({nga.name}, 'Central Java')).regions = 'Southeast Asia';
nga(strcmp({nga.name}, 'Cambodia')).regions = 'Southeast Asia';
nga(strcmp({nga.name}, 'Southern China Hills')).regions = 'East Asia';
nga(strcmp({nga.name}, 'Kansai')).regions = 'East Asia';
nga(strcmp({nga.name}, 'MYRV')).regions ='East Asia';
nga(strcmp({nga.name}, 'Finger Lakes')).regions = 'North America';
nga(strcmp({nga.name}, 'Cahokia')).regions = 'North America';
nga(strcmp({nga.name}, 'Oaxaca')).regions = 'North America';
nga(strcmp({nga.name}, 'Lowland Andes')).regions = 'South America';
nga(strcmp({nga.name}, 'Colombia')).regions = 'South America';
nga(strcmp({nga.name}, 'Cuzco')).regions = 'South America';
nga(strcmp({nga.name}, 'Oro')).regions = 'Oceania-Australia';
nga(strcmp({nga.name}, 'Chuuk')).regions = 'Oceania-Australia';
nga(strcmp({nga.name}, 'Big Island Hawaii')).regions = 'Oceania-Australia';

% prepare Beyond the World Sample 30
bnga = shaperead([oosdata 'Beyond_WS30/Beyond_WS30.shp'], ...
    'UseGeoCoords', true);

bnga = renamefield(bnga, {'NGA'}, {'name'});

temp = num2cell([bnga.id] + 30);
[bnga.id] = temp{:};

bnga(strcmp({bnga.name}, 'Southern Mesopotamia')).regions = ...
    'Southwest Asia';
bnga(strcmp({bnga.name}, 'Galilee')).regions = 'Southwest Asia';
bnga(strcmp({bnga.name}, 'Crete')).regions = 'Europe';
bnga(strcmp({bnga.name}, 'Middle Ganga')).regions = 'South Asia';
bnga(strcmp({bnga.name}, 'Basin of Mexico')).regions = 'North America';

bnga = table2struct(sortrows(struct2table(bnga), 'id'));

% combine
nga = [nga; bnga];

% when did the NGA reach complexity?

% late
ngagroup = {'Ghanaian Coast', 'Iceland', 'Lena Valley', 'Yemen', ...
    'Garo Hills', 'Kapusai Basin', 'Southern China Hills', ...
    'Finger Lakes', 'Lowland Andes', 'Oro'};

[nga(ismember({nga.name}, ngagroup)).complex] = deal('Late');

% middle
ngagroup = {'Niger Inland Delta', 'Paris', 'Orkhon Valley', 'Konya', ...
    'Deccan', 'Central Java', 'Kansai', 'Cahokia', 'Colombia', ...
    'Chuuk', 'Middle Ganga'};

[nga(ismember({nga.name}, ngagroup)).complex] = deal('Middle');

% early
ngagroup = {'Upper Egypt', 'Latium', 'Sogdiana', 'Susiana', 'Kachi', ...
    'Cambodia', 'MYRV', 'Oaxaca', 'Cuzco', 'Big Island Hawaii', ...
    'Southern Mesopotamia', 'Galilee', 'Crete', 'Basin of Mexico'};

[nga(ismember({nga.name}, ngagroup)).complex] = deal('Early');

% rename NGAs to match table data

nga(strcmp({nga.name}, 'Yemen')).name = 'Yemeni Coastal Plain';
nga(strcmp({nga.name}, 'Paris')).name = 'Paris Basin';
nga(strcmp({nga.name}, 'Oro')).name = 'Oro PNG';
nga(strcmp({nga.name}, 'Kachi')).name = 'Kachi Plain';
nga(strcmp({nga.name}, 'MYRV')).name = 'Middle Yellow River Valley';
nga(strcmp({nga.name}, 'Lena Valley')).name = 'Lena River Valley';
nga(strcmp({nga.name}, 'Konya')).name = 'Konya Plain';
nga(strcmp({nga.name}, 'Kapusai Basin')).name = 'Kapuasi Basin';
nga(strcmp({nga.name}, 'Colombia')).name = 'North Colombia';
nga(strcmp({nga.name}, 'Chuuk')).name = 'Chuuk Islands';
nga(strcmp({nga.name}, 'Cambodia')).name = 'Cambodian Basin';
nga(strcmp({nga.name}, 'Oaxaca')).name = 'Valley of Oaxaca';

% early state formation NGAs

stateNGAs = {'Basin of Mexico', 'Valley of Oaxaca', ...
    'Cuzco', 'Upper Egypt', 'Southern Mesopotamia', 'Susiana', ...
    'Kachi Plain', 'Middle Yellow River Valley'};

earlystate = num2cell(ismember({nga.name}, stateNGAs)');
[nga.earlystate] = earlystate{:};

% load separate dataset of Seshat centroids

centers = readtable([oosdata 'seshat_centers.xlsx']);

nga = table2struct(join(struct2table(nga), ...
    centers(:,{'id', 'clat', 'clon'})));

% buffer Seshat NGA centroids
for j = 1:length(nga)
    [nga(j).blat, nga(j).blon] = ...
        bufferm([nga(j).clat], [nga(j).clon], km2deg(brad), 'out', 20);
    
    [nga(j).slat, nga(j).slon] = ...
        bufferm([nga(j).clat], [nga(j).clon], km2deg(srad), 'out', 20);
end


%% 2. find raster averages for NGAs

load('data/prep/geography.mat');
load('data/prep/centrality.mat');

n = length(nga);

% prepare some variables
abslat = abs(latmtx);
acc = acc.data;
forest = potveg.data > 0 & potveg.data <= 8;
grassland = potveg.data > 8 & potveg.data <= 12;
tundra = potveg.data == 12;
desert = potveg.data > 12;

varnames = {'abslat', 'slope', 'tri', 'acc', 'forest', 'grassland', ...
    'tundra', 'desert', 'wbcmtx', 'wbcdist'};

vars = {abslat, slope, tri, acc, forest, grassland, tundra, desert, ...
    CW_wbcmtx, wbcdist(:,:,2)}';

for i = 1:n

    [mask, ~] = vec2mtx(nga(i).slat, nga(i).slon, ...
        4, [-90 90], [-180 180], 'filled');
    mask = mask <= 1;

    for k = 1:length(varnames)
        nga(i).(varnames{k}) = nanmean(vars{k}(mask));
    end
end


ngatbl = struct2table(nga);
ngatbl = removevars(ngatbl, {'Lat', 'Lon'});


%% 3. load and prepare seshat data

seshat = readtable('data/raw/seshat/Equinox2020.05.2023.xlsx');

shortname = unique(seshat.Polity);

polity = table(shortname);

genvars = {'Original name', 'Duration', 'Degree of centralization', ...
    'relationship to preceding (quasi)polity'};
genvarlbls = {'name', 'duration', 'centralization', 'preceding'};

socvars = {'Polity territory', 'Polity Population', ...
    'Population of the largest settlement', 'Settlement hierarchy', ...
    'Administrative levels', 'Professional military officers', ...
    'Professional soldiers', 'Professional priesthood', ...
    'Full-time bureaucrats', 'Examination system', 'Merit promotion', ...
    'Specialized government buildings', 'Formal legal code', ...
    'Judges', 'Courts', 'Professional Lawyers', 'irrigation systems', ...
    'drinking water supply systems', 'markets', 'food storage sites', ...
    'Roads', 'Bridges', 'Ports', 'Non-phonetic writing', ...
    'Phonetic alphabetic writing', 'Tokens', 'Precious metals'};
socvarlbls = {'territory', 'population', 'popcapital', 'hierarchy', ...
    'adminlevels', 'officers', 'soldiers', 'priests', 'bureaucrats', ...
    'exams', 'meritocracy', 'govbuildings', 'legalcode', 'judges', ...
    'courts', 'lawyers', 'irrigation', 'watersupply', 'markets', ...
    'storage', 'roads', 'bridges', 'ports', 'nonphonwriting', ...
    'phonwriting', 'tokens', 'precmetals'};
socvarnum = {'territory', 'population', 'popcapital', 'hierarchy', ...
    'adminlevels'}; % numeric

warvars = {'Settlements in a defensive position', 'Wooden palisades', ...
    'Earth ramparts', 'Ditch', 'Moat', 'Stone walls (non-mortared)', ...
    'Stone walls (mortared)', 'Fortified camps', ...
    'Complex fortifications', 'Tension siege engines', ...
    'Sling siege engines', 'Crossbow', 'Specialized military vessels'};
warvarlbls = {'settledef', 'palisades', 'ramparts', 'ditch', 'moat', ...
    'stonedef', 'stonemortared', 'fortcamps', 'complexfort', ...
    'tensionsiege', 'slingsiege', 'crossbow', 'specialmilitary'};

mobvars = {'elite status is hereditary'};
mobvarlbls = {'status'};

varsecs = {'General variables', 'Social Complexity variables', ...
    'Warfare variables', 'Social Mobility'};

varnames = {genvars, socvars, warvars, mobvars};
varlbls = {genvarlbls, socvarlbls, warvarlbls, mobvarlbls};

for i = 1:length(shortname)
    idx = strcmp(seshat.Polity, shortname(i));
    polity.NGA(i) = seshat.NGA(find(idx, 1, 'first'));
    
    for k = 1:length(varnames)
        for j = 1:length(varnames{k})
            row = idx & ...
                strcmp(seshat.Section, varsecs(k)) & ...
                strcmp(seshat.Variable, varnames{k}(j));

            % name/categorical
            if ismember(varlbls{k}(j), genvarlbls)
                if sum(row) == 0
                    val = {'missing'};
                elseif sum(row) == 1
                    val = seshat.Value_From(row);
                elseif sum(row) > 1
                    val = seshat.Value_From(find(row,1,'last'));
                end
                
                polity.(varlbls{k}{j})(i) = val;
                
            % numeric
            elseif ismember(varlbls{k}(j), socvarnum)
                
                if sum(row) == 0
                    val = nan;
                    
                elseif sum(row) == 1
                    if seshat.Value_Note(row) == "simple"
                        val = str2double(seshat.Value_From(row));
                        if isempty(val) % string
                            val = nan;
                        end
                    elseif seshat.Value_Note(row) == "range" % average
                        valfrom = str2double(seshat.Value_From(row));
                        if isempty(valfrom) % string
                            valfrom = nan;
                        end
                        valto = seshat.Value_To(row);
                        val = (valto + valfrom)/2;
                    else
                        val = nan;
                    end
                    
                else % multiple rows: take most recent mean value
                    
                    lastrow = find(row,1,'last');
                    val = str2double(seshat.Value_From(lastrow));
                    if isempty(val) % string
                        val = nan;
                    end
                    
                    if seshat.Value_Note(lastrow) == "range"
                        valto = seshat.Value_To(lastrow);
                        val = mean([val valto]);
                    end
                end
                
                polity.(varlbls{k}{j})(i) = val;
                
            % absent/present
            else 
                
                if sum(row) == 0
                    val = false;
                elseif sum(row) == 1
                    val = seshat.Value_From(row);                    
                elseif sum(row) > 1 && ...
                        ~any(ismember(seshat.Value_Note(row), ...
                        {'uncertain', 'disputed'}))
                    val = seshat.Value_From(find(row,1,'last'));
                else % uncertain/disputed, multiple rows
                    val = false;
                end

                if islogical(val) % already classified as false
                    polity.(varlbls{k}{j})(i) = false;
                elseif contains(val, 'present')
                    polity.(varlbls{k}{j})(i) = true;
                else % absent, unknown, missing, etc
                    polity.(varlbls{k}{j})(i) = false;
                end
            end
        end
    end
end

% some corrections to the data based on Seshat description
polity.govbuildings(polity.shortname == "IqUruk*") = true;
polity.govbuildings(polity.shortname == "PeWari*") = true;
polity.bureaucrats(polity.shortname == "PeWari*") = true;
polity.govbuildings(polity.shortname == "EgNaqa2") = true;
polity.bureaucrats(polity.shortname == "EgNaqa2") = true;

% add start year and end year of polities

% raw data errors:
% - Japan Middle Jomon culture has no BCE in raw data
polity.duration{strcmp(polity.shortname, 'JpJomo4')} = ...
    [polity.duration{strcmp(polity.shortname, 'JpJomo4')} ' BCE'];

% - Final Jomon have no range
polity.duration{strcmp(polity.shortname, 'JpJomo6')} = '1200-300 BCE';

% - Cuzco Late Formative has wrong duration
polity.duration{strcmp(polity.shortname, 'PeCuzLF')} = '1-199CE';

% - Kachi Plain Urban Period II has wrong duration
polity.duration{strcmp(polity.shortname, 'PkUrbn2')} = '2100-1801BCE';

% - Southern Mesopotamia: several differences to DataBrowser
polity.duration{strcmp(polity.shortname, 'IqUbaid')} = '5500-4201 BCE';
polity.duration{strcmp(polity.shortname, 'IqUruk*')} = '4000-3001 BCE';
polity.duration{strcmp(polity.shortname, 'IqEDyn*')} = '3000-2351 BCE';
polity.duration{strcmp(polity.shortname, 'IqAkkad')} = '2350-2150 BCE';
polity.duration{strcmp(polity.shortname, 'IqUrIII')} = '2112-2004 BCE';

% - MYRV duration
polity.duration{strcmp(polity.shortname, 'CnErlit')} = '1850-1650 BCE';

% create numerical durations
bothnums = contains(polity.duration, '-');

duration = polity.duration(bothnums);

splitdur = regexp(duration, '-', 'split');

anybce = contains(duration, 'BCE', 'IgnoreCase', true);

firstnum = cell2mat(cellfun(@(x) str2double(regexp(x{1}, ...
    '[0-9]+', 'match')), splitdur, 'UniformOutput', false));

endbce = ~cellfun('isempty', regexp(duration, 'BCE$'));

secondnum = cell2mat(cellfun(@(x) str2double(regexp(x{2}, ...
    '[0-9]+', 'match')), splitdur, 'UniformOutput', false));

polity.yearstart(bothnums) = (-1).^anybce.*firstnum;
polity.yearend(bothnums) = (-1).^endbce.*secondnum;

idx = polity.yearstart == 0 & polity.yearend == 0;
polity.yearstart(idx) = nan;
polity.yearend(idx) = nan;

polity = sortrows(polity, {'NGA', 'yearstart'});

polity.migration = ismember(polity.preceding, ...
    {'elite migration', 'population migration'});

% drop first Kansai polity to move up earliest point in time:
polity = polity(~strcmp(polity.name, 'Japan - Incipient Jomon'),:);


%% 4. add agriculture dataset

agri = readtable([oosdata 'agri.csv']);

% extract only rows on carbohydrate sources
carb = agri(strcmp(agri.Variable, 'Carbohydrate Source 1'), ...
    {'NGA', 'ValueFrom', 'DateFrom'});

carb = renamevars(carb, {'NGA', 'ValueFrom', 'DateFrom'}, ...
    {'name', 'crop', 'cropyear'});

% keep only earliest source
[~,idx,~] = unique(carb.name);
carb = carb(idx,:);

% read the Beyond 30 sample
carb_b30 = readtable([oosdata 'agri_beyond30.xlsx']);
carb_b30 = renamevars(carb_b30, {'NGA'}, {'name'});

% append Beyond 30 sample to full sample
carb = [carb; carb_b30(:,{'name', 'crop', 'cropyear'})];

% merge carb table to NGA table
ngatbl = join(ngatbl, carb);

% assign NGA characteristics to polity table
polity = join(polity, ngatbl, 'LeftKeys', 'NGA', 'RightKeys', 'name');

% assign number and timing of polities to NGAs
ngastats = grpstats(polity(:,{'NGA', 'yearstart', 'yearend'}), ...
    'NGA', {'min', 'max'});
ngastats = renamevars(ngastats, {'NGA','GroupCount'}, ...
    {'name', 'numpolities'});
ngatbl = join(ngatbl, ngastats);
ngatbl.min_deltayearstart = ngatbl.min_yearstart - ngatbl.cropyear;


%% 5. finding early states, pre- and post-states

polity.state = (polity.bureaucrats | polity.govbuildings) & ...
    ismember(polity.NGA, stateNGAs);


polity.prestate(:) = true;
polity.poststate(:) = false;
polity.seq(:) = nan;

for j = 1:height(ngatbl)
    idx = strcmp(polity.NGA, ngatbl.name(j));
    pnga = polity(idx,:);
    firststate = find(pnga.state, 1, 'first');
    pnga.prestate(firststate:end) = false;
    pnga.poststate(firststate+1:end) = true;
    pnga.state(pnga.prestate | pnga.poststate) = false;
    
    pnga.seq = (1:height(pnga))';
    polity(idx,:) = pnga;
    
    ngatbl.state(j) = any(pnga.state);
end

% manually correct Chuuk Islands and Oro PNG

nostates = {'Chuuk Islands', 'Oro PNG'};
for j = 1:length(nostates)
    polity.prestate(strcmp(polity.NGA, nostates{j})) = true;
    polity.state(strcmp(polity.NGA, nostates{j})) = false;
    polity.poststate(strcmp(polity.NGA, nostates{j})) = false;
end

% check which polities are early states
statepolity = polity(polity.state,{'NGA', 'name', 'duration'});
disp(statepolity)


%% 6. complexity characteristics

% define characteristics
polity.cc1 = polity.population;
polity.cc2 = polity.territory;
polity.cc3 = polity.popcapital;
polity.cc4 = polity.hierarchy + polity.adminlevels;
polity.cc5 = polity.officers + polity.soldiers + polity.priests + ...
    polity.bureaucrats + polity.exams + polity.meritocracy + ...
    polity.govbuildings + polity.legalcode + polity.judges + ...
    polity.courts + polity.lawyers;
polity.cc6 = polity.irrigation + polity.watersupply + polity.markets + ...
    polity.storage + polity.bridges + polity.roads + polity.ports;
polity.cc7 = polity.nonphonwriting + polity.phonwriting;
%polity.cc8 = 
polity.cc8 = polity.tokens + polity.precmetals;

for k = 1:8
    polity.(['cc' num2str(k)]) = polity.(['cc' num2str(k)])./ ...
        max(polity.(['cc' num2str(k)]));
end

ccvars = strcat(repelem({'cc'}, 8)', cellstr(string(1:8))');

coeff = pca(polity{:,ccvars});
polity.pc1 = polity{:,ccvars}*coeff(:,1);



%% preliminary complexity figure

statstbl = grpstats(polity(:,['NGA' ccvars' 'pc1']), 'NGA', 'mean');
statstbl = renamevars(statstbl, {'NGA'}, {'name'});

ngatbl = join(ngatbl, statstbl);

%% map of First PCA

% figure dimensions
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
geoshow('landareas.shp', ...
    'FaceColor', [0.8 0.8 0.8], 'EdgeAlpha', 0)

s = scatterm(ngatbl.clat, ngatbl.clon, 50*ngatbl.GroupCount, ...
    ngatbl.mean_pc1, 'filled', ...
    'MarkerFaceAlpha', .7);

axis([-180 180 -60 90])
axis off
box off
set(gcf, 'Color', 'w')
set(gca,'FontSize', 7,'LooseInset',get(gca,'TightInset'))

colormap('parula')
c = colorbar;
c.Label.String = 'First PCA of complexity';
c.FontSize = 16;
c.Label.FontSize = 16;
c.Position = [0.2 0.1 0.02 0.3];
%caxis([min([nga.circ]) max([nga.circ])])

% ensure PDF print preserves size of figure
f.Units = 'centimeters';
f.PaperUnits = 'centimeters';
f.PaperSize = f.Position(3:4);

framem('FLineWidth', 1, 'MapLatLimit', [-60 90])
box off
axis off
axis tight

exportgraphics(f, 'figures/map_firstpca.pdf')
close all


%% final NGA struct and table

nga = table2struct(ngatbl);

ngatbl = removevars(ngatbl, {'Geometry', 'BoundingBox', 'Lon', 'Lat'});


%% save

save('data/prep/seshat.mat', 'nga', 'ngatbl', 'polity')

