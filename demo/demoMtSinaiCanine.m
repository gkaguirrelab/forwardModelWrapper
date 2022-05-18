% demoMtSinaiCanine
%


% Clear out variables from the workspace
clear


%% Variable declaration
projectName = 'forwardModelWrapper';
scratchSaveDir = getpref(projectName,'flywheelScratchDir');
subjectName = 'WT';

% Create the functional tmp save dir if it does not exist
saveDir = fullfile(scratchSaveDir,'v0','input','funcZip');
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

% Process one voxel that has a great fit
vxsPass = [52063];

% TR of the acquisition in seconds
tr = '3.0';

% The degree of polynomial to use to remove low-freq trends from the data
polyDeg = '10';

% Flag to average the acquisitions together before computing pRF
% parameters. This makes the operation faster.
averageAcquisitions = '0';
averageVoxels = '0';
convertToPercentChange = '1';

%% Open the flywheel object
fw = flywheel.Flywheel(getpref(projectName,'flywheelAPIKey'));

%% Download the stim file
projectID = '5bb4ade9e849c300150d0d99';
fileName = 'photoFlickerStimulusMtSinaiModel_LFLeftAndRight.mat';
stimFilePath = fullfile(saveDir,fileName);
fw.downloadFileFromProject(projectID,fileName,stimFilePath);


%% Download the mask file
fileName = '2x2x2resampled_invivoTemplate.nii.gz';
maskFilePath = fullfile(saveDir,fileName);
fw.downloadFileFromProject(projectID,fileName,maskFilePath);

%% Download the struct file
analysisID = '606f6dbd40fddd6cd7e53f32';
fileName = 'N344_preprocessedStruct.zip';
structZipPath = fullfile(saveDir,fileName);
fw.downloadOutputFromAnalysis(analysisID,fileName,structZipPath);



%% Download the functional data inputs
% To find these, get the ID for the session (which is in the URL of the web
% GUI, and then use this command to get a list of the analyses associated
% with that session, and then find the analysis ID the we want.
%
%{
    projectName = 'forwardModelWrapper';
    fw = flywheel.Flywheel(getpref(projectName,'flywheelAPIKey'));
    sessionID = '606f4e3a23a4b1585ea16b77';
    analysisList = fw.getSessionAnalyses(sessionID);
%}

% All the functional runs
analysisIDs = {'6283063474112e16ec1f7695','6283062e1dc1489f0fc56fb3',...
    '6282bf3c4d8b9aac211f650a','6282bf35b3f7eeeca9c551c5',...
    '6282bf4b1c7bf8cc04e7cbfc','6282bf442d64bd169f4d6461'};
fileNames = {...
    'N344_photoFlicker_2_LightFlux_LeftEye_NoSmoothing.zip',...
    'N344_photoFlicker_2_LightFlux_RightEye_NoSmoothing.zip',...
    'N347_photoFlicker_1_LightFlux_LeftEye_NoSmoothing.zip',...
    'N347_photoFlicker_1_LightFlux_RightEye_NoSmoothing.zip',...
    'N349_photoFlicker_1_LightFlux_LeftEye_NoSmoothing.zip',...
    'N349_photoFlicker_1_LightFlux_RightEye_NoSmoothing.zip',...
    };

% Download the files and assign the funcZipPath variables
fileIdx = 1;
for aa=1:length(analysisIDs)
    tmpPath = fullfile(saveDir,fileNames{aa});
    if ~isfile(tmpPath)
        fw.downloadOutputFromAnalysis(analysisIDs{aa},fileNames{aa},tmpPath);
    end
    command = sprintf('funcZipPath%02d = tmpPath',fileIdx);
    eval(command);
    fileIdx=fileIdx+1;
end

for ff=fileIdx:36
    tmpPath = 'Na';
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
modelOpts = '{(polyDeg),13,(stimLabels),{ (N344_LF_rightEye_01),(N344_LF_rightEye_02),(N344_LF_rightEye_03),(N344_LF_leftEye_01),(N344_LF_leftEye_02),(N344_LF-leftEye_03),(N347_LF_rightEye_01),(N347_LF_rightEye_02),(N347_LF_rightEye_03),(N347_LF_leftEye_01),(N347_LF_leftEye_02),(N347_LF-leftEye_03),(N349_LF_rightEye_01),(N349_LF_rightEye_02),(N349_LF_rightEye_03),(N349_LF_leftEye_01),(N349_LF_leftEye_02),(N349_LF-leftEye_03) },(avgAcqIdx),{ [1:144,433:576],[145:288,577:720],[289:432,721:864],[865:1008,1297:1440],[1009:1152,1441:1584],[1153:1296,1585:1728],[1729:1872,2161:2304],[1873:2016,2305:2448],[2017:2160,2449:2592] }}';
modelOpts = strrep(modelOpts,'(','''');
modelOpts = strrep(modelOpts,')','''');

%% Call the main routine
mainWrapper(funcZipPath01,funcZipPath02,funcZipPath03,funcZipPath04, ...
    funcZipPath05,funcZipPath06,funcZipPath07,funcZipPath08, ...
    funcZipPath09,funcZipPath10,funcZipPath11,funcZipPath12, ...
    funcZipPath13,funcZipPath14,funcZipPath15,funcZipPath16, ...
    funcZipPath17,funcZipPath18,funcZipPath19,funcZipPath20, ...
    funcZipPath21,funcZipPath22,funcZipPath23,funcZipPath24, ...
    funcZipPath25,funcZipPath26,funcZipPath27,funcZipPath28, ...
    funcZipPath29,funcZipPath30,funcZipPath31,funcZipPath32, ...
    funcZipPath33,funcZipPath34,funcZipPath35,funcZipPath36, ...
    stimFilePath, structZipPath, ...
    'maskFilePath',maskFilePath, ...
    'dataFileType','volumetric', ...
    'dataSourceType','ldogfix', ...
    'averageAcquisitions',averageAcquisitions, ...
    'averageVoxels',averageVoxels, ...
    'convertToPercentChange',convertToPercentChange,...
    'tr',tr, ...
    'modelClass','mtSinai', ...
    'modelOpts',modelOpts, ...
    'Subject',subjectName,...
    'workbenchPath',workbenchPath, ...
    'externalMGZMakerPath', externalMGZMakerPath, ...
    'externalCiftiToFreesurferPath', externalCiftiToFreesurferPath, ...
    'standardMeshAtlasesFolder', standardMeshAtlasesFolder, ...
    'freesurferInstallationPath', freesurferInstallationPath, ...
    'workDir', workDir, ...
    'outPath',outPath, ...
    'vxsPass', vxsPass);

