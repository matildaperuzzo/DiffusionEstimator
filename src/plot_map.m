function plot_map(A, R, pinhasi, pinhasi_active, land, errors)
    loc = 10;
    fwidth = 20;
    tic
    f = figure('Units','inches','Position',[loc loc fwidth fwidth/2.2], ...
    'PaperPosition',[.25 .25 8 6]);
    hold on;

    worldmap(["Ireland", "Iran"])
    axis xy

    % color map with A
    geoshow(sum(A,3), R, 'DisplayType', 'texturemap')
    %make sea white
    geoshow(fliplr([land.Lat]),fliplr([land.Lon]),'DisplayType', ...
        'Polygon', 'FaceColor', 'white', 'FaceAlpha', 0.5)

    framem('FLineWidth', 1, 'FontSize', 7)
    [size_x size_y size_t] = size(A);
    predictions = size_t - pinhasi_active(:,3);
    
    norm_errors = (errors - min(errors))/(max(errors) - min(errors));
    cmap = colormap(flip(pink));
    num_colors = size(cmap,1);
    color_indices = round(norm_errors * (num_colors - 1)) + 1;
    colors = cmap(color_indices,:);

    colormap(parula)
    % Loop over each point and plot with the corresponding color
    for i = 1:length(pinhasi.lat)
        geoshow(pinhasi.lat(i), pinhasi.lon(i), 'DisplayType', 'point', ...
            'Marker', 'o', 'MarkerEdgeColor', 'none', ...
            'MarkerFaceColor', colors(i,:), 'MarkerSize', 5);
    end
    % plot error histogram
    figure
    histogram(errors)
    title('Error histogram')
    xlabel('Error')
    ylabel('Frequency')
    fprintf('Elapsed time: %.2f seconds\n', toc);
end
