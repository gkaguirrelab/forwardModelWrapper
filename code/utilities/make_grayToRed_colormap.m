function [mycolormap] = make_grayToRed_colormap(mapres,show)


%% Set up defaults
if ~exist('show','var')
    show = 0;
end
%% Create colormap
% Gray to Red-Gray 
mycolormap(0*mapres(3)/2+1:1*mapres(3)/2,1) = linspace(0.75,0.875,mapres(3)/2);
mycolormap(0*mapres(3)/2+1:1*mapres(3)/2,2) = linspace(0.75,0.375,mapres(3)/2);
mycolormap(0*mapres(3)/2+1:1*mapres(3)/2,3) = linspace(0.75,0.375,mapres(3)/2);
% Red-Gray to Red
mycolormap(1*mapres(3)/2+1:2*mapres(3)/2,1) = linspace(0.875,1,mapres(3)/2);
mycolormap(1*mapres(3)/2+1:2*mapres(3)/2,2) = linspace(0.375,0,mapres(3)/2);
mycolormap(1*mapres(3)/2+1:2*mapres(3)/2,3) = linspace(0.375,0,mapres(3)/2);
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