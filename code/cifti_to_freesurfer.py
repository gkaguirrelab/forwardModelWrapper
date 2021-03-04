import os, sys

def cifti_to_freesurfer(cifti_image, path_to_workbench, path_to_freesurfer_bin, path_to_subject_freesurfer, standard_mesh_atlases_folder, subject_id, workdir, native_mgz, fsaverage_mgz):
    
    '''
    This script maps cifti images to freesurfer native and fsaverage surfaces
    
    Inputs:
        cifti_image = Input cifti image
        path_to_workbench = Path to the folder where workbench commands are located
        path_to_freesurfer_bin = Freesurfer bin folder
        path_to_subject_freesurfer = Path to freesurfer subject dir 
        standard_mesh_atlases_folder = Path to standard Mesh atlases folder.
        subject_id = Subject Id. must match the freesurfer subject folder name in subjecs dir
        workdir = Workdir where the intermediate outputs will be saved 
        native_mgz = Folder where the native mgz results will be saved
        fsaverage_mgz = Folder where the fsaverage mgz results will be saved
    ''' 
        
    # Create the workdir, native and fsavrage folders if they don't exist
    if not os.path.exists(workdir):
        os.system('mkdir %s' % workdir)
    if not os.path.exists(native_mgz):
        os.system('mkdir %s' % native_mgz)
    if not os.path.exists(fsaverage_mgz):
        os.system('mkdir %s' % fsaverage_mgz)
    
    # Set new paths for cifti hemispheres
    cifti_left = os.path.join(workdir, 'cifti_left.func.gii')
    cifti_right = os.path.join(workdir, 'cifti_right.func.gii')
    
    # Separate cifti files 
    os.system('%s -cifti-separate %s COLUMN -metric CORTEX_LEFT %s -metric CORTEX_RIGHT %s' % (os.path.join(path_to_workbench, 'wb_command'),
                                                                                               cifti_image, os.path.join(workdir, cifti_left),
                                                                                               os.path.join(workdir, cifti_right)))
    
    #  Set paths for the files we use for fsaverage mapping
    current_sphere_left = os.path.join(standard_mesh_atlases_folder, 'resample_fsaverage', 'fs_LR-deformed_to-fsaverage.L.sphere.32k_fs_LR.surf.gii')
    new_sphere_left = os.path.join(standard_mesh_atlases_folder, 'resample_fsaverage', 'fsaverage_std_sphere.L.164k_fsavg_L.surf.gii')
    metric_out_left = os.path.join(workdir, '%s.L.32k_fsavg_L.func.gii' % subject_id)
    current_area_left = os.path.join(standard_mesh_atlases_folder, 'resample_fsaverage', 'fs_LR.L.midthickness_va_avg.32k_fs_LR.shape.gii')
    new_area_left = os.path.join(standard_mesh_atlases_folder, 'resample_fsaverage', 'fsaverage.L.midthickness_va_avg.164k_fsavg_L.shape.gii')
    
    current_sphere_right = os.path.join(standard_mesh_atlases_folder, 'resample_fsaverage', 'fs_LR-deformed_to-fsaverage.R.sphere.32k_fs_LR.surf.gii')
    new_sphere_right = os.path.join(standard_mesh_atlases_folder, 'resample_fsaverage', 'fsaverage_std_sphere.R.164k_fsavg_R.surf.gii')
    metric_out_right = os.path.join(workdir, '%s.R.32k_fsavg_R.func.gii' % subject_id)
    current_area_right = os.path.join(standard_mesh_atlases_folder, 'resample_fsaverage', 'fs_LR.R.midthickness_va_avg.32k_fs_LR.shape.gii')
    new_area_right = os.path.join(standard_mesh_atlases_folder, 'resample_fsaverage', 'fsaverage.R.midthickness_va_avg.164k_fsavg_R.shape.gii')
    
    # Run fsaverage conversion 
    left_hemi_run = '%s -metric-resample %s %s %s ADAP_BARY_AREA %s -area-metrics %s %s' % (os.path.join(path_to_workbench, 'wb_command'),
                                                                                            cifti_left, current_sphere_left, new_sphere_left,
                                                                                            metric_out_left, current_area_left,
                                                                                            new_area_left)
    right_hemi_run = '%s -metric-resample %s %s %s ADAP_BARY_AREA %s -area-metrics %s %s' % (os.path.join(path_to_workbench, 'wb_command'),
                                                                                            cifti_right, current_sphere_right, new_sphere_right,
                                                                                            metric_out_right, current_area_right,
                                                                                            new_area_right)
    os.system(left_hemi_run)
    os.system(right_hemi_run)
    
    # Convert fsaverage gifti to mgz
    metric_out_left_mgz = os.path.join(fsaverage_mgz, '%s.L.32k_fsavg_L.func.mgz' % subject_id)
    metric_out_right_mgz = os.path.join(fsaverage_mgz, '%s.R.32k_fsavg_R.func.mgz' % subject_id)
    os.system('%s %s %s' % (os.path.join(path_to_freesurfer_bin, 'mri_convert'), metric_out_left, metric_out_left_mgz))
    os.system('%s %s %s' % (os.path.join(path_to_freesurfer_bin, 'mri_convert'), metric_out_right, metric_out_right_mgz))
    
    # Map fsaverage to fsnative
    native_metric_left = os.path.join(native_mgz, '%s.L.32k_fsnative_L.func.mgz' % subject_id)
    native_metric_right = os.path.join(native_mgz, '%s.R.32k_fsnative_R.func.mgz' % subject_id)
    os.system('SUBJECTS_DIR=%s; %s --srcsubject fsaverage --trgsubject %s --hemi lh --sval %s --tval %s' % (path_to_subject_freesurfer,
                                                                                                            os.path.join(path_to_freesurfer_bin, 'mri_surf2surf'),
                                                                                                            subject_id, metric_out_left_mgz, native_metric_left))
    os.system('SUBJECTS_DIR=%s; %s --srcsubject fsaverage --trgsubject %s --hemi rh --sval %s --tval %s' % (path_to_subject_freesurfer,
                                                                                                            os.path.join(path_to_freesurfer_bin, 'mri_surf2surf'),
                                                                                                            subject_id, metric_out_right_mgz, native_metric_right))    
cifti_to_freesurfer(*sys.argv[1:])  