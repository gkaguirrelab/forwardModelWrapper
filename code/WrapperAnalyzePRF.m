function results = WrapperAnalyzePRF(stimFileName,dataFileName,tr,outpath,varargin)
% Wrapper to manage inputs to Kendrick Kay's analyze pRF code
%
% Syntax:
%  WrapperAnalyzePRF(stimFileName,dataFileName,tr,outpath)
%
% Description:
%   Details on the pRF model:
%   - Before analysis, we zero out any voxel that has a non-finite value or
%   has all zeros in at least one of the runs.  This prevents weird issues 
%   due to missing or bad data. 
%   - The pRF model that is fit is similar to that described in Dumoulin 
%   and Wandell (2008), except that a static power-law nonlinearity is 
%   added to the model.  This new model, called the Compressive Spatial 
%   Summation (CSS) model, is described in Kay, Winawer, Mezer, & Wandell 
%   (2013).
%   - The model involves computing the dot-product between the stimulus and
%   a 2D isotropic Gaussian, raising the result to an exponent, scaling the
%   result by a gain factor, and then convolving the result with a 
%   hemodynamic response function (HRF).  Polynomial terms are included 
%   (on a run-by-run basis) to model the baseline signal level.
% - The 2D isotropic Gaussian is scaled such that the summation of the 
%   values in the Gaussian is equal to one. This eases the interpretation 
%   of the gain of the model.
% - The exponent parameter in the model is constrained to be non-negative.
% - The gain factor in the model is constrained to be non-negative; this 
%   aids the interpretation of the model (e.g. helps avoid voxels with 
%   negative BOLD responses to the stimuli).
% - The workhorse of the analysis is fitnonlinearmodel.m, which is 
%   essentially a wrapper around routines in the MATLAB Optimization 
%   Toolbox. We use the Levenberg-Marquardt algorithm for optimization, 
%   minimizing squared error between the model and the data.
% - A two-stage optimization strategy is used whereby all parameters 
%   excluding the exponent parameter are first optimized (holding the 
%   exponent parameter fixed) and then all parameters are optimized 
%   (including the exponent parameter).This strategy helps avoid local 
%   minima.
%
%
%   Note: All variable inputs are in the form of strings. This is to
%   support compilation.
%
%
% Inputs:
%   stimFileName          - String. .mat file. Provides the apertures as a  
%                           cell vector of R x C x time. Values should be 
%                           in [0,1].The number of time points can differ 
%                           across runs. The variable needs be named
%                           stimulus.
%   dataFileName          - String. Provides the data as a cell vector of 
%                           voxels x time.the number of time points should 
%                           match the number of time points in <stimulus>.
%   tr                    - String. The TR in seconds (e.g. 1.5)                          
%   outpath               - String. Output path without the save file name.
%
% Optional key/value pairs:
%  
%  'wantglmdenoise'         - String. (optional) is whether to use GLMdenoise
%                           to determine nuisance regressors to add into 
%                           the PRF model.  note that in order to use this 
%                           feature, there must be at least two runs (and 
%                           conditions must repeat across runs). 
%                           We automatically determine the GLM design 
%                           matrix based on the contents of <stimulus>.  
%                           Special case is to pass in the noise regressors 
%                           directly (e.g. from a previous call).default: 0
%  'hrf'                    - String. (optional) is a column vector with the
%                           hemodynamic response function (HRF) to use in 
%                           the model. The first value of <hrf> should be
%                           coincident with the onset of the stimulus, and 
%                           the HRF should indicate the timecourse of the 
%                           response to a stimulus that lasts for one TR.  
%                           Default is to use a canonical HRF (calculated 
%                           using getcanonicalhrf(tr,tr)').
%  'maxpolydeg'             - String. Is a non-negative integer indicating 
%                           the maximum polynomial degree to use for drift 
%                           terms. Can be a vector whose length matches the
%                           number of runs in <data>.  default is to use 
%                           round(L/2) where L is the number of minutes
%                           in the duration of a given run.
%  'seedmode'               - String. Is a vector consisting of one or 
%                           more of the following values (we automatically 
%                           sort and ensure uniqueness):
%                           0 means use generic large PRF seed
%                           1 means use generic small PRF seed
%                           2 means use best seed based on super-grid
%                           default: [0 1 2].
%  -'xvalmode'              - String.
%                           0 means just fit all the data
%                           1 means two-fold cross-validation (first half 
%                           of runs; second half of runs)
%                           2 means two-fold cross-validation (first half               
%                           of each run; second half of each run)
%                           default: 0.  (note that we round when halving.)
%  -'numperjob'             - String.[] means to run locally (not on the cluster)
%                           N where N is a positive integer indicating the 
%                           number of voxels to analyze in each cluster job
%                           this option requires a customized computational 
%                           setup! default: [].
%  -'maxiter'               - String. Is the maximum number of iterations.  
%                           default: 500.
%  -'display'               - String.is 'iter' | 'final' | 'off'.  
%                           default: 'iter'.
%  -'typicalgain'           - String. Is a typical value for the gain in 
%                           each time-series. Default: 10.
%  -'maskFileName'          - String. Path to the mask. If not used, all
%                           voxels in the data file are analyzed.
%  -'prependDummyTRs'       - String. Used when the stimulus and data
%                           lengths are not equal and the inequality is 
%                           caused due to the removal of dummy TRs from
%                           the sample. Calculates the mean along the time
%                           dimension for each voxel and adds that mean at
%                           the beginning of the data (multiple times if
%                           required until data and stimulus sample lengths
%                           are exactly the same. Don't use this option if
%                           the difference is due to sampling. 1 for true 
%                           and 0 for false. Default = 0
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
p.addParameter('prependDummyTRs','0', @isstr)

% parse
p.parse(stimFileName, dataFileName, tr, outpath, varargin{:})

% Load the stimulus and convert to single
load(stimFileName,'stimulus');
stimulus = single(stimulus); 

%% Load Data

% If the input does not end with gz then gear will extract the zip into a
% folder and this matlab script will go to that folder, find all the
% hp2000_clean volumes, and exclude the folder containing the avarage of 
% all runs. This piece of code will only work inside a gear.
if dataFileName(end-1:end) ~= "gz" 
    d = dir('/*/*/*/*/*/MNINonLinear/Results'); % Use this for testing
    
    %d = dir('/flywheel/v0/input/*/*/MNINonLinear/Results'); % find the
    % runs (use this in the gear
    
    d = d(~ismember({d.name},{'.','..'})); % get rid of "." and ".." stuff
    d(1) = []; % Get rid of the first item which is the one contains all runs
    runNumber = length(d); % Get the number of runs
    for i = 1:runNumber
        rawName = strcat(d(i).folder,'/', d(i).name, '/', d(i).name, '_', 'hp2000_clean.nii.gz'); % Get the name of runs with path
        rawData = MRIread(rawName);
        data = rawData.vol;
        data = single(data);
        data = reshape(data, [size(data,1)*size(data,2)*size(data,3), size(data,4)]); %create the data cell required for Kendrick's code
        data{1,i} = data;  %PROBLEM HERE
    end
else    
    rawData = MRIread(p.Results.dataFileName);   % Load 4D data
    data = rawData.vol;
    data = single(data); % convert data volume to single 
    data = reshape(data, [size(data,1)*size(data,2)*size(data,3), size(data,4)]); % Convert 4D to 2D
end

% massage cell inputs
if ~iscell(stimulus)
  stimulus = {stimulus};
end
if ~iscell(data)
  data = {data};
end

% determine how many voxels to analyze 

if ~isempty(p.Results.maskFileName)    % Get the indices from mask if specified
    rawMask = MRIread(p.Results.maskFileName);
    mask = rawMask.vol;
    mask = single(mask); % Convert mask volume to single
    mask = reshape(mask, [size(mask,1)*size(mask,2)*size(mask,3),1]);
    clear rawMask
    
    vxs = find(mask)';
    vxs = single(vxs);
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

% Check that the movie and voxel time-series are of the same temporal 
% length. If they are not but prependDummyTR is issued, add the mean time
% for each voxel at the beginning of the timeseries matrix until the data
% and stimulus matrix lengths become the same.

datasizes = size(data{1});
data_temporal_size = datasizes(2);
stimsizes = size(stimulus{1});
stim_temporal_size = stimsizes(3);

if data_temporal_size < stim_temporal_size
    if str2double(p.Results.prependDummyTRs) == 1
        warning("prependDummyTR function is enabled")
        difference = stim_temporal_size - data_temporal_size;
        means_of_rows = mean(data, 2);
        for i = 1:difference
            data = horzcat(means_of_rows, data);
        end 
    else
        error("Sample lengths of the stimulus and data are not equal. Either resample your data or consider prependDummyTR option")
    end
end

% Prepare the final structure and convert the remaining variables to
% numerical
analysisStructure = struct('vxs',vxs,'wantglmdenoise',str2double(p.Results.wantglmdenoise),'hrf',new_hrf, ...
    'maxpolydeg',new_maxpolydeg,'seedmode',new_seedmode,'xvalmode',str2double(p.Results.xvalmode), ...
    'numperjob',new_numperjob,'maxiter',str2double(p.Results.maxiter),'display',p.Results.display, ...
    'typicalgain',str2double(p.Results.typicalgain));

% Run the function and save the results
results = analyzePRF(stimulus,data,tr,analysisStructure);
save(strcat(outpath,"results.mat"),'results')

% Code here to reformat the results into brain maps, respecting the mask
% that was defined above, and then save the image maps someplace. Also, we
% will want to save some pictures that illustrate what the image map
% outputs look like.

% REPLACE NANs WITH 0 - This is not needed but some softwares (eg. freeview) 
% throws warnings when there are NaNs in the data. This stops it.
results.ecc(isnan(results.ecc)) = 0;
results.ang(isnan(results.ang)) = 0;
results.expt(isnan(results.expt)) = 0; 
results.rfsize(isnan(results.rfsize)) = 0; 
results.R2(isnan(results.R2)) = 0; 
results.gain(isnan(results.gain)) = 0; 

%MAKE 3D
getsize = size(rawData.vol); %Get the size of the original scan 

% Results converted 2D -> 3D
eccentricity = reshape(results.ecc,[getsize(1) getsize(2) getsize(3) 1]);
angular = reshape(results.ang,[getsize(1) getsize(2) getsize(3) 1]);
exponent = reshape(results.expt,[getsize(1) getsize(2) getsize(3) 1]);
rfsize = reshape(results.rfsize,[getsize(1) getsize(2) getsize(3) 1]);
R2 = reshape(results.R2,[getsize(1) getsize(2) getsize(3) 1]);
gain = reshape(results.gain,[getsize(1) getsize(2) getsize(3) 1]);

%SAVE NIFTI results
rawData.nframes = 1; %Set the 4th dimension 1

rawData.vol = eccentricity;
MRIwrite(rawData, 'eccentricity_map.nii.gz')
rawData.vol = angular;
MRIwrite(rawData, 'angular_map.nii.gz')
rawData.vol = exponent;
MRIwrite(rawData, 'exponent_map.nii.gz')
rawData.vol = rfsize;
MRIwrite(rawData, 'rfsize_map.nii.gz')
rawData.vol = R2;
MRIwrite(rawData, 'R2_map.nii.gz')
rawData.vol = gain;
MRIwrite(rawData, 'gain_map.nii.gz')

end
