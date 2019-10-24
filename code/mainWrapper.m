function [hcpStructPath,subjectName,nativeSpaceDirPath,pseudoHemiDirPath]=mainWrapper(funcZipPath, stimFilePath, structZipPath, varargin)
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
p.addParameter('payloadPath', 'Na', @isstr)

% Config options - multiple
p.addParameter('dataFileType', 'cifti', @isstr)

% Config options - pre-process
p.addParameter('dataSourceType', 'icafix', @isstr)
p.addParameter('trimDummyStimTRs', '0', @isstr)
p.addParameter('averageAcquisitions', '0', @isstr)

% Config options - forwardModel
p.addParameter('modelClass','pRF_timeShift',@isstr);
p.addParameter('modelOpts','{}',@isstr);
p.addParameter('tr',[],@isstr);

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


%% Parse the modelOpts string
% modelOpts may be passed in with parens substituted for single quotes. We
% replace those here.
modelOpts = p.Results.modelOpts;
modelOpts = strrep(modelOpts,'(','''');
modelOpts = strrep(modelOpts,')','''');


%% Preprocess
[stimulus, data, vxs, templateImage] = ...
    handleInputs(p.Results.workbenchPath, funcZipPath, stimFilePath, ...
    'maskFilePath',p.Results.maskFilePath, ...
    'averageAcquisitions',p.Results.averageAcquisitions);

% If vxsPass has been defined (perhaps by the demo routine), substitute
% this value for vxs
if ~isempty(p.Results.vxsPass)
    vxs = p.Results.vxsPass;
end


%% Start the parpool
startParpool;


%% forwardModel

% Load the payload
if ~strcmp(p.Results.payloadPath,'Na')
    load(p.Results.payloadPath,'payload');
else
    payload = {};
end

% Call the model
results = forwardModel(data,stimulus,str2double(p.Results.tr),...
    'modelClass', p.Results.modelClass, ...
    'modelOpts', eval(modelOpts), ...
    'modelPayload', payload, ...
    'vxs', vxs);

% Process and save the results
mapsPath = handleOutputs(...
    results, templateImage, p.Results.outPath, p.Results.workbenchPath,...
    'dataFileType', p.Results.dataFileType);

% Create and save some plots
if strcmp(p.Results.modelClass,'pRF_timeShift')
    plotPRF(results,data,p.Results.outPath)
end

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
for mm = 1:length(results.meta.mapField)
    dataPath = fullfile(nativeSpaceDirPath,['R_' results.meta.mapField{mm} '_map.mgz']);
    fig = makeSurfMap(dataPath,surfPath, ...
        'mapScale',results.meta.mapScale{mm}, ...
        'mapLabel',results.meta.mapLabel{mm}, ...
        'mapBounds',results.meta.mapBounds{mm}, ...
        'hemisphere','rh','visible',false);
    plotFileName = fullfile(p.Results.outPath,['rh.' results.meta.mapField{mm} '.png']);
    print(fig,plotFileName,'-dpng')
    close(fig);
end

%% Save lh map images
surfPath = fullfile(hcpStructPath,'T1w',subjectName,'surf');
for mm = 1:length(results.meta.mapField)
    dataPath = fullfile(nativeSpaceDirPath,['L_' results.meta.mapField{mm} '_map.mgz']);
    fig = makeSurfMap(dataPath,surfPath, ...
        'mapScale',results.meta.mapScale{mm}, ...
        'mapLabel',results.meta.mapLabel{mm}, ...
        'mapBounds',results.meta.mapBounds{mm}, ...
        'hemisphere','lh','visible',false);
    plotFileName = fullfile(p.Results.outPath,['lh.' results.meta.mapField{mm} '.png']);
    print(fig,plotFileName,'-dpng')
    close(fig);
end


end % Main function
