function [mycolormap] = make_grayToRed_colormap(mapres)


%% Create colormap
% Gray to Red-Gray 
mycolormap(0*mapres(3)/2+1:1*mapres(3)/2,1) = linspace(0.75,0.875,mapres(3)/2);
mycolormap(0*mapres(3)/2+1:1*mapres(3)/2,2) = linspace(0.75,0.375,mapres(3)/2);
mycolormap(0*mapres(3)/2+1:1*mapres(3)/2,3) = linspace(0.75,0.375,mapres(3)/2);
% Red-Gray to Red
mycolormap(1*mapres(3)/2+1:2*mapres(3)/2,1) = linspace(0.875,1,mapres(3)/2);
mycolormap(1*mapres(3)/2+1:2*mapres(3)/2,2) = linspace(0.375,0,mapres(3)/2);
mycolormap(1*mapres(3)/2+1:2*mapres(3)/2,3) = linspace(0.375,0,mapres(3)/2);

end