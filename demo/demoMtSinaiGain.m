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
subjectName = 'HEROgka1';

% Create the functional tmp save dir if it does not exist
saveDir = fullfile(scratchSaveDir,'v0','input','funcZip');
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end


% TR of the acquisition in seconds
tr = '0.8';

% The degree of polynomial to use to remove low-freq trends from the data
polyDeg = '14';

% Flag to average the acquisitions together before computing pRF
% parameters. This makes the operation faster.
averageAcquisitions = '0';
averageVoxels = '1';


%% Open the flywheel object
fw = flywheel.Flywheel(getpref(projectName,'flywheelAPIKey'));


%% Download the stim file
projectID = '5ca7803af546b60029ef118e';
fileName = 'stimulus_HERO_gka1_LightFlux.mat';
stimFilePath = fullfile(saveDir,fileName);
fw.downloadFileFromProject(projectID,fileName,stimFilePath);


%% Download the mask file
projectID = '5ca7803af546b60029ef118e';
fileName = 'bothHemisEccen.dtseries.nii';
maskFilePath = fullfile(saveDir,fileName);
fw.downloadFileFromProject(projectID,fileName,maskFilePath);



%% Download the functional data inputs
% To find these, get the ID for the session (which is in the URL of the web
% GUI, and then use this command to get a list of the analyses associated
% with that session, and then find the analysis ID the we want.
%
%{
    projectName = 'forwardModelWrapper';
    fw = flywheel.Flywheel(getpref(projectName,'flywheelAPIKey'));
    sessionID = '5cab7166f546b6002af04970';
    analysisList = fw.getSessionAnalyses(sessionID);
%}

% All the LightFlux runs
analysisID = '60269dba314e494b28e2d5b0';
fileNames = {...
    'task_sub-HEROgka1_ses-041416_task-LightFluxA_run-01_space-T1w_desc-preproc_bold_surfaces.zip',...
    'task_sub-HEROgka1_ses-041416_task-LightFluxA_run-02_space-T1w_desc-preproc_bold_surfaces.zip',...
    'task_sub-HEROgka1_ses-041416_task-LightFluxA_run-03_space-T1w_desc-preproc_bold_surfaces.zip',...
    'task_sub-HEROgka1_ses-041416_task-LightFluxA_run-04_space-T1w_desc-preproc_bold_surfaces.zip',...
    'task_sub-HEROgka1_ses-041516_task-LightFluxA_run-05_space-T1w_desc-preproc_bold_surfaces.zip',...
    'task_sub-HEROgka1_ses-041516_task-LightFluxA_run-06_space-T1w_desc-preproc_bold_surfaces.zip',...
    'task_sub-HEROgka1_ses-041416_task-LightFluxB_run-01_space-T1w_desc-preproc_bold_surfaces.zip',...
    'task_sub-HEROgka1_ses-041416_task-LightFluxB_run-02_space-T1w_desc-preproc_bold_surfaces.zip',...
    'task_sub-HEROgka1_ses-041416_task-LightFluxB_run-03_space-T1w_desc-preproc_bold_surfaces.zip',...
    'task_sub-HEROgka1_ses-041516_task-LightFluxB_run-04_space-T1w_desc-preproc_bold_surfaces.zip',...
    'task_sub-HEROgka1_ses-041516_task-LightFluxB_run-05_space-T1w_desc-preproc_bold_surfaces.zip',...
    'task_sub-HEROgka1_ses-041516_task-LightFluxB_run-06_space-T1w_desc-preproc_bold_surfaces.zip' ...
    };

for ff=1:length(fileNames)
    tmpPath = fullfile(saveDir,fileNames{ff});
%    fw.downloadOutputFromAnalysis(analysisID,fileNames{ff},tmpPath);
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

standardMeshAtlasesFolder = fullfile(getpref('forwardModelWrapper','projectBaseDir'),'code','utilities','standard_mesh_atlases');

freesurferBinPath = '/Applications/freesurfer/bin';

freesurferSubjectFolderPath = outPath;

workDir = outPath;

% Assemble the modelOpts
modelOpts = ['{' ...
    ' ''polyDeg'',' polyDeg ',' ...
    '}'];

%% Call the main routine
mainWrapper(funcZipPath01,funcZipPath02,funcZipPath03,funcZipPath04, ...
    funcZipPath05,funcZipPath06,funcZipPath07,funcZipPath08, ...
    funcZipPath09,funcZipPath10,funcZipPath11,funcZipPath12, ...
    'Na','Na','Na', stimFilePath, 'Na', ...
    'maskFilePath',maskFilePath, ...
    'dataFileType','cifti', ...
    'dataSourceType','vol2surf', ...
    'averageAcquisitions',averageAcquisitions, ...
    'averageVoxels',averageVoxels, ...
    'tr',tr, ...
    'modelClass','eventGain', ...
    'modelOpts',modelOpts, ...
    'Subject',subjectName,...
    'workbenchPath',workbenchPath, ...
    'externalMGZMakerPath', externalMGZMakerPath, ...
    'externalCiftiToFreesurferPath', externalCiftiToFreesurferPath, ...
    'standardMeshAtlasesFolder', standardMeshAtlasesFolder, ...
    'freesurferBinPath', freesurferBinPath, ...
    'freesurferSubjectFolderPath', freesurferSubjectFolderPath, ...
    'workDir', workDir, ...
    'outPath',outPath);

