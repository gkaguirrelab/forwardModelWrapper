function ciftiMakePseudoHemi(dtseriesImage, workDir, TR, outputDir)
% Create pseudohemisphere CIFTI surfaces 
%
% Syntax:
%  ciftiMakePseudoHemi(dtseriesImage, workDir, outputDir)
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
%   TR                    - Number. TR in milliseconds
%   outputDir             - String. Folder where the output will be saved
%                         
%
% Outputs:
%   none
%

% Create the workdir and outputdir if they don't exist
if ~exist(workDir)
    mkdir(workDir)
end
if ~exist(outputDir)
    mkdir(outputDir)
end

% Create output paths for volume, left and right hemi
volumeOutput = fullfile(workDir, 'volume.nii');
leftHemisphere = fullfile(workDir, 'leftHemi.func.gii');
rightHemisphere = fullfile(workDir, 'rightHemi.func.gii');
labelFile = fullfile(workDir, 'volumeLabels.nii');

% Separate CIFTI into left, right and volume components
separateCifti = ['wb_command -cifti-separate' ' ' dtseriesImage ' ' 'COLUMN -volume-all' ' ' volumeOutput ' ' '-label' ' ' labelFile ' ' '-metric CORTEX_LEFT' ' ' leftHemisphere ' ' '-metric CORTEX_RIGHT' ' ' rightHemisphere];
fprintf('Separating cifti image into components\n')
system(separateCifti);

% Convert TR to string
TRstr = num2str(TR);

% Reconstruct the original cifti with the pieces we have
origImage = fullfile(workDir, 'origCifti.dtseries.nii');
createFlippedImage = ['wb_command -cifti-create-dense-timeseries' ' ' origImage ' ' '-volume' ' ' volumeOutput ' ' labelFile ' ' '-left-metric' ' ' leftHemisphere ' ' '-right-metric' ' ' rightHemisphere ' ' '-timestep' ' ' TRstr];
fprintf('Creating the original cifti\n')
system(createFlippedImage);

% Flip left and right hemispheres and create another CIFTI image
flippedImage = fullfile(workDir, 'flippedCifti.dtseries.nii');
createFlippedImage = ['wb_command -cifti-create-dense-timeseries' ' ' flippedImage ' ' '-volume' ' ' volumeOutput ' ' labelFile ' ' '-left-metric' ' ' rightHemisphere ' ' '-right-metric' ' ' leftHemisphere ' ' '-timestep' ' ' TRstr];
fprintf('Creating a reversed cifti\n')
system(createFlippedImage);

% Average the original and reversed hemispheres 
[~,name,ext] = fileparts(dtseriesImage);
averagedImageName = ['pseudo_' name ext];
averagedImageSavePath = fullfile(outputDir, averagedImageName);
averageCommand = ['wb_command -cifti-average' ' ' averagedImageSavePath ' ' '-cifti' ' ' origImage ' ' '-cifti' ' ' flippedImage];
fprintf('Averaging the original and reversed cifti\n')
system(averageCommand);
fprintf('Done!\n')

end