function results = WrapperAnalyzePRF(stimulus, data, tr, varagin)
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
%   workbench_path        - String. path to workbench_command
%   stimFileName          - String. .mat file. Provides the apertures as a  
%                           cell vector of R x C x time. Values should be 
%                           in [0,1].The number of time points can differ 
%                           across runs. The variable needs be named
%                           stimulus.
%   dataFileName          - String. Provides the data as a cell vector of 
%                           voxels x time.the number of time points should 
%                           match the number of time points in <stimulus>.
%   dataFileType          - String. Select whether the data is volumetric
%                           surface(CIFTI).
%   tr                    - String. The TR in seconds (e.g. 1.5)                          
%   outpath               - String. Output path without the save file name.
%                           needs to end with a /
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
%  'xvalmode'              - String.
%                           0 means just fit all the data
%                           1 means two-fold cross-validation (first half 
%                           of runs; second half of runs)
%                           2 means two-fold cross-validation (first half               
%                           of each run; second half of each run)
%                           default: 0.  (note that we round when halving.)
%  'numperjob'             - String.[] means to run locally (not on the cluster)
%                           N where N is a positive integer indicating the 
%                           number of voxels to analyze in each cluster job
%                           this option requires a customized computational 
%                           setup! default: Na.
%  'maxiter'               - String. Is the maximum number of iterations.  
%                           default: 500.
%  'display'               - String.is 'iter' | 'final' | 'off'.  
%                           default: 'iter'.
%  'typicalgain'           - String. Is a typical value for the gain in 
%                           each time-series. Default: 10.
%  'maskFileName'          - String. Path to the mask. If not used, all
%                           voxels in the data file are analyzed.
%  'prependDummyTRs'       - String. Used when the stimulus and data
%                           lengths are not equal and the inequality is 
%                           caused due to the removal of dummy TRs from
%                           the sample. Calculates the mean along the time
%                           dimension for each voxel and adds that mean at
%                           the beginning of the data (multiple times if
%                           required until data and stimulus sample lengths
%                           are exactly the same. Don't use this option if
%                           the difference is due to sampling. 1 for true 
%                           and 0 for false. Default = 0 (false)
%   'thresholdData'        - String. Threshold with this percent. Default:10
%   'pixelToDegree'        - String. If a pixel to degree number is
%                           specified, eccentricity values are represented 
%                           on this scale.
%   'convertAngleForBayes' - String. Converts angle so that the results can
%                           be used as inputs in the Bayesian Analysis of  
%                           Retinotopic Maps (Benson & Winawer,2018). Polar
%                           angle is converted in a way that -90 and 90 
%                           degrees will correspond to left and right 
%                           horizontal meridians and upper and lower 
%                           vertical meridians will be 0 and ±180 degrees 
%                           respectively. 1:True, 0:False. Default:1.
%
% Outputs:
%   none
%

%% Parse vargin for options passed here

p = inputParser; p.KeepUnmatched = true;

% Required  
p.addRequired('stimulus', @iscell);
p.addRequired('data', @iscell);
p.addRequired('tr', @isstr);

% Optional parameters
p.addParameter('wantglmdenoise',"0",@isstr);
p.addParameter('hrf',"Na",@isstr);   %MAT FILE, COLUMN VECTOR
p.addParameter('maxpolydeg',"Na",@isstr);
p.addParameter('seedmode','[0 1 2]',@isstr);
p.addParameter('xvalmode',"0",@isstr);
p.addParameter('numperjob',"Na",@isstr);
p.addParameter('maxiter',"500",@isstr);
p.addParameter('display',"iter",@isstr);
p.addParameter('typicalgain',"10",@isstr);

% parse
p.parse(stimulus, data, tr, varargin{:})

% MCR only accepts strings. This part converts variables which are passed
% as strings to vectors and numericals.
tr = str2double(tr);

new_seedmode = [];
if p.Results.maxpolydeg ~= "Na"
    new_maxpolydeg = str2double(p.Results.maxpolyreg);
else 
    new_maxpolydeg = [];
end

if p.Results.numperjob ~= "Na"
    new_numperjob = str2double(p.Results.numperjob);
else
    new_numperjob = [];
end

if p.Results.hrf ~= "Na"
    new_hrf = load(p.Results.hrf,'hrf');
    new_hrf = new_hrf.hrf;
else
    new_hrf = [];
end 

listofnums = ['0','1','2','3','4','5','6','7','8','9'];
for ii = p.Results.seedmode
    if ismember(ii, listofnums)
        new_seedmode = [new_seedmode,str2double(ii)];
    end
end

% Prepare the final structure and convert the remaining variables to
% numerical
analysisStructure = struct('vxs',vxs,'wantglmdenoise',str2double(p.Results.wantglmdenoise),'hrf',new_hrf, ...
    'maxpolydeg',new_maxpolydeg,'seedmode',new_seedmode,'xvalmode',str2double(p.Results.xvalmode), ...
    'numperjob',new_numperjob,'maxiter',str2double(p.Results.maxiter),'display',p.Results.display, ...
    'typicalgain',str2double(p.Results.typicalgain));

% Run the function and save the results.mat
results = analyzePRF(stimulus,data,tr,analysisStructure);
save(strcat(outpath,"retinotopy_results.mat"),'results')

%% Load the raw image again to modify and make maps

if dataFileType == "volumetric"
    rawData = MRIread(p.Results.dataFileName);
    %MAKE 3D
    getsize = size(rawData.vol); %Get the size of the original scan 
    % Results converted 2D -> 3D
    results.ecc = reshape(results.ecc,[getsize(1) getsize(2) getsize(3) 1]);
    results.ang = reshape(results.ang,[getsize(1) getsize(2) getsize(3) 1]);
    results.expt = reshape(results.expt,[getsize(1) getsize(2) getsize(3) 1]);
    results.rfsize = reshape(results.rfsize,[getsize(1) getsize(2) getsize(3) 1]);
    results.R2 = reshape(results.R2,[getsize(1) getsize(2) getsize(3) 1]);
    results.gain = reshape(results.gain,[getsize(1) getsize(2) getsize(3) 1]);
else 
    rawData = ciftiopen(rawName{1,1}, workbench_path);
end

% Whenever there is a zero value in ecccentricity map set angle to NaN.
% Changes the original output values
zero_indices_ecc = find(results.ecc == 0);
for zero_vals = zero_indices_ecc'
    results.ang(zero_vals) = NaN;
end

% Replace ecc values with NaN if they are larger than 90 pixels
results.ecc(results.ecc > 90) = NaN;

%%%Pixel to Degrees conversion. Changes the original output values
if p.Results.pixelToDegree ~= "Na"
    results.ecc = results.ecc ./ str2double(p.Results.pixelToDegree);
    results.rfsize = results.rfsize ./ str2double(p.Results.pixelToDegree);
end

% Create cartesian maps
vector_length = length(results.ecc);
x_map = [];
y_map = [];
for ii = 1:vector_length
    temporary_ecc = results.ecc(ii);
    temporary_ang = results.ang(ii); 
    x_map(ii) = temporary_ecc * cosd(temporary_ang);
    y_map(ii) = temporary_ecc * sind(temporary_ang);
end
x_map = x_map';
y_map = y_map';

%~~~~~~~~COMMENTED OUT. WE DO THIS IN THE PYTHON SCRIPT NOW~~~~~~~~~~~~~ 
%%% The output of this analysis will be used in Bayesian Analysis of  
%%% Retinotopic Maps (Benson & Winawer,2018). Therefore the polar angle 
%%% should be converted in a way that -90 and 90 degrees will correspond 
%%% to left and right horizontal meridians and upper and lower vertical 
%%% meridians will be 0 and ±180 degrees respectively.
%if p.Results.convertAngleForBayes ~= "0" 
%    %angle_converted = wrapTo180(wrapTo360(abs(results.ang-360)+90));
%    angle_converted = mod(abs(results.ang-360)+90,360);
%    idx = (angle_converted < -180) | (180 < angle_converted);
%    angle_converted(idx) = mod(angle_converted(idx) + 180,360) - 180; 
%end

%%% Divide R2 by 100 and set negative values to zero and values larger than
%%% 1 to 1 - Changes the original output values.
results.R2 = results.R2 ./ 100;
results.R2(results.R2 < 0) = 0;

%%% THRESHOLDING - Does not change the original output values. Creates another
%%% variable for the thresholded values
if p.Results.thresholdData ~= "Na"
    threshold = str2double(p.Results.thresholdData); % Convert string to num
    ins = find(results.R2 < threshold); % Find the indices under threshold
    results_thresh = results; 
    for ii = ins'  % Remove the values under threshold from all maps
        results_thresh.ang(ii) = 0;
        results_thresh.ecc(ii) = 0;
        results_thresh.expt(ii) = 0;
        results_thresh.rfsize(ii) = 0;
        results_thresh.R2(ii) = 0;
        results_thresh.gain(ii) = 0;
        results_thresh.converted_angle(ii) = 0;
    end
end

%SAVE NIFTI or CIFTI results
if dataFileType == "volumetric"
    rawData.nframes = 1; %Set the 4th dimension 1
    rawData.vol = results.ecc;
    MRIwrite(rawData, strcat(outpath,'eccentricity_map.nii.gz'))
    rawData.vol = results.ang;
    MRIwrite(rawData, strcat(outpath,'angle_map.nii.gz'))
    rawData.vol = results.expt;
    MRIwrite(rawData, strcat(outpath,'exponent_map.nii.gz'))
    rawData.vol = results.rfsize;
    MRIwrite(rawData, strcat(outpath,'rfsize_map.nii.gz'))
    rawData.vol = results.R2;
    MRIwrite(rawData, strcat(outpath,'R2_map.nii.gz'))
    rawData.vol = results.gain;
    MRIwrite(rawData, strcat(outpath,'gain_map.nii.gz'))
    rawData.vol = x_map;
    MRIwrite(rawData, strcat(outpath,'x_map.nii.gz'))
    rawData.vol = y_map;
    MRIwrite(rawData, strcat(outpath,'y_map.nii.gz'))
    if p.Results.thresholdData ~= "Na"
        rawData.nframes = 1; %Set the 4th dimension 1
        rawData.vol = results_thresh.ecc;
        MRIwrite(rawData, strcat(outpath,'thresh_eccentricity_map.nii.gz'))
        rawData.vol = results_thresh.ang;
        MRIwrite(rawData, strcat(outpath,'thresh_angle_map.nii.gz'))
        rawData.vol = results_thresh.expt;
        MRIwrite(rawData, strcat(outpath,'thresh_exponent_map.nii.gz'))
        rawData.vol = results_thresh.rfsize;
        MRIwrite(rawData, strcat(outpath,'thresh_rfsize_map.nii.gz'))
        rawData.vol = results_thresh.R2;
        MRIwrite(rawData, strcat(outpath,'thresh_R2_map.nii.gz'))
        rawData.vol = results_thresh.gain;
        MRIwrite(rawData, strcat(outpath,'thresh_gain_map.nii.gz'))
    end
    
elseif dataFileType == "cifti"
    rawData.cdata = results.ecc;
    ciftisave(rawData, strcat(outpath,'eccentricity_map.dtseries.nii'), workbench_path)
    rawData.cdata = results.ang;
    ciftisave(rawData, strcat(outpath,'angle_map.dtseries.nii'), workbench_path)
    rawData.cdata = results.expt;
    ciftisave(rawData, strcat(outpath,'exponent_map.dtseries.nii'), workbench_path)
    rawData.cdata = results.rfsize;
    ciftisave(rawData, strcat(outpath,'rfsize_map.dtseries.nii'), workbench_path)
    rawData.cdata = results.R2;
    ciftisave(rawData, strcat(outpath,'R2_map.dtseries.nii'), workbench_path)
    rawData.cdata = results.gain;
    ciftisave(rawData, strcat(outpath,'gain_map.dtseries.nii'), workbench_path) 
    rawData.cdata = x_map;
    ciftisave(rawData, strcat(outpath,'x_map.dtseries.nii'), workbench_path)
    rawData.cdata = y_map;
    ciftisave(rawData, strcat(outpath,'y_map.dtseries.nii'), workbench_path) 
%     if p.Results.convertAngleForBayes ~= "0"
%         rawData.cdata = angle_converted;
%         ciftisave(rawData, strcat(outpath,'converted_angle_map.dtseries.nii'), workbench_path)     
%     end    
    if p.Results.thresholdData ~= "Na"
        rawData.cdata = results_thresh.ecc;
        ciftisave(rawData, strcat(outpath,'thresh_eccentricity_map.dtseries.nii'), workbench_path)
        rawData.cdata = results_thresh.ang;
        ciftisave(rawData, strcat(outpath,'thresh_angle_map.dtseries.nii'), workbench_path)
        rawData.cdata = results_thresh.expt;
        ciftisave(rawData, strcat(outpath,'thresh_exponent_map.dtseries.nii'), workbench_path)
        rawData.cdata = results_thresh.rfsize;
        ciftisave(rawData, strcat(outpath,'thresh_rfsize_map.dtseries.nii'), workbench_path)
        rawData.cdata = results_thresh.R2;
        ciftisave(rawData, strcat(outpath,'thresh_R2_map.dtseries.nii'), workbench_path)
        rawData.cdata = results_thresh.gain;
        ciftisave(rawData, strcat(outpath,'thresh_gain_map.dtseries.nii'), workbench_path)
%         if p.Results.convertAngleForBayes ~= "0"
%             rawData.cdata = results_thresh.converted_angle;
%             ciftisave(rawData, strcat(outpath,'thresh_converted_angle_map.dtseries.nii'), workbench_path)
%         end
    end
end
end
