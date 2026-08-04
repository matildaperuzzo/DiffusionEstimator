function animate_map(A_mat, x, y, filename)

    

% Create a cell array to store the frames
    [~,~,n_frames] = size(A_mat);
    frames = cell(1, n_frames);
    [X,Y] = meshgrid(x,y);
    land = shaperead('landareas.shp', 'UseGeoCoords', true);

    R = georefcells([min(x) max(x)], [min(y) max(y)], ...
        size(squeeze(A_mat(:,:,1))));
    loc = 10;
    fwidth = 20;

    for i = 1:n_frames
        % Plot contour plots of errors standardizing the errors
        f = figure('Units','inches','Position',[loc loc fwidth fwidth/2.2], ...
        'PaperPosition',[.25 .25 8 6]);
        
        hold on;
        worldmap(["Ireland", "Iran"])
        axis xy

        geoshow(squeeze(A_mat(:,:,i)), R, 'DisplayType', 'texturemap')
        clim([min(A_mat(:)), max(A_mat(:))]);
        colormap(copper);
        geoshow(fliplr([land.Lat]),fliplr([land.Lon]),'DisplayType', ...
        'Polygon', 'FaceColor', 'white', 'FaceAlpha', 0.5)

        % Capture the current frame
        frames{i} = getframe(gcf);
        
        % Close the figure to avoid overlapping plots
        close(gcf);
    end

    for i = 1:n_frames
        % Convert the frame to an indexed image
        [frame_data, cmap] = rgb2ind(frames{i}.cdata, 256);
        
        % Write the frame to the GIF file
        if i == 1
            imwrite(frame_data, cmap, filename, 'gif', 'LoopCount', Inf, 'DelayTime', 0.5);
        else
            imwrite(frame_data, cmap, filename, 'gif', 'WriteMode', 'append', 'DelayTime', 0.5);
        end
    end
end