clear all

active_layers = [0 0 0 0];
active_layers = [active_layers ones(1,17)];

parameters = data_prep(20, active_layers);

%%
for i = 1:17
    figure(i)
    hold on;
    h = pcolor(parameters.X{i});
    set(h, 'EdgeColor', 'none');
    scatter(parameters.dataset_idx(:,2), parameters.dataset_idx(:,1), ...
        'filled', ...
        'MarkerFaceColor',[0.6350 0.0780 0.1840], ...
        'SizeData',10);
    title('Layer '+string(i-1))
    clim([0 1]);
    grid off;
    hold off;
end