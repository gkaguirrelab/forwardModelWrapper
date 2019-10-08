function [corr_mat] = make_corr_mat(session_dir,subject_name,visual_area,hemi)

%% set defaults
if ~exist('hemi','var')
    hemi = 'lh';
end
if ~exist('visual_area','var')
    visual_area = 'V1';
end
if ~exist('SUBJECTS_DIR','var')
    SUBJECTS_DIR = getenv('SUBJECTS_DIR');
end
anatdatadir = fullfile(SUBJECTS_DIR,subject_name);
%% Read in pRF area file, get ROI indices
areas = load_nifti(fullfile(session_dir,[hemi '.areas_pRF.nii.gz']));
if strcmp(visual_area,'V1')
    ROIind = find(areas.vol == -1 | areas.vol == 1);
elseif strcmp(visual_area,'V2')
    ROIind = find(areas.vol == -2 | areas.vol == 2);
elseif strcmp(visual_area,'V3')
    ROIind = find(areas.vol == -3 | areas.vol == 3);
elseif strcmp(visual_area,'Vall')
    ROIind = find(areas.vol >= -3 & areas.vol <= 3);
end
%% Get Ecc and Pol
ECC = load_nifti(fullfile(session_dir,[hemi '.ecc_pRF.nii.gz']));
POL = load_nifti(fullfile(session_dir,[hemi '.pol_pRF.nii.gz']));
ecc = ECC.vol(ROIind);
pol = POL.vol(ROIind);
%% Get sigma by eccentricty for visual field V1 - V1
% mmctx = nan(size(ROIind,1),1);
% for vtx = 1:size(ROIind,1);
%     dv = rf_ecc(ecc(vtx),'V1'); % degrees of visual angle (deg)
%     mag = cortical_mag(ecc(vtx),'V1'); % cortical magnification (mm2/deg2)
%     mmctx(vtx) = dv*mag; % sigma in mm2 ctx, based on receptive field size
% end
%% Assume point spread image (mm) is constant for now (3.5mm);
sig = 3.5;

%% Compute correlation matrix
corr_mat = nan(size(ROIind,1));
[verts] = freesurfer_read_surf(fullfile(anatdatadir,'surf',[hemi '.sphere']));
progBar=ProgressBar(size(ROIind,1),'Making correlation matrix...');
for vtx = 1:size(ROIind,1);
    tmpx = spherical_distance(subject_name,ROIind(vtx),verts,hemi);
    x = tmpx(ROIind);
    corr_mat(vtx,:) = exp(-(x.^2)/(2*sig.^2));
    if ~mod(vtx,100);progBar(vtx);end
end
