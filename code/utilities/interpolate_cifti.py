import neuropythy as ny
import os 
import sys

def interpolate_cifti(subject_name, path_to_inferred_maps, path_to_hcp, output):

    sub = ny.hcp_subject(path_to_hcp, default_alignment='FS')
    angle_ecc_maps = {}
    angle_ecc_maps['lh.%s_inferred_angle' % subject_name] = ny.load(os.path.join(path_to_inferred_maps, 'lh.%s_inferred_angle.mgz' % subject_name))
    angle_ecc_maps['rh.%s_inferred_angle' % subject_name] = ny.load(os.path.join(path_to_inferred_maps, 'rh.%s_inferred_angle.mgz' % subject_name))
    angle_ecc_maps['lh.%s_inferred_eccen' % subject_name] = ny.load(os.path.join(path_to_inferred_maps, 'lh.%s_inferred_eccen.mgz' % subject_name))
    angle_ecc_maps['rh.%s_inferred_eccen' % subject_name] = ny.load(os.path.join(path_to_inferred_maps, 'rh.%s_inferred_eccen.mgz' % subject_name))
 
    other_maps_left = {}
    other_maps_left['lh.%s_inferred_sigma' % subject_name] = ny.load(os.path.join(path_to_inferred_maps, 'lh.%s_inferred_sigma.mgz' % subject_name))
    other_maps_left['lh.%s_inferred_varea' % subject_name] = ny.load(os.path.join(path_to_inferred_maps, 'lh.%s_inferred_varea.mgz' % subject_name))
    other_maps_left['lh.%s_inferred_cmf' % subject_name] = ny.load(os.path.join(path_to_inferred_maps, 'lh.%s_inferred_cmf.mgz' % subject_name))
    
    other_maps_right = {}
    other_maps_right['rh.%s_inferred_sigma' % subject_name] = ny.load(os.path.join(path_to_inferred_maps, 'rh.%s_inferred_sigma.mgz' % subject_name))
    other_maps_right['rh.%s_inferred_varea' % subject_name] = ny.load(os.path.join(path_to_inferred_maps, 'rh.%s_inferred_varea.mgz' % subject_name))    
    other_maps_right['rh.%s_inferred_cmf' % subject_name] = ny.load(os.path.join(path_to_inferred_maps, 'rh.%s_inferred_cmf.mgz' % subject_name))
     
    # Negate right hemi angles 
    right_hemi_angle = ny.load(os.path.join(path_to_inferred_maps, 'rh.%s_inferred_angle.mgz' % subject_name))
    right_hemi_angle_negated = right_hemi_angle * -1
    ny.save(os.path.join(path_to_inferred_maps, 'rh.%s_inferred_angle.mgz' % subject_name), right_hemi_angle_negated)

    # convert from angle/eccen to x/y (to avoid circular interpolation errors);
    # also, this function expects that 'polar_angle' means clockwise degrees from
    # vertical
    (x,y) = ny.as_retinotopy({'polar_angle':angle_ecc_maps['lh.%s_inferred_angle' % subject_name], 'eccentricity':angle_ecc_maps['lh.%s_inferred_eccen' % subject_name]}, 'geographical')
    # interpolate over to fs_LR 164k mesh
    (xLR, yLR) = sub.lh.interpolate(sub.hemis['lh_LR32k'], [x, y])
    # convert back to angle and eccen
    (angLR, eccLR) = ny.as_retinotopy({'x':xLR, 'y':yLR}, 'visual')
    
    ny.save(os.path.join(output, 'lh.%s_inferred_angle.nii' % subject_name), angLR)
    ny.save(os.path.join(output, 'lh.%s_inferred_eccen.nii' % subject_name), eccLR)
    
    # Convert right
    (x,y) = ny.as_retinotopy({'polar_angle':angle_ecc_maps['rh.%s_inferred_angle' % subject_name], 'eccentricity':angle_ecc_maps['rh.%s_inferred_eccen' % subject_name]}, 'geographical')
    # interpolate over to fs_LR 164k mesh
    (xLR, yLR) = sub.rh.interpolate(sub.hemis['rh_LR32k'], [x, y])
    # convert back to angle and eccen
    (angRR, eccRR) = ny.as_retinotopy({'x':xLR, 'y':yLR}, 'visual')
    
    ny.save(os.path.join(output, 'rh.%s_inferred_angle.nii' % subject_name), angRR)
    ny.save(os.path.join(output, 'rh.%s_inferred_eccen.nii' % subject_name), eccRR)
    
    for i in other_maps_left.keys():
        interpolated = sub.lh.interpolate(sub.hemis['lh_LR32k'], other_maps_left[i])
        name = str(i) + '.nii'
        ny.save(os.path.join(output, name), interpolated)
    for i in other_maps_right.keys():
        interpolated = sub.rh.interpolate(sub.hemis['rh_LR32k'], other_maps_right[i])
        name =  str(i) + '.nii'
        ny.save(os.path.join(output, name), interpolated)        

interpolate_cifti(*sys.argv[1:])
