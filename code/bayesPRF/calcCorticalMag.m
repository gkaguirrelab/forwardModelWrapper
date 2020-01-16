function calcCorticalMag(Subject, inferredMapsDirPath, surfPath, outPath, varargin)
%
%
%
% Examples:
%{
    inferredMapsDirPath = '/tmp/flywheel/v0/output/TOME_3045_inferred_surface/';
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
p.addParameter('whichSurface','white',@ischar); % pial, white, or sphere

% Parse
p.parse(Subject, inferredMapsDirPath, surfPath, outPath, varargin{:})


% Prepare a figue to hold some plots
plotFigHandle = figure('visible','off');

%% Loop over hemispheres
hemi = {'lh','rh'};

for hh = 1:2
    
    % Load surface files
    surfName = fullfile(surfPath,[hemi{hh} '.' p.Results.whichSurface]);
    [vert,face] = freesurfer_read_surf(surfName);
    
    % Load map data file
    mapPath = fullfile(inferredMapsDirPath,[hemi{hh} '.' Subject '_inferred_angle.mgz']);
    angleMap = squeeze(load_mgh(mapPath));
    
    mapPath = fullfile(inferredMapsDirPath,[hemi{hh} '.' Subject '_inferred_eccen.mgz']);
    eccenMap = squeeze(load_mgh(mapPath));
    
    mapPath = fullfile(inferredMapsDirPath,[hemi{hh} '.' Subject '_inferred_varea.mgz']);
    [vareaMap, M, mr_parms, volsz] = load_mgh(mapPath);
    vareaMap = squeeze(vareaMap);
    
    % Cacluate the surface area for each visual region
    for rr = 1:max(vareaMap)
        vertIdx = find(vareaMap==rr);
        sa(rr) = calcSurfaceArea(vert,face,vertIdx);
    end
    results.(hemi{hh}).surfaceHemisphere = calcSurfaceArea(vert,face,1:size(vert,1));
    results.(hemi{hh}).surfaceAreas = sa;
    
    % Find all vertices that are assigned to a visual area map
    validIdx = find(vareaMap~=0);
    
    % Create a map of cortical magnification
    cmfMap = nan(size(vareaMap));

    % Loop over valid vertices
    for ii=1:length(validIdx)
        
        % The current vertex for which we are making the caclculation
        thisIdx = validIdx(ii);
        
        % Find the vertices that are adjcent to the current vertex (but are
        % not themselves the current vertex)
        neighborIdx = unique(face(any((face==thisIdx)'),:));
        neighborIdx = neighborIdx(neighborIdx~=thisIdx);
        
        % The Cartesian location within the brain of the current vertex
        thisCortCoord = squeeze(vert(thisIdx,:));
        
        % The x and y visual field position for the current vertex
        thisVisCoord = [ eccenMap(thisIdx) .* cosd(angleMap(thisIdx)), ...
            eccenMap(thisIdx) .* sind(angleMap(thisIdx))];
        
        % The pairwise distances between each neighbor vertex and the
        % current vertex, in units of brain mm and visual field degrees
        distancesMm = sqrt(sum((vert(neighborIdx,:)-thisCortCoord).^2,2));
        distancesDeg = vecnorm(thisVisCoord - ...
            [ eccenMap(neighborIdx) .* cosd(angleMap(neighborIdx)), ...
            eccenMap(neighborIdx) .* sind(angleMap(neighborIdx))],2,2);
        
        % The cortical magnification is the mean deg/mm at that point
        cmfMap(thisIdx) = nanmean(nanmean(distancesDeg./distancesMm));
    end
    
    % Replace the nans with zeros
    cmfMap(isnan(cmfMap))=0;
    
    mapPathOut = fullfile(inferredMapsDirPath,[hemi{hh} '.' Subject '_inferred_cmf.mgz']);
    save_mgh(reshape(cmfMap,volsz), mapPathOut, M, mr_parms);
    
    % Create an image of the cortical magnification values
    mapFigHandle = makeSurfMap(mapPathOut,surfPath, ...
        'mapLabel','M^{-1} [deg/mm]', ...
        'mapScale','logJet', ...
        'mapBounds',[0.01 10], ...
        'hemisphere',hemi{hh},'visible',false);
    plotFileName = fullfile(outPath,[hemi{hh} '.' Subject '_cmf.png']);
    print(mapFigHandle,plotFileName,'-dpng')
    close(mapFigHandle);
        
    % Obtain the CMF for V1, and for V2/V3, and make a figure
    ROIs = {'v1','v2v3'};
    for rr = 1:2
        if rr==1
            validIdx = logical( double(vareaMap==1) .* double(eccenMap<=10));
        else
            validIdx = logical(double(xor(vareaMap==2,vareaMap==3)) .* double(eccenMap<=10));
        end
        results.(hemi{hh}).(ROIs{rr}).eccen = eccenMap(validIdx);
        results.(hemi{hh}).(ROIs{rr}).cmf = cmfMap(validIdx);
        [m,b] = TheilSen([eccenMap(validIdx), cmfMap(validIdx)]);
        results.(hemi{hh}).(ROIs{rr}).fit = [m, b];
        
        set(0, 'CurrentFigure', plotFigHandle)        
        subplot(2,2,hh+((rr-1)*2))
        hplot = scatter(eccenMap(validIdx),cmfMap(validIdx),'o','MarkerFaceColor','k','MarkerEdgeColor','none');
        hplot.MarkerFaceAlpha = 0.1;
        hold on
        hline = refline([m,b]);
        hline.Color = 'r';
        hline.LineWidth = 2;
        xlabel('eccentricty [deg]');
        ylabel('M^{-1} [deg/mm]');
        title([Subject '.' ROIs{rr} '.' hemi{hh}],'interpreter', 'none');
        xlim([0 10]);
        ylim([0 2]);
        
    end % loop over regions
    
end % Loop over hemispheres

% Save the plot figure
plotFileName = fullfile(outPath,[Subject '_cmfPlots.pdf']);
print(plotFigHandle,plotFileName,'-dpdf','-fillpage')
close(plotFigHandle);

% Save the results variable
resultsFileName = fullfile(outPath,[Subject '_cmfResults.mat']);
save(resultsFileName,'results');

end % Main function



%% LOCAL FUNCTIONS

function surfaceArea = calcSurfaceArea(vert,face,vertIdx)

% Find the faces that are composed entirely of vertices in the index
faceIdx = find(all(ismember(face,vertIdx)'));

v1 = vert(face(faceIdx,2),:)-vert(face(faceIdx,1),:);
v2 = vert(face(faceIdx,3),:)-vert(face(faceIdx,2),:);
cp = 0.5*cross(v1,v2);
surfaceAreaAll = sum(sqrt(dot(cp,cp,2)));

% Find the faces that are composed of any vertices in the index
faceIdx = find(any(ismember(face,vertIdx)'));

v1 = vert(face(faceIdx,2),:)-vert(face(faceIdx,1),:);
v2 = vert(face(faceIdx,3),:)-vert(face(faceIdx,2),:);
cp = 0.5*cross(v1,v2);
surfaceAreaAny = sum(sqrt(dot(cp,cp,2)));

% Report the average of these two
surfaceArea = (surfaceAreaAll+surfaceAreaAny)/2;

end
