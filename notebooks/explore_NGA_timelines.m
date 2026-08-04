%{
project: BottleNecks
title: explore NGA timelines
purpose: make some explorative NGA timelines
input: centrality.mat
output: 
author: DS
created: 2024-06-24, based on display_seshat.m from 2022-07-15

DESCRIPTION OF PROCESS

1. load data
2. make timelines
%}

clear
clc

cd '~/Dropbox/Research/BottleNecks'


%% load data

load('data/prep/seshat.mat')


%% sort NGA by supraregion and year of earliest polity

sreg = {'Western Eurasia & Africa', 'Central & East Asia', ...
    'Americas & Pacific'};

ngatbl.sreg(ismember(ngatbl.name, ...
    {'Konya Plain', 'Southern Mesopotamia', 'Susiana', 'Crete', ...
    'Upper Egypt', 'Latium', 'Yemeni Coastal Plain', 'Paris Basin', ...
    'Galilee', 'Iceland', 'Niger Inland Delta', 'Ghanaian Coast'})) = ...
    sreg(1);

ngatbl.sreg(ismember(ngatbl.name, ...
    {'Kansai', 'Kachi Plain', 'Middle Yellow River Valley', ...
    'Middle Ganga', 'Sogdiana', 'Deccan', 'Orkhon Valley', ...
    'Cambodian Basin', 'Central Java', 'Lena River Valley', ...
    'Kapuasi Basin', 'Southern China Hills', 'Garo Hills'})) = sreg(2);

ngatbl.sreg(cellfun(@isempty, ngatbl.sreg)) = sreg(3);

for j = 1:height(ngatbl)
    
    % find earliest polity in each NGA
    pnga = polity(strcmp(polity.NGA, ngatbl.name(j)),:);
    
    % earliest culture (polity)
    ngatbl.earliestpolity(j) = min(pnga.yearstart);
end

ngatbl = sortrows(ngatbl, {'earliestpolity'}, 'descend');
ngatbl = sortrows(ngatbl, {'sreg'});


%% figures of NGA timelines

% three or more hierarchies ("state")

loc = 5;
fwidth = 18;

f = figure('Units','inches','Position',[loc loc fwidth fwidth*.55], ...
    'PaperPositionMode','auto');

tiledlayout(f, 1, 1, 'padding', 'compact');
ax = nexttile;

hold on;

state = polity.hierarchy >= 3;

for i = 1:height(ngatbl)
    idx = find(strcmp(polity.NGA, ngatbl.name(i)));
    for t = 1:length(idx)
        if ~state(idx(t))
            l1 = line( ...
                [polity.yearstart(idx(t)) polity.yearend(idx(t))], ...
                [i i], ...
                'Color', [.8 .8 .8 .5], 'LineWidth', 2, 'Marker', '|');
        else
            l2 = line( ...
                [polity.yearstart(idx(t)) polity.yearend(idx(t))], ...
                [i i], ...
                'Color', [.3 .3 1 .5], 'LineWidth', 2, 'Marker', '|');
        end
    end
    MinYearNGA = min(polity.yearstart(idx));
    text(MinYearNGA-50, i, ...
        polity.NGA(idx(1)), ... % all NGAs in idx are the same, take 1st
        'FontSize', 14, 'HorizontalAlignment', 'right')
end

for i = 1:length(sreg)
    txt = text(2300, mean(find(ismember(ngatbl.sreg, sreg(i)))), ...
        sreg{i});
    txt.Rotation = 270;
    txt.HorizontalAlignment = 'center';
    txt.FontSize = 16;
    
    line([2100 2100], ...
        [find(ismember(ngatbl.sreg, sreg(i)),1,'first')-.2 ...
        find(ismember(ngatbl.sreg, sreg(i)),1,'last')+.2], ...
        'Color', [.6 .6 .6], 'LineWidth', 2.5)
end

xlim([-10000, 2300]) 

xlabel('Year')

ax1 = gca;
ax1.YAxis.Visible = 'off';

la = legend([l2 l1], 'Entities with 3+ hierarchies', 'Other entities', ...
    'Location', 'SouthWest');
la.FontSize = 16;
legend boxoff

set(gca,'FontSize', 14)

set(gcf, 'Color', 'w')
box off

exportgraphics(f, 'figures/timeline_hierarchy.pdf')
close all


%% hierarchies

figure; hold on;

ngaids = ngatbl.id;

l = struct();

for i = 1:length(ngaids)
    idx = find(polity.ngaid == ngaids(i));
    for t = 1:length(idx)
        if hierarchy(idx(t)) > 0
            hc = 1 - .8*(hierarchy(idx(t))/max(hierarchy));
            hlabel = ['h' num2str(hierarchy(idx(t)))];
            l.(hlabel) = line( ...
                [polity.yearstart(idx(t)) polity.yearend(idx(t))], ...
                [i i], 'Color', [hc hc 1], ...
                'LineWidth', hierarchy(idx(t)));
        end
    end
    MinYearNGA = min(polity.yearstart(idx));
    text(MinYearNGA-200, i, ...
        polity.NGA(idx(1)), ... % all NGAs in idx are the same, take 1st
        'HorizontalAlignment', 'right')
end

xlabel('Year')

ax1 = gca;
ax1.YAxis.Visible = 'off';

lgd = legend([l.h1 l.h2 l.h3 l.h4 l.h5 l.h6 l.h7], ...
    '1', '2', '3', '4', '5', '6', '7', ...
    'Location', 'NorthWest');

lgd.Title.String = 'Hierarchies:';
lgd.Title.FontWeight = 'normal';
legend boxoff

set(gcf, 'Color', 'w')
box off

print('-r300', '-dpng', '../figures/seshat_NGAlines_hierarchy.png')

axis([-6000 2000 0 35])

print('-r300', '-dpng', '../figures/seshat_NGAlines_hierarchy_6k.png')
close all


%% various indicator variables for trade and public goods

vlist = {'markets', 'irrigation', 'govbuildings', 'roads'};
vlbls = {'Markets','Irrigation systems','Government buildings','Roads'};

figure; hold on;

for k = 1:length(vlist)

    vdata = replace(polity.(vlist{k}), ...
        {'present','inferred present'}, '1');
    vdata = replace(vdata, ...
        {'missing','inferred absent', 'unknown', 'suspected unknown', ...
        'absent'}, '0');
    vdata = cellfun(@str2num, vdata);
    vdata(ismember(polity.(vlist{k}), {'missing', 'unknown'})) = nan;

    ngaids = ngatbl.id;

    l = struct();

    for i = 1:length(ngaids)
        idx = find(polity.ngaid == ngaids(i));
        for t = 1:length(idx)
            if vdata(idx(t)) == 1
                l1 = line( ...
                    [polity.yearstart(idx(t)) polity.yearend(idx(t))], ...
                    [i i], 'Color', [0 0 1], ...
                    'LineWidth', 3.5);
            else
                l0 = line( ...
                    [polity.yearstart(idx(t)) polity.yearend(idx(t))], ...
                    [i i], 'Color', [.5 .5 1], ...
                    'LineWidth', .5);
            end
        end
        MinYearNGA = min(polity.yearstart(idx));
        text(MinYearNGA-200, i, ...
            polity.NGA(idx(1)), ... 
            'HorizontalAlignment', 'right')
    end

    xlabel('Year')

    ax1 = gca;
    ax1.YAxis.Visible = 'off';

    lgd = legend([l0 l1], ...
        'absent', 'present', ...
        'Location', 'NorthWest');

    lgd.Title.String = [vlbls{k} ':'];
    lgd.Title.FontWeight = 'normal';
    legend boxoff

    set(gcf, 'Color', 'w')
    box off

    print('-r300', '-dpng', ...
        ['../figures/seshat_NGAlines_' vlist{k} '.png'])

    axis([-6000 2000 0 35])

    print('-r300', '-dpng', ...
        ['../figures/seshat_NGAlines_' vlist{k} '_6k.png'])
    close all
end

