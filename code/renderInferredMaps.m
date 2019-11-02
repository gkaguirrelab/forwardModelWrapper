function renderInferredMaps(inferredMapsDirPath, Subject, surfPath, outPath)
% Used to create rendered images of the maps produced by bayesPRF
%
% Syntax:
%  renderInferredMaps(inferredMapsDirPath, Subject, surfPath, outPath)
%
% Description:
%   The Flywheel gear bayesPRF returns a set of MGZ files that describe
%   retinotopic organization of visual cortex. This routine creates images
%   of these maps.
%
% Examples:
%{
    surfPath = fullfile(hcpStructPath,'T1w',subjectName,'surf');
    renderInferredMaps(inferredMapsDirPath, surfPath, outPath)
%}

%% Parse inputs
p = inputParser; p.KeepUnmatched = false;

% Required
p.addRequired('inferredMapsDirPath',@isstr);
p.addRequired('Subject', @isstr)
p.addRequired('surfPath',@isstr);
p.addRequired('outPath',@isstr);

% Parse
p.parse(inferredMapsDirPath, surfPath, outPath)



%% The maps to save
mapField = {'eccen','angle','sigma','varea'};
mapScale = {'eccen','angle','logJet','varea'};
mapBounds = {[1 90],[-180 180],[0 10],[]};

%% Save rh map images
for mm = 1:length(mapField)
    dataPath = fullfile(inferredMapsDirPath,['rh.' Subject '_inferred_' mapField{mm} '.mgz']);
    fig = makeSurfMap(dataPath,surfPath, ...
        'mapType',mapScale{mm}, ...
        'mapBounds',mapBounds{mm}, ...
        'hemisphere','rh','visible',false);
    plotFileName = fullfile(outPath,['rh.' Subject '_inferred_' mapField{mm} '.png']);
    print(fig,plotFileName,'-dpng')
    close(fig);
end

%% Save lh map images
mapField = {'eccen','angle','sigma','varea'};
mapScale = {'eccen','angle','logJet','varea'};
for mm = 1:length(mapField)
    dataPath = fullfile(inferredMapsDirPath,['lh.' Subject '_inferred_' mapField{mm} '.mgz']);
    fig = makeSurfMap(dataPath,surfPath, ...
        'mapType',mapScale{mm}, ...
        'mapBounds',mapBounds{mm}, ...
        'hemisphere','lh','visible',false);
    plotFileName = fullfile(outPath,['lh.' Subject '_inferred_' mapField{mm} '.png']);
    print(fig,plotFileName,'-dpng')
    close(fig);
end


end % Main function
