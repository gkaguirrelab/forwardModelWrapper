function calcCorticalMag(Subject, inferredMapsDirPath, surfPath, outPath, varargin)
%
%
%
% Examples:
%{
    inferredMapsDirPath = '/tmp/flywheel/v0/output/inferred_surface/';
    surfPath = '/tmp/flywheel/v0/input/structZip/TOME_3045/T1w/TOME_3045/surf/';
    outPath = '/tmp/flywheel/v0/output/';
    calcCorticalMag('TOME_3045',inferredMapsDirPath, surfPath, outPath)
%}

%% Parse inputs
p = inputParser; p.KeepUnmatched = false;

% Required
p.addRequired('Subject',@isstr);
p.addRequired('inferredMapsDirPath',@isstr);
p.addRequired('surfPath',@isstr);
p.addRequired('outPath',@isstr);

% Optional key-value pairs
p.addParameter('hemisphere','rh',@ischar);
p.addParameter('whichSurface','white',@ischar); % pial, white, or sphere

% Parse
p.parse(Subject, inferredMapsDirPath, surfPath, outPath, varargin{:})


%% Load surface files
surfName = fullfile(surfPath,[p.Results.hemisphere '.' p.Results.whichSurface]);
[vert,face] = freesurfer_read_surf(surfName);


%% Load map data file
mapPath = fullfile(inferredMapsDirPath,[p.Results.hemisphere '.' Subject '_inferred_angle.mgz']);
angleMap = squeeze(load_mgh(mapPath));

mapPath = fullfile(inferredMapsDirPath,[p.Results.hemisphere '.' Subject '_inferred_eccen.mgz']);
eccenMap = squeeze(load_mgh(mapPath));

mapPath = fullfile(inferredMapsDirPath,[p.Results.hemisphere '.' Subject '_inferred_varea.mgz']);
[vareaMap, M, mr_parms, volsz] = load_mgh(mapPath);
vareaMap = squeeze(vareaMap);


% The polar angle values will be negative in the right hemisphere
if strcmp(p.Results.hemisphere,'rh')
%    angleSet = -angleSet;
end

%% Find all valid vertices
validIdx = find(vareaMap~=0);

cmfMap = nan(size(vareaMap));
for ii=1:length(validIdx)
    neighborIdx = unique(face(any((face==validIdx(ii))'),:));
    thisCortCoord = squeeze(vert(validIdx(ii),:));
    thisVisCoord = [ eccenMap(validIdx(ii)) .* cosd(angleMap(validIdx(ii))), ...
                     eccenMap(validIdx(ii)) .* sind(angleMap(validIdx(ii)))];

    distancesMm = sqrt(sum((vert(neighborIdx,:)-thisCortCoord).^2,2));
    distancesDeg = vecnorm(thisVisCoord - ...
    [ eccenMap(neighborIdx) .* cosd(angleMap(neighborIdx)), ...
                     eccenMap(neighborIdx) .* sind(angleMap(neighborIdx))],2,2);
    cmfMap(validIdx(ii)) = nanmean(nanmean(distancesDeg./distancesMm));
end

% Replace the nans with zeros
cmfMap(isnan(cmfMap))=0;

mapPathOut = fullfile(outPath,[p.Results.hemisphere '.' Subject '.cmf.mgz']);
save_mgh(reshape(cmfMap,volsz), mapPathOut, M, mr_parms);

    fig = makeSurfMap(mapPathOut,surfPath, ...
        'mapScale','logJet', ...
        'mapBounds',[0.1 10], ...
        'hemisphere','rh','visible',true);


end % Main function
