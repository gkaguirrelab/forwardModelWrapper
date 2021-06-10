function averagedImageSavePath =  ciftiMakePseudoHemi(dtseriesImage, workDir, outputDir, workbenchPath, varargin)
% Create pseudohemisphere CIFTI surfaces 
%
% Syntax:
%  ciftiMakePseudoHemi(dtseriesImage, workDir, outputDir, workbenchPath, varargin)
%
% Description:
%   Create pseudohemisphere CIFTI surfaces by averaging cifti dtseries left 
%   and right hemispheres. The output image doesn't contain a 
%   volume component.
%
% Inputs:
%   dtseriesImage         - String. Full path to the intput dtseries image.
%   workDir               - String. Folder where the intermediate files
%                           will be saved
%   outputDir             - String. Folder where the output will be saved
%   workbenchPath         - String. Path to workbench function folder
%   verbose               - Logical. If true, run verbose mode. Default:
%                           false
%   TR                    - Number. TR in milliseconds. Can be left empty 
%                           if using the function for a cifti map rather
%                           than a cifti timeseries image.
%                         
%
% Outputs:
%   none
%

%% Parse inputs
p = inputParser; p.KeepUnmatched = false;

% Required
p.addRequired('dtseriesImage',@isstr);
p.addRequired('workDir',@isstr);
p.addRequired('outputDir',@isstr);
p.addRequired('workbenchPath',@isstr);

% Optional
p.addParameter('verbose', false, @islogical)
p.addParameter('TR', '')

% Parse
p.parse(dtseriesImage, workDir, outputDir, workbenchPath, varargin{:})

% Create the workdir and outputdir if they don't exist
if ~exist(workDir)
    mkdir(workDir)
end
if ~exist(outputDir)
    mkdir(outputDir)
end
if isunix
    setenv('LD_LIBRARY_PATH', ['/usr/lib/x86_64-linux-gnu:',getenv('LD_LIBRARY_PATH')]);
end

% Check if cifti data is single TR. If not and TR not specified throw error
dataLoaded = ciftiopen(dtseriesImage);
dataSize = size(dataLoaded.cdata);
if dataSize(2)>1 && isempty(p.Results.TR)
    error('You have a timeseries data. Please specify a TR')
end

% Create output paths for volume, left and right hemi
volumeOutput = fullfile(workDir, 'volume.nii');
leftHemisphere = fullfile(workDir, 'leftHemi.func.gii');
rightHemisphere = fullfile(workDir, 'rightHemi.func.gii');
labelFile = fullfile(workDir, 'volumeLabels.nii');

% Create workbench command root 
workbenchCommand = workbenchPath;

% Separate CIFTI into left, right and volume components
separateCifti = [workbenchCommand ' ' '-cifti-separate' ' ' dtseriesImage ' ' 'COLUMN -volume-all' ' ' volumeOutput ' ' '-label' ' ' labelFile ' ' '-metric CORTEX_LEFT' ' ' leftHemisphere ' ' '-metric CORTEX_RIGHT' ' ' rightHemisphere];
if p.Results.verbose
    fprintf('Separating cifti image into components\n')
end
system(separateCifti);

% Convert TR to string
TRstr = num2str(p.Results.TR);

% Reconstruct the original cifti with the pieces we have
origImage = fullfile(workDir, 'origCifti.dtseries.nii');
createFlippedImage = [workbenchCommand ' ' '-cifti-create-dense-timeseries' ' ' origImage ' ' '-volume' ' ' volumeOutput ' ' labelFile ' ' '-left-metric' ' ' leftHemisphere ' ' '-right-metric' ' ' rightHemisphere ' ' '-timestep' ' ' TRstr];
if p.Results.verbose
    fprintf('Creating the original cifti\n')
end
system(createFlippedImage);

% Flip left and right hemispheres and create another CIFTI image
flippedImage = fullfile(workDir, 'flippedCifti.dtseries.nii');
createFlippedImage = [workbenchCommand ' ' '-cifti-create-dense-timeseries' ' ' flippedImage ' ' '-volume' ' ' volumeOutput ' ' labelFile ' ' '-left-metric' ' ' rightHemisphere ' ' '-right-metric' ' ' leftHemisphere ' ' '-timestep' ' ' TRstr];
if p.Results.verbose
    fprintf('Creating a reversed cifti\n')
end
system(createFlippedImage);

% Average the original and reversed hemispheres 
[~,name,ext] = fileparts(dtseriesImage);
averagedImageName = ['pseudo_' name ext];
averagedImageSavePath = fullfile(outputDir, averagedImageName);
averageCommand = [workbenchCommand ' ' '-cifti-average' ' ' averagedImageSavePath ' ' '-cifti' ' ' origImage ' ' '-cifti' ' ' flippedImage];
if p.Results.verbose
    fprintf('Averaging the original and reversed cifti\n')
end
system(averageCommand);
fprintf('Done!\n')

end