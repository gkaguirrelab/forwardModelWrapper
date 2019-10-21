function [hcpStructPath,subjectName,nativeSpaceDirPath,pseudoHemiDirPath]=mainPRF(funcZipPath, stimFilePath, structZipPath, varargin)
% When compiled, is called by the python run function in the gear
%
% Syntax:
%  mainPRF
%
% Description



%% Parse inputs
p = inputParser; p.KeepUnmatched = false;

% Required
p.addRequired('funcZipPath',@isstr);
p.addRequired('stimFilePath',@isstr);
p.addRequired('structZipPath',@isstr);

% Optional inputs
p.addParameter('maskFilePath', 'Na', @isstr)
p.addParameter('hrfFilePath', 'Na', @isstr)

% Config options - multiple
p.addParameter('dataFileType', 'cifti', @isstr)

% Config options - pre-process
p.addParameter('dataSourceType', 'icafix', @isstr)
p.addParameter('trimDummyStimTRs', '0', @isstr)
p.addParameter('averageAcquisitions', '0', @isstr)

% Config options - wrapper
p.addParameter('tr',[],@isstr);
p.addParameter('wantglmdenoise','0',@isstr);
p.addParameter('maxpolydeg','Na',@isstr);
p.addParameter('seedmode','[0 1 2]',@isstr);
p.addParameter('xvalmode','0',@isstr);
p.addParameter('maxiter','500',@isstr);
p.addParameter('typicalgain','10',@isstr);

% Config options - post-process
p.addParameter('pixelsPerDegree', 'Na', @isstr)
p.addParameter('screenMagnification', '1.0', @isstr)

% Config options - convert to mgz
p.addParameter('externalMGZMakerPath', [], @isstr)
p.addParameter('RegName', 'FS', @isstr)

% Config options - demo over-ride
p.addParameter('vxsPass', [], @isnumeric)

% Internal paths
p.addParameter('workbenchPath', '', @isstr);
p.addParameter('outPath', '', @isstr);


% Parse
p.parse(funcZipPath, stimFilePath, structZipPath, varargin{:})



%% AnalyzePRFPreprocess
[stimulus, data, vxs, templateImage] = ...
    preprocessPRF(p.Results.workbenchPath, funcZipPath, stimFilePath, ...
    'maskFilePath',p.Results.maskFilePath, ...
    'averageAcquisitions',p.Results.averageAcquisitions);

% If vxsPass has been defined (perhaps by the demo routine), substitute
% this value for vxs
if ~isempty(p.Results.vxsPass)
    vxs = p.Results.vxsPass;
end

% If the hrfFilePath has been defined, load it
if ~strcmp(p.Results.hrfFilePath,'Na')
    load(p.Results.hrfFilePath,'hrf');
else
    hrf = [];
end


%% Start the parpool
startParpool;


%% wrapperPRF
results = analyzePRF(stimulus,data,'vxs',vxs,'tr',0.8);

% results = wrapperPRF(stimulus, data, vxs, ...
%     'tr',p.Results.tr,...
%     'hrf',hrf,...
%     'wantglmdenoise',p.Results.wantglmdenoise,...
%     'maxpolydeg',p.Results.maxpolydeg,...
%     'seedmode',p.Results.seedmode,...
%     'xvalmode',p.Results.xvalmode,...
%     'maxiter',p.Results.maxiter,...
%     'typicalgain',p.Results.typicalgain);

% Process and save the results
[modifiedResults, mapsPath] = postprocessPRF(...
    results, templateImage, p.Results.outPath, p.Results.workbenchPath,...
    'dataFileType', p.Results.dataFileType, ...
    'pixelsPerDegree', p.Results.pixelsPerDegree, ...
    'screenMagnification', p.Results.screenMagnification);

% Create and save some plots
plotPRF(modifiedResults,data,p.Results.outPath)


%% Convert to MGZ
% If we are working with CIFTI files, convert the resulting maps to
% native-space MGZ images. These files can then serve as input to the
% neuropythy Bayesian fitting routine.

if strcmp(p.Results.dataFileType,'cifti')
    % Uncompress the structZip into the dir that holds the zip. We do this
    % with a system call so that we can prevent over-writing a prior unzipped
    % version of the data (which can happen in demo mode).
    command = ['unzip -q -n ' structZipPath ' -d ' fileparts(structZipPath)];
    system(command);
    
    % Find the directory that is produced by this unzip operation
    fileList = dir(fileparts(structZipPath));
    fileList = fileList(...
        cellfun(@(x) ~startsWith(x,'.'),extractfield(fileList,'name')) ...
        );
    fileList = fileList(cell2mat(extractfield(fileList,'isdir')));
    hcpStructPath = fullfile(fileList.folder,fileList.name);
    subjectName = fileList.name;
    
    % Create directories for the output files
    nativeSpaceDirPath = fullfile(p.Results.outPath, 'maps_nativeMGZ');
    if ~exist(nativeSpaceDirPath,'dir')
        mkdir(nativeSpaceDirPath);
    end
    pseudoHemiDirPath = fullfile(p.Results.outPath, 'maps_nativeMGZ_pseudoHemisphere');
    if ~exist(pseudoHemiDirPath,'dir')
        mkdir(pseudoHemiDirPath);
    end
    
    % Perform the call and report if an error occurred
    command =  ['python3 ' p.Results.externalMGZMakerPath ' ' mapsPath ' ' hcpStructPath ' ' p.Results.RegName ' ' nativeSpaceDirPath ' ' pseudoHemiDirPath];
    callErrorStatus = system(command);
    if callErrorStatus
        warning('An error occurred during execution of the external Python function for map conversion');
    end
end


%% Save rh map images
surfPath = fullfile(hcpStructPath,'T1w',subjectName,'surf');
for mm = 1:length(modifiedResults.mapType)
    dataPath = fullfile(nativeSpaceDirPath,['R_' modifiedResults.mapType{mm} '_map.mgz']);
    fig = makeSurfMap(dataPath,surfPath, ...
        'mapScale',modifiedResults.mapType{mm}, ...
        'mapLabel',modifiedResults.mapLabel{mm}, ...
        'mapBounds',modifiedResults.mapBounds{mm}, ...
        'hemisphere','rh','visible',false);
    plotFileName = fullfile(p.Results.outPath,['rh.' mapSet{mm} '.png']);
    print(fig,plotFileName,'-dpng')
    close(fig);
end

%% Save lh map images
mapSet = {'eccentricity','angle','R2','rfsize','hrfshift','gain','exponent'};
mapTypes = {'ecc','pol','rsquared','sigma','hrfshift','gain','exponent'};
surfPath = fullfile(hcpStructPath,'T1w',subjectName,'surf');
for mm = 1:length(mapSet)
    dataPath = fullfile(nativeSpaceDirPath,['L_' mapSet{mm} '_map.mgz']);
    fig = makeSurfMap(dataPath,surfPath, ...
        'mapType',mapTypes{mm}, ...
        'hemisphere','lh','visible',false);
    plotFileName = fullfile(p.Results.outPath,['lh.' mapSet{mm} '.png']);
    print(fig,plotFileName,'-dpng')
    close(fig);
end


end % Main function
