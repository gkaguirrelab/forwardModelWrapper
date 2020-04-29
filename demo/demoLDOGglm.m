% DEMO_LDOGglm
%
% This routine downloads LDOG struct and func data from flywheel and then
% submits the files for analysis


% Clear out variables from the workspace, as we will be passing these
% within the workspace to forwardModel
clear


% Use the average signal in the mask region
averageVoxels = '1';


%% Variable declaration
projectName = 'forwardModelWrapper';
scratchSaveDir = getpref(projectName,'flywheelScratchDir');
subjectName = 'N292';

% TR of the acquisition in seconds
tr = '3.0';

% HRF parameters for the ldog data
hrfParams = '[-0.7520, 0.8389, 0.1139]';
polyDeg = '5';

% Flag to average the acquisitions together before computing pRF
% parameters. This makes the operation faster.
averageAcquisitions = '0';



%% Download the functional data
outputFileSuffix = 'N292_lightFluxFlicker.zip';

% Create the functional tmp save dir if it does not exist
saveDir = fullfile(scratchSaveDir,'v0','input','funcZip');
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

% Create a flywheel object
fw = flywheel.Flywheel(getpref(projectName,'flywheelAPIKey'));

%% Download the functional data
% photoFlicker1, LplusS FIX output
analysisID = '5e444eb96dea31209d2a742e';
fileName = 'N292_photoFlicker_1_LplusS.zip';
funcZipPath01 = fullfile(saveDir,fileName);
fw.downloadOutputFromAnalysis(analysisID,fileName,funcZipPath01);

% photoFlicker2, LplusS FIX output
analysisID = '5e4592d16dea3124dd2a7443';
fileName = 'N292_photoFlicker_2_LplusS.zip';
funcZipPath02 = fullfile(saveDir,fileName);
fw.downloadOutputFromAnalysis(analysisID,fileName,funcZipPath02);


%% Download the stim file
projectID = '5bb4ade9e849c300150d0d99';
fileName = 'photoFlicker_LplusS_acq_01_06_08_x2_stimulus.mat';
stimFilePath = fullfile(saveDir,fileName);
fw.downloadFileFromProject(projectID,fileName,stimFilePath)


%% Download the structural data

% Create the save dir if it does not exist
saveDir = fullfile(scratchSaveDir,'v0','input','structZip');
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

analysisID = '5e4304dd6dea311bba2a7436';
fileName = 'N292_preprocessedStruct.zip';
structZipPath = fullfile(saveDir,fileName);

% Download the mask file
sessionID = '5dcafb3fe74aa3005e1a04e6';
fileName = 'N292_R2_map_thresh_0.3.nii.gz';
maskFilePath = fullfile(saveDir,fileName);
fw.downloadFileFromSession(sessionID,fileName,maskFilePath)



%% Additional settings


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
               ' ''hrfParams'',' hrfParams ',' ...
               ' ''polyDeg'',' polyDeg ...
               '}'];

%% Call the main routine
mainWrapper(funcZipPath01,funcZipPath02,'Na','Na','Na','Na','Na','Na','Na','Na', stimFilePath, structZipPath, ...
    'maskFilePath',maskFilePath, ...
    'averageAcquisitions',averageAcquisitions, ...
    'averageVoxels',averageVoxels, ...
    'tr',tr, ...
    'modelClass','glm', ...
    'modelOpts',modelOpts, ...
    'Subject',subjectName,...
    'dataFileType', 'volumetric',...
    'dataSourceType', 'ldogfix',...
    'workbenchPath',workbenchPath, ...
    'externalMGZMakerPath', externalMGZMakerPath, ...
    'outPath',outPath);
