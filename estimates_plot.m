
load('generated_data\filename_database.mat')
markers = {'o','diamond','square'};
crops = {'wheat','rice','maize'};
offset = [-0.10 0.05 -0.0];
cmap = slanCM('romao');
colors = [cmap(160,:);     %origin data 
           cmap(220,:);    %line
           cmap(40,:)];

f = figure();
f.Position = [100 100 400 460];
vmax = 110.567/2/4;
sizes = [4 4 4];
subplot(5,5,2:10)
hold on
for i = 1:length(database)

    if any(contains(database{i}.layers, 'av'))
        disp(database{i}.layers)
        for c = 1:length(crops)
            if strmatch(database{i}.dataset,crops{c})
                load(database{i}.file)
                bs_theta = [theta_optim];
                prob = 1./(1 + exp(-bs_theta));
                v = prob*vmax;
                % e = errorbar(mean(v), 3 + offset(c), std(v), 'horizontal', 'Color', colors(c,:), 'CapSize',0,'LineWidth',1);
                h = plot(mean(v), 3 + offset(c), markers{c}, ...
                     'MarkerSize', sizes(c), ...
                     'Color', colors(c,:), ...
                     'MarkerFaceColor', colors(c,:));
                legend_handles(c) = h;
            end
        end
    end


    if any(contains(database{i}.layers, 'sea')) & (length(database{i}.layers) == 1)
        disp(database{i}.layers)
        disp(database{i}.dataset)
        
        for c = 1:length(crops)
            if strmatch(database{i}.dataset,crops{c})
                load(database{i}.file)
                bs_theta = [theta_optim];
                prob = 1./(1 + exp(-bs_theta(:,1)));
                v = prob*vmax;
                
                % e = errorbar(mean(v), 2 + offset(c), std(v), 'horizontal', 'Color', colors(c,:), 'CapSize',0,'LineWidth',1);
                h = plot(mean(v), 2 + offset(c), markers{c}, ...
                     'MarkerSize', sizes(c), ...
                     'Color', colors(c,:), ...
                     'MarkerFaceColor', colors(c,:));
            end
        end
    end

    if any(contains(database{i}.layers, 'sea')) & any(contains(database{i}.layers, 'prec'))
        disp(database{i}.layers)
        disp(database{i}.dataset)

        for c = 1:length(crops)
            if strmatch(database{i}.dataset,crops{c})
                bs_theta = [theta_optim];
                load(database{i}.file)
                prob = 1./(1 + exp(-bs_theta(:,1)));
                v = prob*vmax;
                % e = errorbar(mean(v), 1 + offset(c), std(v), 'horizontal', 'Color', colors(c,:), 'CapSize',0,'LineWidth',1);
                h = plot(mean(v), 1 + offset(c), markers{c}, ...
                     'MarkerSize', sizes(c), ...
                     'Color', colors(c,:), ...
                     'MarkerFaceColor', colors(c,:));
            end
        end
    end
end
ylim([0,4])
xlim([-2,8])
xticks([-0,5])
yticks([1,2,3])
xline(0,'--k')
l = legend(legend_handles, crops, ...
    'Location', 'northeast', ...
    'FontSize', 8, ...
    'Interpreter', 'latex', ...
    'Color','w', ...
    'TextColor','k');

grid('on')
yticklabels({'sea and precipitation','sea only','baseline model'})
% ylabel('Model','FontSize', 12, ...
%     'Interpreter', 'latex')
set(gca,"TickLabelInterpreter",'latex', 'FontSize', 8, 'Color','k')
set(gca, 'Units', 'normalized', 'Position', [0.25 0.7 0.7 0.25])  % [left bottom width height]
xlabel('average velocity (km/decade)', 'Interpreter','latex')

set(gcf, 'Color', 'White', 'Alphamap', 1)
set(gca, 'Color', 'White', 'Alphamap', 1)
set(gca, 'XColor', [0, 0, 0])
set(gca, 'YColor', [0, 0, 0])

subplot(5,5,12:25)
hold on
for crop = 1:3
    counter = 1; % To track y-position across subplots
    for i = 1:length(database)
        % Check for 'sea' layer (simplified condition)
        if ~any(contains(database{i}.layers, 'sea')) | (length(database{i}.layers) < 2)
            continue;
        end
        
        if strcmp(database{i}.dataset, crops{crop})
            disp(database{i}.file);
            load(database{i}.file);
            bs_theta = [theta_optim];
            prob_diff = 1./(1+exp(-(bs_theta(:,1)+bs_theta(:,2)))) - 1./(1+exp(-bs_theta(:,1)));
            v_diff = prob_diff*vmax;
          
            % e = errorbar(mean(v_diff), counter + offset(crop), std(v_diff), 'horizontal', 'Color', colors(crop,:), 'CapSize',0,'LineWidth',1);
            h = plot(mean(v_diff), counter + offset(crop), markers{crop}, ...
                 'MarkerSize', sizes(crop), ...
                 'Color', colors(crop,:), ...
                 'MarkerFaceColor', colors(crop,:));
 
            counter = counter + 1; % Increment y-position
        end
    end
end

ylim([0,6])
yticks([1,2,3,4,5])
xlim([-10,10])
xticks([-5,0,5])
grid('on')
yticklabels({'anisotropy','crop suitability','rivers','precipitation','mean temperature','sea only'})
set(gca,"TickLabelInterpreter",'latex')
xline(0,'--k')
% ylabel('Model','FontSize', 12, ...
%     'Interpreter', 'latex')
set(gca, 'Units', 'normalized', 'Position', [0.25 0.1 0.7 0.5], 'FontSize', 8)  % [left bottom width height]
xlabel('velocity difference (km/decade)', 'Interpreter','latex')
set(gcf, 'Color', 'White', 'Alphamap',0)
set(gcf, 'Color', 'White', 'Alphamap', 1)
set(gca, 'Color', 'White', 'Alphamap', 1)
set(gca, 'XColor', [0, 0, 0])
set(gca, 'YColor', [0, 0, 0])
exportgraphics(gcf,'saved_plots/estimates.pdf','ContentType','vector')