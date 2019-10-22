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




%% Save rh map images
mapField = {'eccen','angle','sigma','varea'};
mapScale = {'eccen','angle','logJet','varea'};
for mm = 1:length(mapField)
    dataPath = fullfile(inferredMapsDirPath,['rh.inferred_' mapField{mm} '.mgz']);
    fig = makeSurfMap(dataPath,surfPath, ...
        'mapType',mapScale{mm}, ...
        'hemisphere','rh','visible',false);
    plotFileName = fullfile(outPath,['rh.inferred_' mapField{mm} '.png']);
    print(fig,plotFileName,'-dpng')
    close(fig);
end

%% Save lh map images
mapField = {'eccen','angle','sigma','varea'};
mapScale = {'eccen','angle','logJet','varea'};
for mm = 1:length(mapField)
    dataPath = fullfile(inferredMapsDirPath,['lh.inferred_' mapField{mm} '.mgz']);
    fig = makeSurfMap(dataPath,surfPath, ...
        'mapType',mapScale{mm}, ...
        'hemisphere','lh','visible',false);
    plotFileName = fullfile(outPath,['lh.inferred_' mapField{mm} '.png']);
    print(fig,plotFileName,'-dpng')
    close(fig);
end


end % Main function
