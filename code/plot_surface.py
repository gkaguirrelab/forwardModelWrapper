import os
import sys
import nilearn
from nilearn import plotting
from matplotlib.pyplot import plt

def plot_surface(subject_id, path_to_R2_map, ldog_surface_and_calculations_folder, threshold, output):
    
    # This function makes surface plots from R2 stat maps.
    
    # Inputs
    # subject_id: Subject id that is appended in front of ldog images.
    # path_to_R2_map: Path to R2 volumetric stat map
    # ldog_surface_and_calculations_folder: Folder that contains the surface folder
    # and all invivo-exvivo calculations (specific to the ldog project)
    # threshold: Threshold for the surface maps
    # output: Folder to save the images. Images are prenamed, so only point to the
    # folder you want to save images to.
    
    threshold = float(threshold)
    
    # Set paths
    interpolated_map = os.path.join(ldog_surface_and_calculations_folder, '%s_surface_interpolated.nii.gz' % subject_id)
    orig_image = os.path.join(ldog_surface_and_calculations_folder, 'Woofsurfer', 'mri', 'T1.nii')
    lh_inf = os.path.join(ldog_surface_and_calculations_folder, 'Woofsurfer', 'surf', 'lh.inflated')
    rh_inf = os.path.join(ldog_surface_and_calculations_folder, 'Woofsurfer', 'surf', 'rh.inflated')
    sulc_map_lh = os.path.join(ldog_surface_and_calculations_folder, 'Woofsurfer', 'surf', 'lh.sulc')
    sulc_map_rh = os.path.join(ldog_surface_and_calculations_folder, 'Woofsurfer', 'surf', 'rh.sulc')
    
    #Set path to calculations 
    warp = os.path.join(ldog_surface_and_calculations_folder,'exvivo_warp_files', 'toEx1Warp.nii.gz')
    secondary_linear = os.path.join(ldog_surface_and_calculations_folder,'exvivo_warp_files', 'secondLinearAnts.mat')
    initial_linear = os.path.join(ldog_surface_and_calculations_folder,'exvivo_warp_files', 'initialLinearAnts.mat')
    register_dat = os.path.join(ldog_surface_and_calculations_folder, 'exvivo_warp_files', 'register.dat')
    
    # Apply the invivo to exvivo warp to the map (ldog specific step)
    os.system('/usr/lib/ants/antsApplyTransforms -d 3 -i %s -r %s -o %s -t %s -t %s -t %s' % (path_to_R2_map,
                                                                                              orig_image,
                                                                                              interpolated_map,
                                                                                              warp,
                                                                                              secondary_linear,
                                                                                              initial_linear))    
   
    # Interpolate and make the left and right hemispheres and save it to a temporary folder
    surfaces_folder = '/tmp/surfaces_folder'
    os.system('mkdir %s' % surfaces_folder)
    os.system('export FREESURFER_HOME=/freesurfer;/bin/bash -c \'source $FREESURFER_HOME/FreeSurferEnv.sh &>/dev/null\';export SUBJECTS_DIR=%s;/freesurfer/bin/mri_vol2surf --mov %s --ref %s --reg %s --srcsubject Woofsurfer --hemi %s --o %s' % (ldog_surface_and_calculations_folder, interpolated_map, interpolated_map, register_dat, 'lh', os.path.join(surfaces_folder, 'left_hemi.mgz')))
    os.system('export FREESURFER_HOME=/freesurfer;/bin/bash -c \'source $FREESURFER_HOME/FreeSurferEnv.sh &>/dev/null\';export SUBJECTS_DIR=%s;/freesurfer/bin/mri_vol2surf --mov %s --ref %s --reg %s --srcsubject Woofsurfer --hemi %s --o %s' % (ldog_surface_and_calculations_folder, interpolated_map, interpolated_map, register_dat, 'rh', os.path.join(surfaces_folder, 'right_hemi.mgz')))
  
    # Make the surface plots
    loaded_lh_map = nilearn.surface.load_surf_data(os.path.join(surfaces_folder, 'left_hemi.mgz'))
    loaded_rh_map = nilearn.surface.load_surf_data(os.path.join(surfaces_folder, 'right_hemi.mgz'))
    loaded_inflated_left = nilearn.surface.load_surf_mesh(lh_inf)
    loaded_inflated_right = nilearn.surface.load_surf_mesh(rh_inf)  
    fig1 = plt.figure(figsize=[11,6])
    fig2 = plt.figure(figsize=[11,6])
    fig3 = plt.figure(figsize=[11,6])
    fig4 = plt.figure(figsize=[11,6])
    plotting.plot_surf_stat_map(loaded_inflated_left, loaded_lh_map, bg_map=sulc_map_lh,
                                threshold=threshold, view='medial', title='left', figure=fig1, output_file=os.path.join(output,'%s_left_medial.png' % subject_id))
    plotting.plot_surf_stat_map(loaded_inflated_left, loaded_lh_map, bg_map=sulc_map_lh,
                                threshold=threshold, view='lateral', title='left', figure=fig2, output_file=os.path.join(output,'%s_left_lateral.png' % subject_id))    
    
    plotting.plot_surf_stat_map(loaded_inflated_right, loaded_rh_map, bg_map=sulc_map_rh,
                                threshold=threshold, view='medial', title='right', figure=fig3, output_file=os.path.join(output,'%s_right_medial.png' % subject_id))   
    plotting.plot_surf_stat_map(loaded_inflated_right, loaded_rh_map, bg_map=sulc_map_rh,
                                threshold=threshold, view='lateral', title='right', figure=fig4, output_file=os.path.join(output,'%s_right_lateral.png' % subject_id))     
    
plot_surface(*sys.argv[1:])   