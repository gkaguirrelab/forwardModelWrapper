% DEMO_LDOGglm
%
% This routine downloads LDOG struct and func data from flywheel and then
% submits the files for analysis


% Clear out variables from the workspace, as we will be passing these
% within the workspace to forwardModel
clear



%% Variable declaration
projectName = 'forwardModelWrapper';
scratchSaveDir = getpref(projectName,'flywheelScratchDir');
subjectName = 'EM529';

% TR of the acquisition in seconds
tr = '3.0';

% HRF parameters for the ldog data
hrfParams = '[-0.7520, 0.8389, 0.1139]';
polyDeg = '13';

% Flag to average the acquisitions together.
averageAcquisitions = '1';

% Use the average signal in the mask region
averageVoxels = '0';

% Pad missing TRs
padTruncatedTRs = '1';

%% Download the functional data inputs
% To find these, get the ID for the session (which is in the URL of the web
% GUI, and then use this command to get a list of the analyses associated
% with that session, and then find the analysis ID the we want.
%
%{
    sessionID = '60146008afe25f7a6015acd6';
    analysisList = fw.getSessionAnalyses('sessionID');
%}

% Create the functional tmp save dir if it does not exist
saveDir = fullfile(scratchSaveDir,'v0','input','funcZip');
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end


% Create a flywheel object
fw = flywheel.Flywheel(getpref(projectName,'flywheelAPIKey'));


%% Download the stim file
projectID = '5bb4ade9e849c300150d0d99';
fileName = 'blockedStimulus_1x144_On=1.mat';
stimFilePath = fullfile(saveDir,fileName);
fw.downloadFileFromProject(projectID,fileName,stimFilePath);


%% Download the functional data
% photoFlicker1, LminusS FIX output
analysisID = '6019723149214bc3ae649389';
fileName = 'EM529_photoFlicker_1_LminusS_RightEye_trimmed.zip';
funcZipPath01 = fullfile(saveDir,fileName);
fw.downloadOutputFromAnalysis(analysisID,fileName,funcZipPath01);

% photoFlicker1, LplusS FIX output
analysisID = '601972345b34e1456d15ab39';
fileName = 'EM529_photoFlicker_1_LminusS_RightEye.zip';
funcZipPath02 = fullfile(saveDir,fileName);
fw.downloadOutputFromAnalysis(analysisID,fileName,funcZipPath02);



%% Download the structural data

% Create the save dir if it does not exist
saveDir = fullfile(scratchSaveDir,'v0','input','structZip');
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

analysisID = '601745597cad7bd53015acd6';
fileName = 'EM529_preprocessedStruct.zip';
structZipPath = fullfile(saveDir,fileName);
fw.downloadOutputFromAnalysis(analysisID,fileName,structZipPath);

% Download the mask file
projectID = '5bb4ade9e849c300150d0d99';
fileName = '2x2x2resampled_invivoTemplate.nii.gz';
maskFilePath = fullfile(saveDir,fileName);
fw.downloadFileFromProject(projectID,fileName,maskFilePath)



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
mainWrapper(funcZipPath01,funcZipPath02,'Na','Na','Na','Na','Na','Na','Na','Na','Na','Na','Na','Na','Na', stimFilePath, structZipPath, ...
    'maskFilePath',maskFilePath, ...
    'averageAcquisitions',averageAcquisitions, ...
    'averageVoxels',averageVoxels, ...
    'padTruncatedTRs',padTruncatedTRs, ...
    'tr',tr, ...
    'modelClass','glm', ...
    'modelOpts',modelOpts, ...
    'Subject',subjectName,...
    'dataFileType', 'volumetric',...
    'dataSourceType', 'ldogfix',...
    'workbenchPath',workbenchPath, ...
    'externalMGZMakerPath', externalMGZMakerPath, ...
    'outPath',outPath);
