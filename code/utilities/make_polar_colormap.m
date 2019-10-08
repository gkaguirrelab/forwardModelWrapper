function [mycolormap] = make_polar_colormap(mapres,show)

%   Creates a matrxi useful for plotting pRF and ccRF polar angle maps
%
%   Usage:
%   [mycolormap] = make_polar_colormap(show)
%
%   defaults:
%   show = 0; do not plot the resulting polar angle colormap
%
%   Written by Andrew S Bock Oct 2014

%% Set up defaults
if ~exist('show','var')
    show = 0;
end
%% Create colormap
%mycolormap = blue_green_red;
mycolormap = zeros(mapres(3),3);
% Yellow to Red
mycolormap(1:mapres(3)/4,1) = ones(mapres(3)/4,1);
mycolormap(1:mapres(3)/4,2) = linspace(1,0,mapres(3)/4);
% Red to Green
mycolormap(mapres(3)/4+1:mapres(3)/2,1) = linspace(1,0,mapres(3)/4);
mycolormap(mapres(3)/4+1:mapres(3)/2,2) = linspace(0,1,mapres(3)/4);
% Green to Blue
mycolormap(mapres(3)/2+1:3*mapres(3)/4,2) = linspace(1,0,mapres(3)/4);
mycolormap(mapres(3)/2+1:3*mapres(3)/4,3) = linspace(0,1,mapres(3)/4);
% Blue to Yellow
mycolormap(3*mapres(3)/4+1:mapres(3),1) = linspace(0,1,mapres(3)/4);
mycolormap(3*mapres(3)/4+1:mapres(3),2) = linspace(0,1,mapres(3)/4);
mycolormap(3*mapres(3)/4+1:mapres(3),3) = linspace(1,0,mapres(3)/4);
% Flip so visual field is reversed
mycolormap = flipud(mycolormap);
%% Plot resulting colormap
if show
    figure;
    x = linspace(-1,1,mapres(3));
    [xx,yy] = meshgrid(x);
    [th,r] = cart2pol(xx,yy);
    img = th;
    img(r>1) = 3.2; % Set values outside of circle to black
    img = img/nanmax(img(:))*mapres(2);
    imagesc(x,x,img);
    colorbar;
    axis tight equal off
    set(gca,'ydir','normal')
    colormap([mycolormap;.8 .8 .8]);
end