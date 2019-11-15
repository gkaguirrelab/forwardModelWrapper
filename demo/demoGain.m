% DEMO_eventGain
%
% This routine downloads ICAFIX and hcp-struct data from flywheel and then
% submits the files for analysis


% Clear out variables from the workspace, as we will be passing these
% within the workspace to mainPRF
clear




%% Variable declaration
projectName = 'forwardModelWrapper';
scratchSaveDir = getpref(projectName,'flywheelScratchDir');
subjectName = 'KAS25';

% The type of HRF model to fit
hrfType = '''gamma''';
hrfSearch = 'false';

% TR of the acquisition in seconds
tr = '0.8';

% The typical amplitude of the BOLD fMRI response
typicalGain = '300';

% The degree of polynomial to use to remove low-freq trends from the data
polyDeg = '5';

% Flag to average the acquisitions together before computing pRF
% parameters. This makes the operation faster.
averageAcquisitions = '0';
averageVoxels = '1';


%% Download the functional data
outputFileSuffix = '_hcpicafix.zip';

% Create the functional tmp save dir if it does not exist
saveDir = fullfile(scratchSaveDir,'v0','input','funcZip');
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

% Create a flywheel object
fw = flywheel.Flywheel(getpref(projectName,'flywheelAPIKey'));

% The ica-fix results for one subject
searchStruct = struct(...
    'returnType', 'analysis', ...
    'filters', {{...
    struct('match', struct('project0x2elabel', 'LFContrast')), ...
    struct('match', struct('subject0x2ecode', subjectName)), ...
    struct('match', struct('session0x2elabel', 'Research^Aguirre')), ...
    struct('match', struct('session0x2elabel', '1')), ...
    struct('match', struct('analysis0x2elabel', 'ica')), ...
    struct('match', struct('analysis0x2elabel', '_1')), ...
    }} ...
    );
analyses = fw.search(searchStruct);

% We should only find one analysis result for this search
if length(analyses)~=1
    error('Search failed to find a unique analysis')
end

% Get the analysis object
thisAnalysis = fw.getAnalysis(analyses{1}.analysis.id);

% Find the file with the matching stem
analysisFileMatchIdx = cellfun(@(x) endsWith(x.name,outputFileSuffix),thisAnalysis.files);

% Get some more information about the analysis and define a saveStem
thisName = thisAnalysis.files{analysisFileMatchIdx}.name;
saveName = fullfile(saveDir,thisName);

% If the file has not already been downloaded, get it
if ~exist(saveName,'file')    
    % Inform the user
    fprintf(['Downloading: ' thisName '\n']);
    fprintf(['         to: ' saveDir '\n']);
    
    % Download the matching file to the rootSaveDir. This can take a while
    fw.downloadOutputFromAnalysis(thisAnalysis.id,thisName,saveName);        
end

% The name to be passed to the wrapper
funcZipPath = saveName;


%% Download the structural data
outputFileSuffix = '_hcpstruct.zip';

% Create the save dir if it does not exist
saveDir = fullfile(scratchSaveDir,'v0','input','structZip');
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

% Create a flywheel object
fw = flywheel.Flywheel(getpref(projectName,'flywheelAPIKey'));

% The ica-fix results for the RETINO data for one subject
searchStruct = struct(...
    'returnType', 'analysis', ...
    'filters', {{...
    struct('match', struct('analysis0x2elabel', 'hcp')), ...
    struct('match', struct('analysis0x2elabel', 'struct')), ...
    struct('match', struct('project0x2elabel', 'LFContrast')), ...
    struct('match', struct('subject0x2ecode', subjectName)), ...
    }} ...
    );
analyses = fw.search(searchStruct);

% We should only find one analysis result for this search
if length(analyses)~=1
    error('Search failed to find a unique analysis')
end

% Get the analysis object
thisAnalysis = fw.getAnalysis(analyses{1}.analysis.id);

% Find the file with the matching stem
analysisFileMatchIdx = cellfun(@(x) endsWith(x.name,outputFileSuffix),thisAnalysis.files);

% Get some more information about the analysis and define a saveStem
thisName = thisAnalysis.files{analysisFileMatchIdx}.name;
saveName = fullfile(saveDir,thisName);

% If the file has not already been downloaded, get it
if ~exist(saveName,'file')    
    % Inform the user
    fprintf(['Downloading: ' thisName '\n']);
    fprintf(['         to: ' saveDir '\n']);
    
    % Download the matching file to the rootSaveDir. This can take a while
    fw.downloadOutputFromAnalysis(thisAnalysis.id,thisName,saveName);
end

% The name to be passed to the wrapper
structZipPath = saveName;

%% Additional settings

% Required input
stimFilePath = fullfile(getpref(projectName,'projectBaseDir'),'demo','KAS25_sess1_acq1-5.mat');

% Optional input
maskFilePath = fullfile(getpref(projectName,'projectBaseDir'),'demo','V1_combined_ecc_0_to_20.dscalar.nii');

% Internal paths
workbenchPath = getpref(projectName,'wbCommand');
outPath = fullfile(scratchSaveDir,'v0','output');
if ~exist(outPath,'dir')
    mkdir(outPath);
end

% Path to the external python routine that converts map formats
externalMGZMakerPath = fullfile(getpref('forwardModelWrapper','projectBaseDir'),'code','make_fsaverage.py');


% Assemble the modelOpts
modelOpts = ['{' ...
               ' ''typicalGain'',' typicalGain ',' ...
               ' ''polyDeg'',' polyDeg ',' ...
               ' ''hrfType'', ' hrfType ',' ...
               ' ''hrfSearch'', ' hrfSearch ...
               '}'];

%% Call the main routine
mainWrapper(funcZipPath,'Na','Na','Na','Na', stimFilePath, structZipPath, ...
    'maskFilePath',maskFilePath, ...
    'averageAcquisitions',averageAcquisitions, ...
    'averageVoxels',averageVoxels, ...
    'tr',tr, ...
    'modelClass','eventGain', ...
    'modelOpts',modelOpts, ...
    'Subject',subjectName,...
    'workbenchPath',workbenchPath, ...
    'externalMGZMakerPath', externalMGZMakerPath, ...
    'outPath',outPath);

