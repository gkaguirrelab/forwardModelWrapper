function make_cifti(leftHemiMap, rightHemiMap, pathToHCP, templateDtseries, workbench_path, output)

% Load neuropythy nifti interpolated maps
leftRaw = MRIread(leftHemiMap);
rightRaw = MRIread(rightHemiMap);

% Get the left and right hemi vectors
leftHemiData = leftRaw.vol(:);
rightHemiData = rightRaw.vol(:);

% Load templates
ciftiTemplate = ciftiopen(templateDtseries, workbench_path);
leftAtlas = gifti(fullfile(pathToHCP,'MNINonLinear', 'fsaverage_LR32k', 'TOME_3045.L.atlasroi.32k_fs_LR.shape.gii'));
rightAtlas = gifti(fullfile(pathToHCP,'MNINonLinear', 'fsaverage_LR32k', 'TOME_3045.R.atlasroi.32k_fs_LR.shape.gii'));

% Concatanete AtlasROI vectors. These vectors are exactly the same for the 
% FSLR template but we concatenate to make it usable for non symetrical
% hemispheres
atlas = [leftAtlas.cdata; rightAtlas.cdata];

% Concatenate the hemispheres and set very large values to the vertices
% that do not belong in the hemisperes. We do not use nans or zeros in 
% case these values are present in the hemispheres as well.
fullData = [leftHemiData; rightHemiData];
zeroIdxL = atlas==0;
for ii = 1:length(fullData)
    fullData(zeroIdxL) = 9999;
end

% Get rid of the values that do not belong 
fullData(fullData==9999) = [];

% Calculate the number of subcortical vertices from atlases and concetenate
other = length(ciftiTemplate.cdata) - length(fullData);
other = zeros(other,1);
fullData = [fullData; other];

% Save to template
ciftiTemplate.cdata = fullData;
ciftisave(ciftiTemplate, output, workbench_path)

end 
