# This is not a part of the AnalyzePRF gear. It is used in the Bayesian Fitting gear because we don't pass hcp-struct results to AnalyzePRF


import neuropythy as ny
import math

path_to_cifti_maps = '/home/ozzy/Desktop/asildenemebu/'
path_to_subject = '/home/ozzy/Desktop/BENSON/Datasaver/DATA/TOME_3042_hcpstruct/TOME_3042'
output = '/home/ozzy/Desktop/asildenemebu/mgzed'

sub = ny.hcp_subject(path_to_subject, default_alignment='MSMSulc')
hem_from_left = sub.hemis['lh_LR32k']
hem_to_left = sub.hemis['lh']
hem_from_right = sub.hemis['rh_LR32k']
hem_to_right = sub.hemis['rh']

maps = {}
maps['angular_map'] = "%sangle_map.dtseries.nii"%path_to_cifti_maps
maps['eccentricity_map'] = "%seccentricity_map.dtseries.nii"%path_to_cifti_maps
maps['exponent_map'] = "%sexponent_map.dtseries.nii"%path_to_cifti_maps
maps['gain_map'] = "%sgain_map.dtseries.nii"%path_to_cifti_maps
maps['R2_map'] = "%sR2_map.dtseries.nii"%path_to_cifti_maps
maps['rfsize_map'] = "%srfsize_map.dtseries.nii"%path_to_cifti_maps
#maps['converted_angle_map'] = "%sconverted_angle_map.dtseries.nii"%path_to_cifti_maps
maps['x_map'] = "%sx_map.dtseries.nii"%path_to_cifti_maps
maps['y_map'] = "%sy_map.dtseries.nii"%path_to_cifti_maps

for i in maps.keys():
    im = ny.load(maps[i])
    (lhdat, rhdat, other) = ny.hcp.cifti_split(im)
    native_result_left = hem_from_left.interpolate(hem_to_left, lhdat)
    native_result_right = hem_from_right.interpolate(hem_to_right, rhdat)
    ny.save("%s/L_%s.mgz"%(output,i), native_result_left)
    ny.save("%s/R_%s.mgz"%(output,i), native_result_right)    
        
path_to_left_x_mgz = output + '/L_x_map.mgz'
path_to_right_x_mgz = output + '/R_x_map.mgz'
path_to_left_y_mgz = output + '/L_y_map.mgz'
path_to_right_y_mgz = output + '/R_y_map.mgz'

left_x = ny.load(path_to_left_x_mgz)
print(len(left_x))
right_x = ny.load(path_to_right_y_mgz)
print(len(right_x))
left_y = ny.load(path_to_left_y_mgz)
print(len(left_y))
right_y = ny.load(path_to_right_y_mgz)
print(len(right_y))

left_length = len(left_x)
right_length = len(right_x)
left_angle_new_template = left_x
left_eccentricity_new_template = left_x
right_angle_new_template = right_x
right_eccentricity_new_template = right_x

for i in range(left_length):
    temp_x = left_x[i]
    temp_y = left_y[i]
    left_angle_new_template[i] = math.atan2(temp_y,temp_x)
    left_eccentricity_new_template[i] = math.sqrt(temp_x ** 2 + temp_y ** 2)

for ii in range (right_length):
    temp_x = right_x[ii]
    temp_y = right_y[ii]
    right_angle_new_template[ii] = math.atan2(temp_y,temp_x)
    right_eccentricity_new_template[ii] = math.sqrt(temp_x ** 2 + temp_y ** 2)  
    
ny.save("%s/L_new_angle.mgz"%output, left_angle_new_template)  
ny.save("%s/L_new_eccen.mgz"%output, left_eccentricity_new_template)
ny.save("%s/R_new_angle.mgz"%output, right_angle_new_template)  
ny.save("%s/R_new_eccen.mgz"%output, left_eccentricity_new_template)  
    
    
    