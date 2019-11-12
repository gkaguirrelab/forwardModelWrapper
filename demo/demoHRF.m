% DEMO_AnalyzeHRF
%
% This routine downloads ICAFIX and hcp-struct data from flywheel and then
% submits the files for analysis


% Clear out variables from the workspace, as we will be passing these
% within the workspace to mainPRF
clear


% Set this to true to quickly process a single voxel (seconds), vs.
% analyzing the entire V1 region (minutes)
doOneVoxel = false;


%% Variable declaration
projectName = 'forwardModelWrapper';
scratchSaveDir = getpref(projectName,'flywheelScratchDir');
subjectName = 'TOME_3045';

% TR of the acquisition in seconds
tr = '0.8';

% The typical amplitude of the BOLD fMRI response
typicalGain = '300';

polyDeg = '13';

% Flag to average the acquisitions together before computing pRF
% parameters. This makes the operation faster.
averageAcquisitions = '1';



%% Download the functional data
outputFileSuffix = '_hcpicafix.zip';

% Create the functional tmp save dir if it does not exist
saveDir = fullfile(scratchSaveDir,'v0','input','funcZip');
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

% Create a flywheel object
fw = flywheel.Flywheel(getpref(projectName,'flywheelAPIKey'));

% The ica-fix results for the RETINO data for one subject
searchStruct = struct(...
    'returnType', 'analysis', ...
    'filters', {{...
    struct('match', struct('analysis0x2elabel', 'icafix')), ...
    struct('match', struct('analysis0x2elabel', 'FLASH')), ...
    struct('match', struct('project0x2elabel', 'tome')), ...
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
    struct('match', struct('project0x2elabel', 'tome')), ...
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
stimFilePath = fullfile(getpref(projectName,'projectBaseDir'),'demo','flashStimulus_1x1x450.mat');

% Optional input
maskFilePath = fullfile(getpref(projectName,'projectBaseDir'),'demo','lh.V1mask.dscalar.nii');

% Internal paths
workbenchPath = getpref(projectName,'wbCommand');
outPath = fullfile(scratchSaveDir,'v0','output');
if ~exist(outPath,'dir')
    mkdir(outPath);
end


% Setup processing one or all voxels
if doOneVoxel
    % Process one voxel that has a great fit
    vxsPass = 52153;
else
    vxsPass = [];
end

% Path to the external python routine that converts map formats
externalMGZMakerPath = fullfile(getpref('forwardModelWrapper','projectBaseDir'),'code','make_fsaverage.py');


% Assemble the modelOpts
modelOpts = ['{' ...
               ' ''typicalGain'',' typicalGain ',' ...
               ' ''polyDeg'',' polyDeg ...
               '}'];

%% Call the main routine
mainWrapper(funcZipPath,'Na','Na','Na','Na', stimFilePath, structZipPath, ...
    'maskFilePath',maskFilePath, ...
    'averageAcquisitions',averageAcquisitions, ...
    'tr',tr, ...
    'modelClass','flobsHRF', ...
    'modelOpts',modelOpts, ...
    'Subject',subjectName,...
    'workbenchPath',workbenchPath, ...
    'externalMGZMakerPath', externalMGZMakerPath, ...
    'outPath',outPath, ...
    'vxsPass', vxsPass);

