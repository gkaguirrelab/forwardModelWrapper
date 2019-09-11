import neuropythy as ny

path_to_cifti_maps = '/home/ozzy/Desktop/asildenemebu/'
path_to_subject = '/home/ozzy/Desktop/BENSON/Datasaver/DATA/TOME_3042_hcpstruct/TOME_3042'
output = '/home/ozzy/Desktop/asildenemebu/mgzed'

sub = ny.hcp_subject(path_to_subject, default_alignment='MSMSulc')
hem_from_left = sub.hemis['lh_LR32k']
hem_to_left = sub.hemis['lh']
hem_from_right = sub.hemis['rh_LR32k']
hem_to_right = sub.hemis['rh']

maps = {}
maps['angular_map'] = "%sangular_map.dtseries.nii"%path_to_cifti_maps
maps['eccentricity_map'] = "%seccentricity_map.dtseries.nii"%path_to_cifti_maps
maps['exponent_map'] = "%sexponent_map.dtseries.nii"%path_to_cifti_maps
maps['gain_map'] = "%sgain_map.dtseries.nii"%path_to_cifti_maps
maps['R2_map'] = "%sR2_map.dtseries.nii"%path_to_cifti_maps
maps['rfsize_map'] = "%srfsize_map.dtseries.nii"%path_to_cifti_maps

for i in maps.keys():
    im = ny.load(maps[i])
    (lhdat, rhdat, other) = ny.hcp.cifti_split(im)
    native_result_left = hem_from_left.interpolate(hem_to_left, lhdat)
    native_result_right = hem_from_right.interpolate(hem_to_right, rhdat)
    ny.save("%s/L_%s.mgz"%(output,i), native_result_left)
    ny.save("%s/R_%s.mgz"%(output,i), native_result_right)    
    
