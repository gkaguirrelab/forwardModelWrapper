import neuropythy as ny
import math
import numpy as np

###################### Set some paths #####################################################

#path_to_cifti_maps = '/home/ozzy/Desktop/TOME_3043/results/'
#path_to_subject = '/home/ozzy/Desktop/TOME_3043/TOME_3043_hcpstruct/TOME_3043'
#output = '/home/ozzy/Desktop/TOME_3043/results/mgzed'
##
path_to_cifti_maps = '/home/ozzy/Desktop/hcp_func_maps/'
path_to_subject = '/home/ozzy/Desktop/BENSON/Datasaver/DATA/TOME_3042_hcpstruct/TOME_3042'
output = '/home/ozzy/Desktop/hcp_func_maps/mgzed'

############# Load the FSLR_32k and native left and right hemispheres #####################

#sub = ny.hcp_subject(path_to_subject, default_alignment='FS')
sub = ny.hcp_subject(path_to_subject, default_alignment='MSMSulc')
hem_from_left = sub.hemis['lh_LR32k']
hem_to_left = sub.hemis['lh']
hem_from_right = sub.hemis['rh_LR32k']
hem_to_right = sub.hemis['rh']

############# Set a dictionary for the AnalyzePRF results #################################

maps = {}
maps['angle_map'] = "%sangle_map.dtseries.nii"%path_to_cifti_maps
maps['eccentricity_map'] = "%seccentricity_map.dtseries.nii"%path_to_cifti_maps
maps['exponent_map'] = "%sexponent_map.dtseries.nii"%path_to_cifti_maps
maps['gain_map'] = "%sgain_map.dtseries.nii"%path_to_cifti_maps
maps['R2_map'] = "%sR2_map.dtseries.nii"%path_to_cifti_maps
maps['rfsize_map'] = "%srfsize_map.dtseries.nii"%path_to_cifti_maps
maps['x_map'] = "%sx_map.dtseries.nii"%path_to_cifti_maps
maps['y_map'] = "%sy_map.dtseries.nii"%path_to_cifti_maps

############ Interpolate AnalyzePRF maps over subject's native surface ####################

for i in maps.keys():
    im = ny.load(maps[i])
    (lhdat, rhdat, other) = ny.hcp.cifti_split(im)   # Separate left and right hemispheres
    native_result_left = hem_from_left.interpolate(hem_to_left, lhdat)
    native_result_right = hem_from_right.interpolate(hem_to_right, rhdat)
    ny.save("%s/L_%s.mgz"%(output,i), native_result_left)
    ny.save("%s/R_%s.mgz"%(output,i), native_result_right)    

##################### Convert cartesian x-y maps to polar maps ############################      

path_to_left_x_mgz = output + '/L_x_map.mgz'
path_to_right_x_mgz = output + '/R_x_map.mgz'
path_to_left_y_mgz = output + '/L_y_map.mgz'
path_to_right_y_mgz = output + '/R_y_map.mgz'

left_x = ny.load(path_to_left_x_mgz)
left_y = ny.load(path_to_left_y_mgz)
right_x = ny.load(path_to_right_x_mgz)
right_y = ny.load(path_to_right_y_mgz)

left_angle_new_template = np.rad2deg(np.mod(np.arctan2(left_y,left_x), 2*np.pi))
left_eccentricity_new_template = np.sqrt(left_x**2 + left_y**2)
right_angle_new_template = np.rad2deg(np.mod(np.arctan2(right_y,right_x), 2*np.pi))
right_eccentricity_new_template = np.sqrt(right_x**2 + right_y**2)


###################### Wrap angle maps to -180 - 180 scale ################################

left_angle_converted = (np.abs(left_angle_new_template - 360) + 90) % 360
for i in range(len(left_angle_new_template)):
    if left_angle_converted[i] < -180 or left_angle_converted[i] > 180:
        left_angle_converted[i] = ((left_angle_converted[i] + 180) % 360) - 180

right_angle_converted = (np.abs(right_angle_new_template - 360) + 90) % 360
for i in range(len(right_angle_new_template)):
    if right_angle_converted[i] < -180 or right_angle_converted[i] > 180:
        right_angle_converted[i] = ((right_angle_converted[i] + 180) % 360) - 180


############################### Save results ##############################################

ny.save("%s/L_new_angle.mgz"%output, left_angle_new_template)  
ny.save("%s/L_new_eccen.mgz"%output, left_eccentricity_new_template)
ny.save("%s/R_new_angle.mgz"%output, right_angle_new_template)  
ny.save("%s/R_new_eccen.mgz"%output, right_eccentricity_new_template)  
ny.save("%s/L_new_angle_converted.mgz"%output, left_angle_converted)
ny.save("%s/R_new_angle_converted.mgz"%output, right_angle_converted)

