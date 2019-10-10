function renderInferredMaps(inferredMapsDirPath, surfPath, outPath)
%
%
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
p.addRequired('surfPath',@isstr);
p.addRequired('outPath',@isstr);

% Parse
p.parse(inferredMapsDirPath, surfPath, outPath)




%% Save map images
mapSet = {'eccen','angle','sigma','varea'};
mapTypes = {'ecc','pol','sigma','varea'};
for mm = 1:length(mapSet)
    dataPath = fullfile(inferredMapsDirPath,['rh.inferred_' mapSet{mm} '.mgz']);
    fig = saveSurfMap(dataPath,surfPath, ...
        'mapType',mapTypes{mm}, ...
        'maxEccentricity', 90, ...
        'hemisphere','rh','visible',false);
    plotFileName = fullfile(outPath,['rh.inferred_' mapSet{mm} '.png']);
    print(fig,plotFileName,'-dpng')
end


end % Main function
