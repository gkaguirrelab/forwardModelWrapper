function WrapperAnalyzePRF(stimFileName,dataFileName,tr,outpath,varargin)
% Wrapper to manage inputs to Kendrick Kay's analyze pRF code
%
% Syntax:
%  WrapperAnalyzePRF(stimFileName,dataFileName,tr,outpath)
%
% Description:
%   Add a description here.
%
%   Note: All variable inputs are in the form of strings. This is to
%   support compilation.
%
%
% Inputs:
%   stimFileName          - String. Lorem ipsum lorem ipsum lorem ipsum 
%                           lorem ipsum lorem ipsum lorem ipsum lorem ipsum
%                           lorem ipsum lorem ipsum lorem ipsum lorem ipsum
%   dataFileName          - String. Lorem ipsum lorem ipsum lorem ipsum 
%                           lorem ipsum lorem ipsum lorem ipsum lorem ipsum
%                           lorem ipsum lorem ipsum lorem ipsum lorem ipsum
%   tr                    - String. Lorem ipsum lorem ipsum lorem ipsum 
%                           lorem ipsum lorem ipsum lorem ipsum lorem ipsum
%                           lorem ipsum lorem ipsum lorem ipsum lorem ipsum
%   outpath               - String. Lorem ipsum lorem ipsum lorem ipsum 
%                           lorem ipsum lorem ipsum lorem ipsum lorem ipsum
%                           lorem ipsum lorem ipsum lorem ipsum lorem ipsum
%
% Optional key/value pairs:
%  'wantglmdenoise'       - String. Lorem ipsum lorem ipsum lorem ipsum 
%                           lorem ipsum lorem ipsum lorem ipsum lorem ipsum
%                           lorem ipsum lorem ipsum lorem ipsum lorem ipsum
%
% Outputs:
%   none
%
% Examples:
%{
    % Run the wrapper using Kendrick's example data. The path to Kendrick's
    % data is currently hard-coded
    examplePath='~/Documents/MATLAB/toolboxes/analyzePRF/exampledataset.mat';
    load(examplePath,'stimulus','data')

    % Kendrick's example fMRI data must be resampled to match the time
    % domain of the stimulus
    data = tseriesinterp(data,2,1,2);

    % We reshape the data to be a 2x2x2 volume and save as a nifti file
    tempData=reshape(data{1}(1:8,:),[2 2 2 300]);
    tempNiftiPath='~/Desktop/tempNifti.nii';
    niftiwrite(tempData, tempNiftiPath)

    % Save the stimulus file
    tempStimFilePath='~/Desktop/tempStim.mat';
    stimulus=stimulus{1};
    save(tempStimFilePath,'stimulus');

    % Run the wrapper function
    tr='1';
    outpath='~/Desktop/tempResults.mat';
    WrapperAnalyzePRF(tempStimFilePath,tempNiftiPath,tr,outpath);
%}




%% Parse vargin for options passed here

p = inputParser; p.KeepUnmatched = true;

% Required  
p.addRequired('stimFileName',@isstr);
p.addRequired('dataFileName',@isstr);
p.addRequired('tr', @isstr);
p.addRequired('outpath', @isstr);

% Optional parameters
p.addParameter('wantglmdenoise','0',@isstr);
p.addParameter('hrf',[],@isstr);   %MAT FILE, COLUMN VECTOR
p.addParameter('maxpolydeg',[],@isstr);
p.addParameter('seedmode','[0 1 2]',@isstr);
p.addParameter('xvalmode','0',@isstr);
p.addParameter('numperjob',[],@isstr);
p.addParameter('maxiter','500',@isstr);
p.addParameter('display','iter',@isstr);
p.addParameter('typicalgain','10',@isstr);
p.addParameter('maskFileName',[], @isstr);

% parse
p.parse(stimFileName, dataFileName, tr, outpath, varargin{:})

% Load the stimulus and data files
load(stimFileName,'stimulus');

%%nifti to 2d
rawData = niftiread(p.Results.dataFileName);   % Load 4D data
data = reshape(rawData, [size(rawData,1)*size(rawData,2)*size(rawData,3), size(rawData,4)]); % Convert 4D to 2D
data = im2single(data);   % convert data to single precision

% massage cell inputs
if ~iscell(stimulus)
  stimulus = {stimulus};
end
if ~iscell(data)
  data = {data};
end

% determine how many voxels to analyze 

if ~isempty(p.Results.maskFileName)    % Get the indices from mask if specified
    rawMask = niftiread(p.Results.maskFileName);
    mask = rawMask(:);
    vxs = find(mask)';
else                                   % Analyze all voxels if no mask is specified 
    is3d = size(data{1},4) > 1;
    if is3d
      dimdata = 3;
      dimtime = 4;
      xyzsize = sizefull(data{1},3);
    else
      dimdata = 1;
      dimtime = 2;
      xyzsize = size(data{1},1);
    end
    numvxs = prod(xyzsize);
    vxs = 1:numvxs;
end

% MCR only accepts strings. This part converts variables which are passed
% as strings to vectors and numericals.

tr = str2double(tr);
listofnums = ['0','1','2','3','4','5','6','7','8','9'];
new_seedmode = [];
if ~isempty(p.Results.maxpolydeg)
    new_maxpolydeg = str2double(p.Results.maxpolyreg);
else 
    new_maxpolydeg = p.Results.maxpolydeg;
end

if ~isempty(p.Results.numperjob)
    new_numperjob = str2double(p.Results.numperjob);
else
    new_numperjob = p.Results.numperjob;
end

if ~isempty(p.Results.hrf)
    new_hrf = load(p.Results.hrf,'hrf');
    new_hrf = new_hrf.hrf;
else
    new_hrf = p.Results.hrf;
end 

for ii = p.Results.seedmode
    if ismember(ii, listofnums)
        new_seedmode = [new_seedmode,str2double(ii)];
    end
end

%% Need to check that the movie and voxel time-series are of the same
%% temporal length. If they are not, we could issue an error here


% Prepare the final structure and convert the remaining variables to
% numerical
analysisStructure = struct('vxs',vxs,'wantglmdenoise',str2double(p.Results.wantglmdenoise),'hrf',new_hrf, ...
    'maxpolydeg',new_maxpolydeg,'seedmode',new_seedmode,'xvalmode',str2double(p.Results.xvalmode), ...
    'numperjob',new_numperjob,'maxiter',str2double(p.Results.maxiter),'display',p.Results.display, ...
    'typicalgain',str2double(p.Results.typicalgain));

% Run the function and save the results
results = analyzePRF(stimulus,data,tr,analysisStructure);
save(outpath,'results')

% Code here to reformat the results into brain maps, respecting the mask
% that was defined above, and then save the image maps someplace. Also, we
% will want to save some pictures that illustrate what the image map
% outputs look like.


end
