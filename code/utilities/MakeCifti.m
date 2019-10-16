%function MakeCifti(leftHemiMap, rightHemiMap, leftAtlasROI, rightAtlasROI, templateDtseries, workbench_path, output)

leftHemiMap = '/home/ozenc/Desktop/volumed/L_angle.nii';
rightHemiMap = '/home/ozenc/Desktop/volumed/R_angle.nii';
rightAtlasROI = '/home/ozenc/Desktop/TOME_3045_hcpstruct/TOME_3045/MNINonLinear/fsaverage_LR32k/TOME_3045.R.atlasroi.32k_fs_LR.shape.gii';
leftAtlasROI = '/home/ozenc/Desktop/TOME_3045_hcpstruct/TOME_3045/MNINonLinear/fsaverage_LR32k/TOME_3045.L.atlasroi.32k_fs_LR.shape.gii';
templateDtseries = '/home/ozenc/Desktop/maps_cifti/ang_map.dtseries.nii' ;
wb_command = '/home/ozenc/workbench/bin_linux64/wb_command';

leftRaw = MRIread(leftHemiMap);
rightRaw = MRIread(rightHemiMap);

leftHemiData = leftRaw.vol(:);
rightHemiData = rightRaw.vol(:);
ciftiTemplate = ciftiopen(templateDtseries, wb_command);
leftAtlas = gifti(leftAtlasROI);
rightAtlas = gifti(rightAtlasROI);
leftAtlas = leftAtlas.cdata;
rightAtlas =rightAtlas.cdata;

zeroIdx = leftAtlas==0;
for ii = 1:length(leftHemiData)
    leftHemiData(zeroIdx) = 0;
    rightHemiData(zeroIdx) = 0;
end

other = 91282 - (length(leftHemiData) + length(rightHemiData));
other = zeros(other,1);
fullData = [leftHemiData; rightHemiData; other];
ciftiTemplate.cdata = fullData;
ciftisave(ciftiTemplate, '/home/ozenc/Desktop/budurpasa.dtseries.nii', wb_command)
%zeroVector = zeros(1, size(leftHemiData), size(rightHemiData));

%end 