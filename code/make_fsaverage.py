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
    
    maps = {}
    maps['angle_map'] = os.path.join(path_to_cifti_maps, 'ang_map.dtseries.nii')
    maps['eccentricity_map'] = os.path.join(path_to_cifti_maps, 'ecc_map.dtseries.nii')
    maps['exponent_map'] = os.path.join(path_to_cifti_maps, 'expt_map.dtseries.nii')
    maps['gain_map'] = os.path.join(path_to_cifti_maps, 'gain_map.dtseries.nii')
    maps['R2_map'] = os.path.join(path_to_cifti_maps, 'R2_map.dtseries.nii')
    maps['rfsize_map'] = os.path.join(path_to_cifti_maps, 'rfsize_map.dtseries.nii')
    maps['x_map'] = os.path.join(path_to_cifti_maps, 'cartX_map.dtseries.nii')
    maps['y_map'] = os.path.join(path_to_cifti_maps, 'cartY_map.dtseries.nii')
    maps['hrfshift_map'] = os.path.join(path_to_cifti_maps, 'hrfshift_map.dtseries.nii')
    
#### Interpolate AnalyzePRF maps over subject's native surface do the flip and average ####   
    print('Starting: Left-Right averaging and interpolation')
    
    for amap in maps.keys():
        
        print('Processing %s'%amap)
       
        # Load the maps interpolate to native space and save the unprocessed 
        # mgz maps.
        tempim = ny.load(maps[amap])
        (orig_lhdat, orig_rhdat, orig_other) = ny.hcp.cifti_split(tempim)  
        original_result_left = hem_from_left.interpolate(hem_to_left, orig_lhdat)
        original_result_right = hem_from_right.interpolate(hem_to_right, orig_rhdat)
        if amap == maps['x_map'] or amap == maps['y_map']:
            pass
        else:
            ny.save(os.path.join(native_mgz,'L_original_%s.mgz'%amap), original_result_left)
            ny.save(os.path.join(native_mgz,'R_original_%s.mgz'%amap), original_result_right)
        
        # Get a copy of the unprocessed hemispheres and overwrite them with the
        # flipped versions
        flipped_rhdat = orig_rhdat.copy()
        flipped_lhdat = orig_lhdat.copy()
        for length in range(len(orig_lhdat)):
            flipped_rhdat[length] = orig_lhdat[length]
            flipped_lhdat[length] = orig_rhdat[length]
        
        # Get another copy of the unprocessed images and overwrite and save 
        # them with the flipped-unflipped averages
        final_averaged_left = orig_lhdat.copy()
        final_averaged_right = orig_rhdat.copy()
        for length in range(len(orig_lhdat)):
            if amap == maps['x_map']:
                final_averaged_left[length] = (orig_lhdat[length] + (-1 * flipped_lhdat[length]))/2
                final_averaged_right[length] = (orig_rhdat[length] + (-1 * flipped_rhdat[length]))/2
            else:
                final_averaged_left[length] = (orig_lhdat[length] + flipped_lhdat[length])/2
                final_averaged_right[length] = (orig_rhdat[length] + flipped_rhdat[length])/2
         
        # Interpolate the processed images and save them
        averaged_result_left = hem_from_left.interpolate(hem_to_left, final_averaged_left)
        averaged_result_right = hem_from_right.interpolate(hem_to_right, final_averaged_right)
        ny.save(os.path.join(native_mgz_pseudo_hemi,'L_processed_%s.mgz'%amap), averaged_result_left)
        ny.save(os.path.join(native_mgz_pseudo_hemi,'R_processed_%s.mgz'%amap), averaged_result_right)
    
##################### Convert cartesian x-y maps to polar maps ############################      
   
    print('Starting: Cartesian to polar angle conversion')
    
    # Reload the X-Y cartesian images.
    left_x = ny.load(os.path.join(native_mgz_pseudo_hemi, 'L_processed_x_map.mgz'))
    left_y = ny.load(os.path.join(native_mgz_pseudo_hemi, 'L_processed_y_map.mgz'))
    right_x = ny.load(os.path.join(native_mgz_pseudo_hemi, 'R_processed_x_map.mgz'))
    right_y = ny.load(os.path.join(native_mgz_pseudo_hemi, 'R_processed_y_map.mgz'))
    
    # Calculate the angle and eccentricity
    left_angle_new_template = np.rad2deg(np.mod(np.arctan2(left_y,left_x), 2*np.pi))
    left_eccentricity_new_template = np.sqrt(left_x**2 + left_y**2)
    right_angle_new_template = np.rad2deg(np.mod(np.arctan2(right_y,right_x), 2*np.pi))
    right_eccentricity_new_template = np.sqrt(right_x**2 + right_y**2)
    
    # Overwriting the eccentricity maps with the new ones.
    ny.save(os.path.join(native_mgz_pseudo_hemi,'L_processed_eccentricity_map.mgz'), left_eccentricity_new_template) 
    ny.save(os.path.join(native_mgz_pseudo_hemi,'R_processed_eccentricity_map.mgz'), right_eccentricity_new_template) 
    
###################### Wrap angle maps to -180 - 180 scale ################################
    
    print('Starting: Rescaling angle maps')
    
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
    ny.save(os.path.join(native_mgz_pseudo_hemi,'L_processed_angle_map.mgz'), left_angle_converted)
    ny.save(os.path.join(native_mgz_pseudo_hemi,'R_processed_angle_map.mgz'), right_angle_converted)

    os.system("rm %s"%os.path.join(native_mgz_pseudo_hemi,'*_x_map.mgz'))
    os.system("rm %s"%os.path.join(native_mgz_pseudo_hemi,'*_y_map.mgz'))
    os.system("rm %s"%os.path.join(native_mgz,'*_x_map.mgz'))
    os.system("rm %s"%os.path.join(native_mgz,'*_y_map.mgz'))    

    print('Done !')

make_fsaverage(*sys.argv[1:])