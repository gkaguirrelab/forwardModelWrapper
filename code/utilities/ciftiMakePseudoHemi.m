function ciftiMakePseudoHemi(dtseriesImage, workDir, outputDir)
% Create pseudohemisphere CIFTI surfaces 
%
% Syntax:
%  ciftiMakePseudoHemi(dtseriesImage, workDir, outputDir)
%
% Description:
%   Create pseudohemisphere CIFTI surfaces by averagin cifti dtseries left 
%   and right hemispheres. The output image doesn't contain a 
%   volume component. from the LDOG project.
%
% Inputs:
%   dtseriesImage         - String. Full path to the intput dtseries image.
%   workDir               - String. Folder where the intermediate files
%                           will be saved
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

% Separate CIFTI into left, right and volume components
separateCifti = ['wb_command -cifti-separate' ' ' dtseriesImage ' ' 'COLUMN -volume-all' ' ' volumeOutput ' ' '-metric CORTEX_LEFT' ' ' leftHemisphere ' ' '-metric CORTEX_RIGHT' ' ' rightHemisphere];
fprintf('Separating cifti image into components\n')
system(separateCifti);

% Create another cifti from the original by removing  the volume component
origWithoutVol = fullfile(workDir, 'origWithoutVol.dtseries.nii');
createOrigWithoutVol = ['wb_command -cifti-create-dense-timeseries' ' ' origWithoutVol ' ' '-left-metric' ' ' leftHemisphere ' ' '-right-metric' ' ' rightHemisphere];
fprintf('Creating a CIFTI without the volume component\n')
system(createOrigWithoutVol);

% Flip left and right hemispheres and create another CIFTI image
reversedWithoutVol = fullfile(workDir, 'reversedWithoutVol.dtseries.nii');
createReversedWithoutVol = ['wb_command -cifti-create-dense-timeseries' ' ' reversedWithoutVol ' ' '-left-metric' ' ' rightHemisphere ' ' '-right-metric' ' ' leftHemisphere];
fprintf('Creating a reversed cifti\n')
system(createReversedWithoutVol);

% Average the original and reversed hemispheres 
[~,name,ext] = fileparts(dtseriesImage);
averagedImageName = ['pseudo_' name ext];
averagedImageSavePath = fullfile(outputDir, averagedImageName);
averageCommand = ['wb_command -cifti-average' ' ' averagedImageSavePath ' ' '-cifti' ' ' origWithoutVol ' ' '-cifti' ' ' reversedWithoutVol];
fprintf('Averaging the original and reversed cifti\n')
system(averageCommand);
fprintf('Done!')

end