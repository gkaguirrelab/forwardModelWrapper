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
    
    % Find all valid vertices
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
    
    mapPathOut = fullfile(inferredMapsDirPath,[hemi{hh} '.' Subject '_inferred_cmf.mgz']);
    save_mgh(reshape(cmfMap,volsz), mapPathOut, M, mr_parms);
    
    % Create an image of the cortical magnification values
    mapFigHandle = makeSurfMap(mapPathOut,surfPath, ...
        'mapLabel','M^-1 [deg/mm]', ...
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
        results.(ROIs{rr}).(hemi{hh}).eccen = eccenMap(validIdx);
        results.(ROIs{rr}).(hemi{hh}).cmf = cmfMap(validIdx);
        [m,b] = TheilSen([eccenMap(validIdx), cmfMap(validIdx)]);
        results.(ROIs{rr}).(hemi{hh}).fit = [m, b];
        
        set(0, 'CurrentFigure', plotFigHandle)        
        subplot(2,2,hh+((rr-1)*2))
        hplot = scatter(eccenMap(validIdx),cmfMap(validIdx),'o','MarkerFaceColor','k','MarkerEdgeColor','none');
        hplot.MarkerFaceAlpha = .1;
        hold on
        hline = refline([m,b]);
        hline.Color = 'r';
        hline.LineWidth = 2;
        xlabel('eccentricty [deg]');
        ylabel('M^-^1 [deg/mm]');
        title([Subject '.' ROIs{rr} '.' hemi{hh}],'interpreter', 'none');
        xlim([0 10]);
        ylim([0 2]);
        
    end % loop over regions
    
end % Loop over hemispheres

% Save the plot figure
plotFileName = fullfile(outPath,[Subject '_cmfPlots.pdf']);
print(plotFigHandle,plotFileName,'-dpdf')
close(plotFigHandle);

% Save the results variable
resultsFileName = fullfile(outPath,[Subject '_cmfResults.mat']);
save(resultsFileName,'results');

end % Main function
