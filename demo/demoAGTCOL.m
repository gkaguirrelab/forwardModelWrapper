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
subjectName = 'MELA_5001';

% Create the functional tmp save dir if it does not exist
saveDir = fullfile(scratchSaveDir,'v0','input','funcZip');
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end


% TR of the acquisition in seconds
tr = '0.8';

% The degree of polynomial to use to remove low-freq trends from the data
polyDeg = '13';

% Process just this one voxel
vxsPass = [52153];

% Flag to average the acquisitions together before computing pRF
% parameters. This makes the operation faster.
averageAcquisitions = '0';
averageVoxels = '0';


%% Open the flywheel object
fw = flywheel.Flywheel(getpref(projectName,'flywheelAPIKey'));


%% Download the stim file
projectID = '60ae28a77d5d3e03ef2a8716';
fileName = 'MELA_5002_LeftEyeStim_stim.mat';
stimFilePath = fullfile(saveDir,fileName);
fw.downloadFileFromProject(projectID,fileName,stimFilePath);


%% Download the functional data inputs
% To find these, get the ID for the session (which is in the URL of the web
% GUI, and then use this command to get a list of the analyses associated
% with that session, and then find the analysis ID the we want.
%
%{
    projectName = 'forwardModelWrapper';
    fw = flywheel.Flywheel(getpref(projectName,'flywheelAPIKey'));
    sessionID = '60be0db23964cfd4be98227c';
    analysisList = fw.getSessionAnalyses(sessionID);
%}

% The two ICA FIX outputs
analysisIDs = {'60bf7c310c56657de23d07ee','60bf7c3a7e735624fa3d068c'};
fileNames = {...
    'MELA_5002_ICAFIX_multi_LStim_A_01_LStim_B_02_LStim_A_03_LStim_B_04_LStim_A_05_hcpicafix.zip',...
    'MELA_5002_ICAFIX_multi_LStim_B_06_LStim_A_07_LStim_B_08_LStim_A_09_LStim_B_10_hcpicafix.zip' ...
    };

for ff=1:length(analysisIDs)
    tmpPath = fullfile(saveDir,fileNames{ff});
    if ~isfile(tmpPath)
        fw.downloadOutputFromAnalysis(analysisIDs{ff},fileNames{ff},tmpPath);
    end
    command = sprintf('funcZipPath%02d = tmpPath',ff);
    eval(command);
end


%% Additional settings

% Internal paths
workbenchPath = getpref(projectName,'wbCommand');
outPath = fullfile(scratchSaveDir,'v0','output');
if ~exist(outPath,'dir')
    mkdir(outPath);
end

% Path to the external python routine that converts map formats
externalMGZMakerPath = fullfile(getpref('forwardModelWrapper','projectBaseDir'),'code','make_fsaverage.py');

% Path to the external python routine that converts map formats
externalCiftiToFreesurferPath = fullfile(getpref('forwardModelWrapper','projectBaseDir'),'code','cifti_to_freesurfer.py');

% CIFTI atlases
standardMeshAtlasesFolder = fullfile(getpref('forwardModelWrapper','projectBaseDir'),'code','utilities','standard_mesh_atlases');


freesurferInstallationPath = '/Applications/freesurfer/';

workDir = outPath;

% Assemble the modelOpts
modelOpts = ['{' ...
    ' ''polyDeg'',' polyDeg ',' ...
    ' ''stimLabels'',{''LminusM'',''LMS'',''S'',''omni'',''baseline'',''attention''},',...
    ' ''confoundStimLabel'',''attention'',', ...
    ' ''avgAcqIdx'', {1:500,501:1000,1001:1500,1501:2000,2001:2500}', ...
    '}'];

%% Call the main routine
mainWrapper(funcZipPath01,funcZipPath02,'Na','Na', ...
    'Na','Na','Na','Na', ...
    'Na','Na','Na','Na', ...
    'Na','Na','Na', stimFilePath, 'Na', ...
    'dataFileType','cifti', ...
    'dataSourceType','icafix', ...
    'averageAcquisitions',averageAcquisitions, ...
    'averageVoxels',averageVoxels, ...
    'vxsPass', vxsPass, ...
    'tr',tr, ...
    'modelClass','agtcOL', ...
    'modelOpts',modelOpts, ...
    'Subject',subjectName,...
    'workbenchPath',workbenchPath, ...
    'externalMGZMakerPath', externalMGZMakerPath, ...
    'externalCiftiToFreesurferPath', externalCiftiToFreesurferPath, ...
    'standardMeshAtlasesFolder', standardMeshAtlasesFolder, ...
    'freesurferInstallationPath', freesurferInstallationPath, ...
    'workDir', workDir, ...
    'outPath',outPath);

