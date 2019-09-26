% DEMO_AnalyzePRF
%
% This routine downloads ICAFIX and hcp-struct data from flywheel and then
% submits the files to pRF analysis.

projectName = 'pRFCompileWrapper';

% Which subject to process?
subjectName = 'TOME_3021';

% Define a few variables
outputFileSuffix = '_hcpicafix.zip';
scratchSaveDir = getpref(projectName,'flywheelScratchDir');

% Create the save dir if it does not exist
if ~exist(scratchSaveDir,'dir')
    mkdir(scratchSaveDir);
end

% Define the pixels / deg
screenHeightCm = 39.2257;
screenDistanceCm = 106.5;
visualAngleDegOnePercent = atand((39.2257/100)/106.5);
pixelToDegree = 108 / (visualAngleDegOnePercent*100);
pixelToDegree = num2str(pixelToDegree);

% Create a flywheel object
fw = flywheel.Flywheel(getpref(projectName,'flywheelAPIKey'));

% The ica-fix results for the RETINO data for one subject
searchStruct = struct(...
    'returnType', 'analysis', ...
    'filters', {{...
    struct('match', struct('analysis0x2elabel', 'icafix')), ...
    struct('match', struct('analysis0x2elabel', 'RETINO')), ...
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
saveName = fullfile(scratchSaveDir,thisName);

% If the file has not already been downloaded, get it
if ~exist(saveName,'file')
    
    % Inform the user
    fprintf(['Downloading: ' thisName '\n']);
    fprintf(['         to: ' scratchSaveDir '\n']);
    
    % Download the matching file to the rootSaveDir. This can take a while
    fw.downloadOutputFromAnalysis(thisAnalysis.id,thisName,saveName);
        
end

% Assemble variables for the call to AnalyzePRFPreprocess
workbenchPath = getpref(projectName,'wbCommand');
inputDataPath = saveName;
stimFilePath = fullfile(getpref(projectName,'projectBaseDir'),'demo','pRFStimulus_108x108x420.mat');
maskFilePath = fullfile(getpref(projectName,'projectBaseDir'),'demo','lh.V1mask.dscalar.nii');
tempDir = scratchSaveDir;

% Call AnalyzePRFPreprocess
[stimulus, data, vxs, templateImage] = ...
    AnalzePRFPreprocess(workbenchPath, inputDataPath, stimFilePath, tempDir, ...
    'maskFilePath',maskFilePath, ...
    'averageAcquisitions','1');

% Set the TR
tr = 0.8;

% Call the analyzePRF wrapper
results = WrapperAnalyzePRF(stimulus, data, tr, vxs);

% Process and save the results
modifiedResults = AnalzePRFPostprocess(...
    results, templateImage, tempDir, workbenchPath,...
    'pixelToDegree', pixelToDegree);
