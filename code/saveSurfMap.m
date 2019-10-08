function saveSurfMap(dataPath,surfPath, varargin)
%   Visualize a surface overlay in matlab
%
%   Usage:
%   surface_plot(p.Results.mapType,data,subject_name,hemi,surface,thresh,p.Results.alphaVal,polar_map,p.Results.viewAngle,p.Results.lightAngle)
%
%   p.Results.mapTypes:
%       'ecc' 'pol' 'sig' 'co' 'var' 'areas' 'zstat'
%   data = full path to data to overlay on surface or data array
%       (note, must be in the same space as 'surface')
%   subject_name = subject surface to plot (e.g. 'fsaverage')
%   hemi = hemisphere ('lh', 'rh');
%   surface = 'inflated' % 'pial' or any surface in freesurfer
%   p.Results.alphaVal = p.Results.alphaValparancy value (0.65 - default)
%   thresh = logical vector of the same length as data file, 0s for
%   vertices not to show (e.g. less than some threshold).
%   polar_map = portion of visual field. 'hemi' or 'full' ('hemi' - default);
%   p.Results.viewAngle = view angle (default: [45,-10] for 'lh' and [-45,-10] for 'rh');
%   p.Results.lightAngle = light angle (default: [45,-10] for 'lh' and [-45,-10] for 'rh');
%
%   example: surface_plot('ecc','/home/andrew/SUBJECTS/RESTING/data/stim_lh_occipital_resting_ecc_Templ_rf.tf_avgsurf.nii.gz','fsaverage','lh',0.75)
%
%   written by Andrew Bock 2013
%
%{
    dataPath = '/tmp/flywheel/v0/output/maps_nativeMGZ/R_original_eccentricity_map.mgz'
    surfPath = '/tmp/flywheel/v0/input/structZip/TOME_3021/T1w/TOME_3021/surf'
    saveSurfMap(dataPath,surfPath,'hemisphere','rh','maxEccentricity',10)
%}



%% Input parser
p = inputParser; p.KeepUnmatched = true;

% Required
p.addRequired('dataPath', @ischar);
p.addRequired('surfPath', @ischar);

% Optional key-value pairs
p.addParameter('mapType', 'ecc', @ischar);
p.addParameter('hemisphere','lh',@ischar);
p.addParameter('whichSurface','inflated',@ischar); % pial, white, or sphere
p.addParameter('maxEccentricity',30,@isnumeric);
p.addParameter('alphaVal',0.85,@isnumeric);
p.addParameter('viewAngle',[-30,-10],@isnumeric);
p.addParameter('lightAngle',[-30,-10],@isnumeric);
p.addParameter('showCurvature',true,@islogical);

% parse
p.parse(dataPath, surfPath, varargin{:})



%% Define color map
switch p.Results.mapType
    case 'ecc'
        mapres=[0 p.Results.maxEccentricity 200];
        mycolormap = make_ecc_colormap(mapres);
    case 'pol'
        mapres=[0 360 200];
        mycolormap = make_polar_colormap(mapres);
    case 'sig'
        mycolormap = flipud(jet(200));
        mapres=[0 10 200];
    case 'co'
        %         mycolormap = jet(200);
        mapres=[-1 1 200];
        mycolormap = make_rbco_colormap(mapres);
    case 'areas'
        mycolormap = [
            .75 .75 .75
            1 1 1
            .75 .75 .75
            1 1 1
            .75 .75 .75
            1 1 1
            .75 .75 .75
            1 1 1
            .75 .75 .75
            1 1 1
            ];
        mapres=[-5 5 length(mycolormap)];
    otherwise
        error('Unrecognized mapType');
end
myvec = linspace(mapres(1),mapres(2),size(mycolormap,1));


%% Load surface files
surfName = fullfile(surfPath,[p.Results.hemisphere '.' p.Results.whichSurface]);
[vert,face] = freesurfer_read_surf(surfName);


%% Prepare the curvature information
% Load the curvature map
curvName = fullfile(surfPath,[p.Results.hemisphere '.curv']);
[curv,~] = freesurfer_read_curv(curvName);

% Prepare the curvature map and cmap for plotting
if p.Results.showCurvature
    % Reverse the sign for plotting. Not sure why this is needed yet
    curv = -curv;
    
    % Binarize the curvature information
    ind.sulci = curv<0;
    ind.gyri = curv>0;
    ind.medial = curv==0;
    curv(ind.sulci) = .8;
    curv(ind.gyri) = 0.9;
    curv(ind.medial) = 0.7;
    cmap_curv = repmat(curv,1,3);
else
    curv = 0.85 * ones(size(curv));
    cmap_curv = repmat(curv,1,3);
end


%% Place the curvature and map information into a patch structure
brain.vertices = vert;
brain.faces = face;
brain.facevertexcdata = cmap_curv;


%% Load map data file
srf = load_mgh(dataPath);


%% Threshold data
% Want to implement thresholding based on R^2 map
%srf(srf<thresh) = nan;


%% Color vertices
cmap_vals = zeros(size(cmap_curv))+0.5;
alpha_vals = zeros(size(cmap_curv,1),1);
for i = 1:length(srf)
    % Find the closest color value to the srf(i) value
    [~,ind] = min(abs(myvec-srf(i)));
    if isnan(srf(i))
        col4thisvox = [.8 .8 .8]; % set nan to gray
    else
        col4thisvox = mycolormap(ind,:);
    end
    cmap_vals(i,:) = col4thisvox;
end


%% Set p.Results.alphaValparency
alpha_vals(~isnan(srf)) = p.Results.alphaVal;



%% Make figure
figure('units','normalized','position',[0 0 1 1]);
% make legend first, so that brain surface is active last
subplot(4,4,3);
if strcmp(p.Results.mapType,'ecc') || strcmp(p.Results.mapType,'pol')
    x = linspace(-1,+1,mapres(3)); [xx,yy] = meshgrid(x);
    [th,r] = cart2pol(xx,yy);
    if strcmp(p.Results.mapType,'ecc')
        img = r;
        img(r>1) = nan;
    elseif strcmp(p.Results.mapType,'pol')
        img = th;
            img(r>1) = 360;
    else
        img = yy - min(yy(:));
    end
    img = img/nanmax(img(:))*mapres(2);
    img(isnan(img)) = mapres(2);
    imagesc(x,x,img)
end
if ~strcmp(p.Results.mapType,'pol') && ~strcmp(p.Results.mapType,'ROI') && ~strcmp(p.Results.mapType,'image')
    cb = colorbar;
    caxis([mapres(1) mapres(2)]);
end
axis tight equal off
% if strcmp(p.Results.mapType,'pol')
%     legendmap = [.8 .8 .8;.8 .8 .8;mycolormap];
% else
if strcmp(p.Results.mapType,'areas') || strcmp(p.Results.mapType,'blueareas') ...
        || strcmp(p.Results.mapType,'co') || strcmp(p.Results.mapType,'rbco')
    legendmap = mycolormap;
else
    if strcmp(p.Results.mapType,'pol')
        legendmap = mycolormap;
    else
        legendmap = [mycolormap;.8 .8 .8];
    end
end
% end
if strcmp(p.Results.mapType,'image')
else
    colormap(legendmap)
end
% Flip map if polar angle (e.g. upper visal field - ventral surface)
% if strcmp(p.Results.mapType,'pol')
%     set(cb,'YDir','reverse')
% else
%     set(cb,'YDir','normal')
% end


%% Plot brain and surface map
smp = brain;
smp.facevertexcdata = cmap_vals;
%set(gcf,'name',data);
subplot(1,2,1); hold on
hbrain = patch(brain,'EdgeColor','none','facecolor','interp','FaceAlpha',1);
hmap = patch(smp,'EdgeColor','none','facecolor','interp','FaceAlpha','flat'...
    ,'FaceVertexAlphaData',alpha_vals,'AlphaDataMapping','none');
daspect([1 1 1]);
% Camera settings
cameratoolbar;
camproj perspective; % orthographic; perspective
lighting phong; % flat; gouraud; phong
material dull; % shiny; metal; dull
view(p.Results.viewAngle(1),p.Results.viewAngle(2));
%lightangle(p.Results.lightAngle(1),p.Results.lightAngle(2));
hcamlight = camlight('headlight');
axis tight off;
%zoom(2)
% note - to delete light, type 'delete(findall(gcf,'Type','light'))'