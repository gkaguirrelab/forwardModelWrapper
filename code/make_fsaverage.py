import sys
import neuropythy as ny
import numpy as np
import os 

def make_fsaverage(path_to_cifti_maps, path_to_hcp, alignment_type, native_mgz, native_mgz_pseudo_hemi):

############# Load the FSLR_32k and native left and right hemispheres #####################
    print('Starting')
    
    sub = ny.hcp_subject(path_to_hcp, default_alignment=alignment_type)
    hem_from_left = sub.hemis['lh_LR32k']
    hem_from_right = sub.hemis['rh_LR32k']
    hem_to_left = sub.hemis['lh']
    hem_to_right = sub.hemis['rh']
    
############# Set a dictionary for the AnalyzePRF results #################################
    
    maps = os.listdir(path_to_cifti_maps)
    
#### Interpolate AnalyzePRF maps over subject's native surface do the flip and average ####   
    
    print('Starting: Left-Right averaging and interpolation')
    
    for amap in maps:
        
        print('Processing %s'%amap)
       
        # Load the maps interpolate to native space and save the unprocessed 
        # mgz maps.
        tempim = ny.load(os.path.join(path_to_cifti_maps, amap))
        (orig_lhdat, orig_rhdat, orig_other) = ny.hcp.cifti_split(tempim)  
        original_result_left = hem_from_left.interpolate(hem_to_left, orig_lhdat)
        original_result_right = hem_from_right.interpolate(hem_to_right, orig_rhdat)
        ny.save(os.path.join(native_mgz,'L_%s.mgz'%amap[:-13]), original_result_left)
        ny.save(os.path.join(native_mgz,'R_%s.mgz'%amap[:-13]), original_result_right)
        
        # Get a copy of the unprocessed hemispheres and overwrite them with the
        # flipped versions. Getiing a copy to preserve the voxel information
        flipped_rhdat = orig_rhdat.copy()
        flipped_lhdat = orig_lhdat.copy()
        for length in range(len(orig_lhdat)):
            flipped_rhdat[length] = orig_lhdat[length]
            flipped_lhdat[length] = orig_rhdat[length]
        
        # Get another copy of the unprocessed images and overwrite them with
        # the flipped-unflipped averages
        final_averaged_left = orig_lhdat.copy()
        final_averaged_right = orig_rhdat.copy()
        for length in range(len(orig_lhdat)):
            if amap == 'cartX_map.dtseries.nii':
                final_averaged_left[length] = (orig_lhdat[length] + (-1 * flipped_lhdat[length]))/2
                final_averaged_right[length] = (orig_rhdat[length] + (-1 * flipped_rhdat[length]))/2
            else:
                final_averaged_left[length] = (orig_lhdat[length] + flipped_lhdat[length])/2
                final_averaged_right[length] = (orig_rhdat[length] + flipped_rhdat[length])/2
         
        # Interpolate the processed images and save them
        averaged_result_left = hem_from_left.interpolate(hem_to_left, final_averaged_left)
        averaged_result_right = hem_from_right.interpolate(hem_to_right, final_averaged_right)
        ny.save(os.path.join(native_mgz_pseudo_hemi,'L_%s.mgz'%amap[:-13]), averaged_result_left)
        ny.save(os.path.join(native_mgz_pseudo_hemi,'R_%s.mgz'%amap[:-13]), averaged_result_right)
    
##################### Convert cartesian x-y maps to polar maps ############################      
    
    print('Starting: Cartesian to polar angle conversion and rescaling')
    
    for i in range(2):
        if i == 0:
            variable = native_mgz
        elif i == 1: 
            variable = native_mgz_pseudo_hemi
            
        # Reload the X-Y cartesian images.
        left_x = ny.load(os.path.join(variable, 'L_cartX_map.mgz'))
        left_y = ny.load(os.path.join(variable, 'L_cartY_map.mgz'))
        right_x = ny.load(os.path.join(variable, 'R_cartX_map.mgz'))
        right_y = ny.load(os.path.join(variable, 'R_cartY_map.mgz'))
        
        # Calculate the angle and eccentricity
        left_angle_new_template = np.rad2deg(np.mod(np.arctan2(left_y,left_x), 2*np.pi))
        left_eccentricity_new_template = np.sqrt(left_x**2 + left_y**2)
        right_angle_new_template = np.rad2deg(np.mod(np.arctan2(right_y,right_x), 2*np.pi))
        right_eccentricity_new_template = np.sqrt(right_x**2 + right_y**2)
        
        # Overwriting the eccentricity maps with the new ones.
        ny.save(os.path.join(variable,'L_eccen_map.mgz'), left_eccentricity_new_template) 
        ny.save(os.path.join(variable,'R_eccen_map.mgz'), right_eccentricity_new_template) 
    
###################### Wrap angle maps to -180 - 180 scale ################################
        
        # Rescale the angle maps
        left_angle_converted = (np.abs(left_angle_new_template - 360) + 90) % 360
        for i in range(len(left_angle_new_template)):
            if left_angle_converted[i] < -180 or left_angle_converted[i] > 180:
                left_angle_converted[i] = ((left_angle_converted[i] + 180) % 360) - 180
        
        right_angle_converted = (np.abs(right_angle_new_template - 360) + 90) % 360
        for i in range(len(right_angle_new_template)):
            if right_angle_converted[i] < -180 or right_angle_converted[i] > 180:
                right_angle_converted[i] = ((right_angle_converted[i] + 180) % 360) - 180
        
        # Overwriting the angle maps with the new ones.
        ny.save(os.path.join(variable,'L_angle_map.mgz'), left_angle_converted)
        ny.save(os.path.join(variable,'R_angle_map.mgz'), right_angle_converted)

    print('Done !')

make_fsaverage(*sys.argv[1:])