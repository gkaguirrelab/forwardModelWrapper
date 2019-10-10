function [mycolormap] = make_ecc_colormap(mapres)


%% Create colormap
% Blue to Red (0,0,1) -> (1,0,0)
mycolormap(0*mapres(3)/5+1:1*mapres(3)/5,1) = linspace(0,1,mapres(3)/5);
mycolormap(0*mapres(3)/5+1:1*mapres(3)/5,2) = zeros(mapres(3)/5,1);
mycolormap(0*mapres(3)/5+1:1*mapres(3)/5,3) = linspace(1,0,mapres(3)/5);
% Red to Yellow (1,0,0) -> (1,0.85,0)
mycolormap(1*mapres(3)/5+1:2*mapres(3)/5,1) = ones(mapres(3)/5,1);
mycolormap(1*mapres(3)/5+1:2*mapres(3)/5,2) = linspace(0,0.85,mapres(3)/5);
mycolormap(1*mapres(3)/5+1:2*mapres(3)/5,3) = zeros(mapres(3)/5,1);
% Yellow to Green (1,0.85,0) -> (0,0.85,0)
mycolormap(2*mapres(3)/5+1:3*mapres(3)/5,1) = linspace(1,0,mapres(3)/5);
mycolormap(2*mapres(3)/5+1:3*mapres(3)/5,2) = 0.85*ones(mapres(3)/5,1);
mycolormap(2*mapres(3)/5+1:3*mapres(3)/5,3) = zeros(mapres(3)/5,1);
% Green to Cyan (0,0.85,0) -> (0,0.85,1)
mycolormap(3*mapres(3)/5+1:4*mapres(3)/5,1) = zeros(mapres(3)/5,1);
mycolormap(3*mapres(3)/5+1:4*mapres(3)/5,2) = 0.85*ones(mapres(3)/5,1);
mycolormap(3*mapres(3)/5+1:4*mapres(3)/5,3) = linspace(0,1,mapres(3)/5);
% Cyan to White (0,0.85,1) -> (1,1,1)
mycolormap(4*mapres(3)/5+1:5*mapres(3)/5,1) = linspace(0,1,mapres(3)/5);
mycolormap(4*mapres(3)/5+1:5*mapres(3)/5,2) = linspace(0.85,1,mapres(3)/5);
mycolormap(4*mapres(3)/5+1:5*mapres(3)/5,3) = ones(mapres(3)/5,1);

end