import neuropythy as ny
import numpy as np

path_to_cifti_maps = '/home/ozzy/Desktop/lg/'
freesurfer_def_spehere_path_left = '/home/ozzy/Desktop/BENSON/DATA/TOME_3042_hcpstruct/TOME_3042/MNINonLinear/fsaverage/TOME_3042.L.def_sphere.164k_fs_L.surf.gii'
freesurfer_def_spehere_path_right = '/home/ozzy/Desktop/BENSON/DATA/TOME_3042_hcpstruct/TOME_3042/MNINonLinear/fsaverage/TOME_3042.R.def_sphere.164k_fs_R.surf.gii'
LR32k_sphere_left = '/home/ozzy/Desktop/BENSON/DATA/TOME_3042_hcpstruct/TOME_3042/MNINonLinear/fsaverage_LR32k/TOME_3042.L.sphere.32k_fs_LR.surf.gii'
LR32k_sphere_right = '/home/ozzy/Desktop/BENSON/DATA/TOME_3042_hcpstruct/TOME_3042/MNINonLinear/fsaverage_LR32k/TOME_3042.R.sphere.32k_fs_LR.surf.gii'
output = '/home/ozzy/Desktop/lg/mgzed/'

fsaverage_l = ny.load(freesurfer_def_spehere_path_left)
fsaverage_r = ny.load(freesurfer_def_spehere_path_right)
hcp_l = ny.load(LR32k_sphere_left)
hcp_r = ny.load(LR32k_sphere_right)

maps = {}
maps['angular_map'] = "%sangular_map.dtseries.nii"%path_to_cifti_maps
maps['eccentricity_map'] = "%seccentricity_map.dtseries.nii"%path_to_cifti_maps
maps['exponent_map'] = "%sexponent_map.dtseries.nii"%path_to_cifti_maps
maps['gain_map'] = "%sgain_map.dtseries.nii"%path_to_cifti_maps
maps['R2_map'] = "%sR2_map.dtseries.nii"%path_to_cifti_maps
maps['rfsize_map'] = "%srfsize_map.dtseries.nii"%path_to_cifti_maps

for i in maps.keys():
    print("writing %s to fsaverage"%i)
    image = ny.load(maps[i], 'cifti', to='image')
    idxmap = image.header.get_index_map(1)
    prefix = 'CIFTI_STRUCTURE_CORTEX_'
    hemi_tr = {'LEFT':'lh', 'RIGHT':'rh'}
    result = {}
    for (sname,hname) in hemi_tr.items():
        sname = prefix + sname
        mdl = next(u for u in idxmap.brain_models if u.brain_structure == sname)
        (i0,ii) = (mdl.index_offset, mdl.index_count)
        x = np.zeros(mdl.surface_number_of_vertices)
        idcs = np.array(mdl.vertex_indices)
        x[idcs] = image.dataobj[0,i0:(i0+ii)]
        result[hname] = x    
    interpolated_left = hcp_l.interpolate(fsaverage_l,result['lh'])
    interpolated_right = hcp_r.interpolate(fsaverage_r,result['rh'])
    savename_left = output + 'L_' + i + '.mgz'
    savename_right = output + 'R_' + i + '.mgz'
    ny.save(savename_left, interpolated_left)
    ny.save(savename_right, interpolated_right)
