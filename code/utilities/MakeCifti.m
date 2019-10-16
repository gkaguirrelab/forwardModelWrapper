%function MakeCifti(leftHemiMap, rightHemiMap, leftAtlasROI, rightAtlasROI, templateDtseries, workbench_path, output)

leftHemiMap = '/home/ozzy/Desktop/area_experimentalis/lh.nii';
rightHemiMap = '/home/ozzy/Desktop/area_experimentalis/rh.nii';
rightAtlasROI = '/home/ozzy/Desktop/TOME_3045/MNINonLinear/fsaverage_LR32k/TOME_3045.R.atlasroi.32k_fs_LR.shape.gii';
leftAtlasROI = '/home/ozzy/Desktop/TOME_3045/MNINonLinear/fsaverage_LR32k/TOME_3045.L.atlasroi.32k_fs_LR.shape.gii';
templateDtseries = '/home/ozzy/Desktop/ang_map.dtseries.nii' ;
wb_command = workbench_path;

% Load neuropythy nifti interpolated maps
leftRaw = MRIread(leftHemiMap);
rightRaw = MRIread(rightHemiMap);

% Get the left and right hemi vectors
leftHemiData = leftRaw.vol(:);
rightHemiData = rightRaw.vol(:);

% Load templates
ciftiTemplate = ciftiopen(templateDtseries, wb_command);
leftAtlas = gifti(leftAtlasROI);
rightAtlas = gifti(rightAtlasROI);
leftAtlas = leftAtlas.cdata;
rightAtlas =rightAtlas.cdata;


zeroIdx = leftAtlas==0;
for ii = 1:length(leftHemiData)
    leftHemiData(zeroIdx) = nan;
    rightHemiData(zeroIdx) = nan;
end

%leftHemiData(any(isnan(leftHemiData), 2), :) = [];
%rightHemiData(any(isnan(rightHemiData), 2), :) = [];

other = 91282 - (length(leftHemiData) + length(rightHemiData));
other = zeros(other,1);
fullData = [leftHemiData; rightHemiData; other];
ciftiTemplate.cdata = fullData;
ciftisave(ciftiTemplate, '/home/ozzy/Desktop/budurpasa.dtseries.nii', wb_command)
%zeroVector = zeros(1, size(leftHemiData), size(rightHemiData));

%end 