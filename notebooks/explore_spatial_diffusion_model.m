%% spatial diffusion model

clear
clc

d = 22.5; % distance between two cells
gamma = 10; % km per decade

rng(123)


%% pinhasi simulation

% load build
load('data/prep/geography.mat');

% load pinhasi
pinhasi = readtable( ...
    'data/raw/pinhasi/Neolithic_timing_Europe_PLOS.xls');

pinhasi = pinhasi(pinhasi.Var1 == "SITE",:); %% keep only site rows

pinhasi = renamevars(pinhasi, {'Latitude', 'Longitude', 'CALC14BP'}, ...
    {'lat', 'lon', 'bp'});

pinhasi = pinhasi(:,{'lat', 'lon', 'bp'});

pinhasi.bp = 1950 - pinhasi.bp; % from BP to year

idx = find(pinhasi.bp == min(pinhasi.bp));

% restrict to Europe/Iran range
topleft = [60, -17.19];
bottomright = [15, 65.07];

latidx = lat <= topleft(1) & lat >= bottomright(1);
lonidx = lon >= topleft(2) & lon <= bottomright(2);

latp = lat(latidx);
lonp = lon(lonidx);

% turn pinhasi into matrix

refvec = [1/delta latp(end) lonp(1)];
[X, Y] = meshgrid(lonp, latp);

% pinhasimtx = imbedm(pinhasi.lat(idx), pinhasi.lon(idx), ...
%     1, zeros(length(latp), length(lonp)), refvec);

pinhasimtx = zeros(length(latp),length(lonp));
[~, index_x] = min(abs(latp - pinhasi.lat(idx)));
[~, index_y] = min(abs(lonp - pinhasi.lon(idx)));
pinhasimtx(index_x,index_y) = 1;


contour(X,Y,pinhasimtx)


%% define frontier function
function F = map_frontier(a)
    % Get the size of the matrix
    [rows, cols] = size(a);
    % Initialize the frontier matrix
    F = false(rows, cols);

    % Iterate through each cell in the matrix
    for r = 1:rows
        for c = 1:cols
            if a(r, c) % If the cell is activated
                % Check all 8 possible neighboring cells
                for i = -1:1
                    for j = -1:1
                        if i == 0 && j == 0
                            continue; % Skip the cell itself
                        end
                        nr = r + i; % Neighbor row index
                        nc = c + j; % Neighbor column index
                        % Check if neighbor is within bounds
                        if nr >= 1 && nr <= rows && nc >= 1 && nc <= cols
                            if ~a(nr, nc) % If neighbor is not activated
                                F(nr, nc) = true; % Mark as frontier
                            end
                        end
                    end
                end
            end
        end
    end
end

%% define simulation array

T = 200;

A = false(length(latp), length(lonp), T);

A(:,:,1) = pinhasimtx == 1; % starting location

x = csidata(latidx, lonidx);
x = x./max(x);

% simulate
for t = 2:T
    a = A(:,:,t-1); % matrix of currently activated cells
    F = map_frontier(a); % find adjacent cells to currently activated ones
    f = find(F); % indices of frontier cells
    pi = gamma/d*x;
    adopt = rand(length(f), 1) <= pi(f); % which frontier cells adopt
    a(f(adopt)) = true; % update activated cells to include adopters
    A(:,:,t) = a;
end


%% make gif

land = shaperead('landareas.shp', 'UseGeoCoords', true);

R = georefcells([latp(1) latp(end)], [lonp(1) lonp(end)], ...
    size(pinhasimtx));

loc = 10;
fwidth = 20;

for t = 1:T

    f = figure('Units','inches','Position',[loc loc fwidth fwidth/2.2], ...
    'PaperPosition',[.25 .25 8 6]);
    hold on;

    worldmap(["Ireland", "Iran"])

    geoshow(A(:,:,t), R, 'DisplayType', 'texturemap')
    axis xy

    geoshow(fliplr([land.Lat]),fliplr([land.Lon]),'DisplayType', ...
        'Polygon', 'FaceColor', 'white')

    framem('FLineWidth', 1, 'FontSize', 7)
    
    title(['\fontsize{16}' num2str(min(pinhasi.bp)+10*t)])

    filename = 'figures/pinhasi_diffusion.gif';

    frame = getframe(f);
    im = frame2im(frame);
    [B,map] = rgb2ind(im,256);

    if t == 1
        imwrite(B,map,filename,"gif","LoopCount",Inf,"DelayTime",.02);
    else
        imwrite(B,map,filename,"gif","WriteMode","append","DelayTime",.02);
    end

    exportgraphics(f, ['figures/pinhasi_diffusion-' num2str(t) '.png'])

    close all

end
