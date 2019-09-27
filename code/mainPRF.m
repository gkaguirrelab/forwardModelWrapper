% This script assembles filepaths and hands off processing to various
% functions


% This routine may be called de-novo, or in the setting of an example
% script that has pre-defined some of the variables that are set below. We
% only define those variables that do not yet exist


%% Required inputs
if ~exist('funcZipPath','var')
	dirTmp = dir('/flywheel/v0/input/funcZip/*.zip');
    funcZipPath = fullfile(dir.folder,dir.name);
end
if ~exist('stimFilePath','var')
	dirTmp = dir('/flywheel/v0/input/funcFile/*.m');
    stimFilePath = fullfile(dir.folder,dir.name);
end
if ~exist('structZipPath','var')
	dirTmp = dir('/flywheel/v0/input/structZip/*.zip');
    structZipPath = fullfile(dir.folder,dir.name);
end


%% Optional inputs
if ~exist('maskFilePath','var')
    maskFilePath = 1;
end
if ~exist('hrfFilePath','var')
    hrf = [];
end


%% Config options
if ~exist('tr','var')
    tr = '0.8';
end
if ~exist('trimDummyStimTRs','var')
    trimDummyStimTRs = '0';
end
if ~exist('dataFileType','var')
    dataFileType = 'cifti';
end
if ~exist('dataSourceType','var')
    dataSourceType = 'icafix';
end
if ~exist('averageAcquisitions','var')
    averageAcquisitions = '0';
end
if ~exist('wantglmdenoise','var')
    wantglmdenoise = '0';
end
if ~exist('maxpolydeg','var')
    maxpolydeg = 'Na';
end
if ~exist('seedmode','var')
    seedmode = '[0 1 2]';
end
if ~exist('xvalmode','var')
    xvalmode = '0';
end
if ~exist('numperjob','var')
    numperjob = 'Na';
end
if ~exist('maxiter','var')
    maxiter = '500';
end
if ~exist('typicalgain','var')
    typicalgain = '10';
end


%% Internal paths
if ~exist('workbenchPath','var')
    foo = 1;
end
if ~exist('outDir','var')
    outDir = '/flywheel/v0/input';
end


% Call AnalyzePRFPreprocess
[stimulus, data, vxs, templateImage] = ...
    preprocessPRF(workbenchPath, funcZipPath, stimFilePath, ...
    'maskFilePath',maskFilePath, ...
    'averageAcquisitions',averageAcquisitions);

% If vxsPass has been defined (perhaps by the demo routine), substitute
% this value for vxs
if exist('vxsPass','var')
    vxs = vxsPass;
end

% Call the analyzePRF wrapper
results = wrapperPRF(stimulus, data, vxs, ...
    'tr',tr,...
    'hrf',hrf,...
    'wantglmdenoise',wantglmdenoise,...
    'maxpolydeg',maxpolydeg,...
    'seedmode',seedmode,...
    'xvalmode',xvalmode,...
    'numperjob',numperjob,...
    'maxiter',maxiter,...
    'typicalgain',typicalgain);

% Process and save the results
modifiedResults = postprocessPRF(...
    results, templateImage, outDir, workbenchPath,...
    'dataFileType', dataFileType, ...
    'pixelsPerDegree', pixelsPerDegree);

% Call the python routine here


