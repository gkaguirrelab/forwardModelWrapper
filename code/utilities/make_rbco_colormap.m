function [mycolormap] = make_rbco_colormap(mapres,show)

%   Creates a matrix useful for plotting pRF and ccRF correlation maps
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
% Blue to Blue-Gray 
mycolormap(0*mapres(3)/4+1:1*mapres(3)/4,1) = linspace(0,0.375,mapres(3)/4);
mycolormap(0*mapres(3)/4+1:1*mapres(3)/4,2) = linspace(0,0.375,mapres(3)/4);
mycolormap(0*mapres(3)/4+1:1*mapres(3)/4,3) = linspace(1,0.875,mapres(3)/4);
% Blue-Gray to Gray 
mycolormap(1*mapres(3)/4+1:2*mapres(3)/4,1) = linspace(0.375,0.75,mapres(3)/4);
mycolormap(1*mapres(3)/4+1:2*mapres(3)/4,2) = linspace(0.375,0.75,mapres(3)/4);
mycolormap(1*mapres(3)/4+1:2*mapres(3)/4,3) = linspace(0.875,0.75,mapres(3)/4);
% Gray to Red-Gray 
mycolormap(2*mapres(3)/4+1:3*mapres(3)/4,1) = linspace(0.75,0.875,mapres(3)/4);
mycolormap(2*mapres(3)/4+1:3*mapres(3)/4,2) = linspace(0.75,0.375,mapres(3)/4);
mycolormap(2*mapres(3)/4+1:3*mapres(3)/4,3) = linspace(0.75,0.375,mapres(3)/4);
% Red-Gray to Red
mycolormap(3*mapres(3)/4+1:4*mapres(3)/4,1) = linspace(0.875,1,mapres(3)/4);
mycolormap(3*mapres(3)/4+1:4*mapres(3)/4,2) = linspace(0.375,0,mapres(3)/4);
mycolormap(3*mapres(3)/4+1:4*mapres(3)/4,3) = linspace(0.375,0,mapres(3)/4);
%% Plot resulting colormap
if show
    figure;
    x = linspace(-1,+1,mapres(3)); [xx,yy] = meshgrid(x);
    [xx,yy] = meshgrid(x);
    img = yy - min(yy(:));
    img = img/nanmax(img(:))*mapres(2);
    imagesc(x,x,img)
    cb = colorbar;
    caxis([mapres(1) mapres(2)]);
    colormap(mycolormap)
    set(cb,'YDir','normal')
end