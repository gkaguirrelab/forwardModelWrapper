function results = wrapperPRF(stimulus, data, vxs, varargin)
% Wrapper to manage inputs to Kendrick Kay's analyze pRF code
%
% Syntax:
%  results = wrapperPRF(stimulus, data, vxs)
%
% Description:
%   Wrapper around the analyzePRF function written by Kendrick Kay. The
%   main purpose of this function is to conver the input key-value pairs
%   from strings to numeric values as appropriate.
%
% Inputs:
%   stimulus              - Stimulus is a cell vector of R x C x time.
%                           If the cell size of input stimulus does not
%                           match the cell size of input data, the first
%                           cell is duplicated until they match. Be aware
%                           of this duplication if your stimulus time
%                           points are different accross runs.
%   data                  - If an ICAfix directory is specified, timeseries
%                           are extracted from all of the runs in the
%                           directory and reconstructed in a 1 x Run cell.
%                           Each image data is organized in those cells as
%                           voxels x time matrices. If a single file is
%                           specified, result is a similar matrix put in a
%                           1x1 cell.
%   vxs                   - Vector. Identifies the indices of the data to
%                           be analyzed. This is the implementation of a
%                           mask.
%
% Optional key/value pairs (text taken from analyzePRF):
%   tr                    - String. The TR in seconds (e.g. 1.5)
%  'wantglmdenoise'       - String. (optional) is whether to use GLMdenoise
%                           to determine nuisance regressors to add into
%                           the PRF model.  note that in order to use this
%                           feature, there must be at least two runs (and
%                           conditions must repeat across runs).
%                           We automatically determine the GLM design
%                           matrix based on the contents of <stimulus>.
%                           Special case is to pass in the noise regressors
%                           directly (e.g. from a previous call).default: 0
%  'hrf'                  - Numeric. (optional) A column vector with the
%                           hemodynamic response function (HRF) to use in
%                           the model. The first value of <hrf> should be
%                           coincident with the onset of the stimulus, and
%                           the HRF should indicate the timecourse of the
%                           response to a stimulus that lasts for one TR.
%                           Default is to use a canonical HRF (calculated
%                           using getcanonicalhrf(tr,tr)').
%  'maxpolydeg'           - String. Is a non-negative integer indicating
%                           the maximum polynomial degree to use for drift
%                           terms. Can be a vector whose length matches the
%                           number of runs in <data>.  default is to use
%                           round(L/2) where L is the number of minutes
%                           in the duration of a given run.
%  'seedmode'             - String. Is a vector consisting of one or
%                           more of the following values (we automatically
%                           sort and ensure uniqueness):
%                           0 means use generic large PRF seed
%                           1 means use generic small PRF seed
%                           2 means use best seed based on super-grid
%                           default: [0 1 2].
%  'xvalmode'             - String.
%                           0 means just fit all the data
%                           1 means two-fold cross-validation (first half
%                           of runs; second half of runs)
%                           2 means two-fold cross-validation (first half
%                           of each run; second half of each run)
%                           default: 0.  (note that we round when halving.)
%  'numperjob'            - String.[] means to run locally (not on the cluster)
%                           N where N is a positive integer indicating the
%                           number of voxels to analyze in each cluster job
%                           this option requires a customized computational
%                           setup! default: Na.
%  'maxiter'              - String. Is the maximum number of iterations.
%                           default: 500.
%  'display'              - String.is 'iter' | 'final' | 'off'.
%                           default: 'iter'.
%  'typicalgain'          - String. Is a typical value for the gain in
%                           each time-series. Default: 10.
%
% Outputs:
%   results               - Structure. Contains the results produced by
%                           the analyzePRF routine. 
%

%% Parse vargin for options passed here

p = inputParser; p.KeepUnmatched = true;

% Required
p.addRequired('stimulus', @iscell);
p.addRequired('data', @iscell);
p.addRequired('vxs', @isnumeric);

% Optional parameters
p.addParameter('tr',[],@isstr);
p.addParameter('hrf',[],@isnumeric);
p.addParameter('wantglmdenoise','0',@isstr);
p.addParameter('maxpolydeg','Na',@isstr);
p.addParameter('seedmode','[0 1 2]',@isstr);
p.addParameter('xvalmode','0',@isstr);
p.addParameter('numperjob','Na',@isstr);
p.addParameter('maxiter','500',@isstr);
p.addParameter('display','off',@isstr);
p.addParameter('typicalgain','10',@isstr);

% parse
p.parse(stimulus, data, vxs, varargin{:})


% We handle all key-value pairs as char vectors as this will be the form of
% input from the external call to the compiled code. We convert the strings
% here to numeric values as needed.
numericTypes = {'tr','wantglmdenoise','maxpolydeg','seedmode','xvalmode','numperjob','maxiter','typicalgain'};
for ii = 1:length(numericTypes)
    keyVal = p.Results.(numericTypes{ii});
    if strcmp(keyVal,'Na')
        keyVal = '[]';
    end
    evalString = [numericTypes{ii} ' = ' keyVal ';'];
    eval(evalString);
end

% analyzePRF is called with an struct variable that contains the options
analysisStructure = struct('vxs',vxs,'wantglmdenoise',wantglmdenoise,'hrf',p.Results.hrf, ...
    'maxpolydeg',maxpolydeg,'seedmode',seedmode,'xvalmode',xvalmode, ...
    'numperjob',numperjob,'maxiter',maxiter,'display',p.Results.display, ...
    'typicalgain',typicalgain);

% Run the function and return the results
results = analyzePRF(stimulus,data,tr,analysisStructure);

end % Main function
