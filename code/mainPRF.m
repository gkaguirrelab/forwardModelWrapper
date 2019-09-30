function mainPRF(funcZipPath, stimFilePath, structZipPath, varargin)
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
p.addParameter('hrfFilePath', 'Na', @isstr)

% Config options - multiple
p.addParameter('verbose', '1', @isstr)
p.addParameter('dataFileType', 'cifti', @isstr)

% Config options - pre-process
p.addParameter('dataSourceType', 'icafix', @isstr)
p.addParameter('trimDummyStimTRs', '0', @isstr)
p.addParameter('averageAcquisitions', '0', @isstr)

% Config options - wrapper
p.addParameter('tr',[],@isstr);
p.addParameter('wantglmdenoise','0',@isstr);
p.addParameter('maxpolydeg','Na',@isstr);
p.addParameter('seedmode','[0 1 2]',@isstr);
p.addParameter('xvalmode','0',@isstr);
p.addParameter('numperjob','Na',@isstr);
p.addParameter('maxiter','500',@isstr);
p.addParameter('display','off',@isstr);
p.addParameter('typicalgain','10',@isstr);

% Config options - post-process
p.addParameter('pixelsPerDegree', 'Na', @isstr)
p.addParameter('screenMagnification', '1.0', @isstr)

% Config options - convert to mgz
p.addParameter('externalMGZMakerPath',...
    fullfile(getpref('pRFCompileWrapper','projectBaseDir'),'code','make_fsaverage.py'), @isstr)
p.addParameter('RegName', 'FS', @isstr)

% Config options - demo over-ride
p.addParameter('demoMode', false, @islogical)
p.addParameter('vxsPass', [], @isnumeric)

% Internal paths
p.addParameter('workbenchPath', '', @isstr);
p.addParameter('outPath', '', @isstr);


% Parse
p.parse(funcZipPath, stimFilePath, structZipPath, varargin{:})



%% PRF analysis
% Call AnalyzePRFPreprocess
[stimulus, data, vxs, templateImage] = ...
    preprocessPRF(p.Results.workbenchPath, funcZipPath, stimFilePath, ...
    'maskFilePath',p.Results.maskFilePath, ...
    'averageAcquisitions',p.Results.averageAcquisitions);

% If vxsPass has been defined (perhaps by the demo routine), substitute
% this value for vxs
if ~isempty(p.Results.vxsPass)
    vxs = p.Results.vxsPass;
end

% If the hrfFilePath has been defined, load it
if ~strcmp(p.Results.hrfFilePath,'Na')
    load(p.Results.hrfFilePath,'hrf');
else
    hrf = [];
end

% Call the analyzePRF wrapper
results = wrapperPRF(stimulus, data, vxs, ...
    'tr',p.Results.tr,...
    'hrf',hrf,...
    'wantglmdenoise',p.Results.wantglmdenoise,...
    'maxpolydeg',p.Results.maxpolydeg,...
    'seedmode',p.Results.seedmode,...
    'xvalmode',p.Results.xvalmode,...
    'numperjob',p.Results.numperjob,...
    'maxiter',p.Results.maxiter,...
    'typicalgain',p.Results.typicalgain);

% Process and save the results
modifiedResults = postprocessPRF(...
    results, templateImage, p.Results.outPath, p.Results.workbenchPath,...
    'dataFileType', p.Results.dataFileType, ...
    'pixelsPerDegree', p.Results.pixelsPerDegree, ...
    'screenMagnification', p.Results.screenMagnification);

% If we are in demo mode, show some plots
if p.Results.demoMode
    plotPRF(modifiedResults,data,stimulus)
end


%% Convert to MGZ

% Uncompress the structZip into the dir that holds the zip. We do this
% with a system call so that we can prevent over-writing a prior unzipped
% version of the data (which can happen in demo mode).
command = ['unzip -n ' structZipPath ' -d ' fileparts(structZipPath)];
system(command);

% Find the directory that is produced by this unzip operation
fileList = dir(fileparts(structZipPath));
fileList = fileList(...
    cellfun(@(x) ~startsWith(x,'.'),extractfield(fileList,'name')) ...
    );
fileList = fileList(cell2mat(extractfield(fileList,'isdir')));
hcpStructPath = fullfile(fileList.folder,fileList.name);

% Assemble variables for python external call
ciftiMapsPath = fullfile(p.Results.outPath,'maps');

command =  ['python ' p.Results.externalMGZMakerPath ' ' ciftiMapsPath ' ' hcpStructPath ' ' p.Results.RegName ' ' fullfile(p.Results.outPath, 'nativeMaps')];
%system(command);

end % Main function