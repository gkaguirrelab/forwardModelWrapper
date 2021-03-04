import os, sys
import nibabel as nb

def cifti_to_freesurfer(path_to_cifti_maps, path_to_workbench, path_to_freesurfer_bin, path_to_subject_freesurfer, standard_mesh_atlases_folder, subject_id, workdir, native_mgz, native_mgz_pseudo_hemi):
    
    '''
    This script maps cifti images to freesurfer native and fsaverage surfaces
    
    Inputs:
        path_to_cifti_maps = Folder containing cifti maps
        path_to_workbench = Path to the folder where workbench commands are located
        path_to_freesurfer_bin = Freesurfer bin folder where freesurfer functions are located
        path_to_subject_freesurfer = Path to freesurfer subject dir. This is specified by $SUBJECTS_DIR when freesurfer is installed
        standard_mesh_atlases_folder = Path to standard Mesh atlases folder. Zipped version can be found in forwardModelWrapper utilities 
        subject_id = Subject Id. Must match the subject folder located in path_to_subject_freesurfer
        workdir = Workdir where the intermediate outputs will be saved 
        native_mgz = Folder where the native mgz results will be saved
        native_mgz_pseudo_hemi = Folder where the pseudo hemi mgz results will be saved
    ''' 
        
    # Create the workdir, native and fsavrage folders if they don't exist
    if not os.path.exists(workdir):
        os.system('mkdir %s' % workdir)
    if not os.path.exists(native_mgz):
        os.system('mkdir %s' % native_mgz)
    if not os.path.exists(native_mgz_pseudo_hemi):
        os.system('mkdir %s' % native_mgz_pseudo_hemi)

    for amap in os.listdir(path_to_cifti_maps):
        
        # Get file location
        initial_file_location = os.path.join(path_to_cifti_maps, amap)
        
        # Get image name
        amap_name = os.path.split(amap)[1][:-13]
        
        # Set new paths for cifti hemispheres in gifti format
        cifti_left = os.path.join(workdir, 'cifti_left.func.gii')
        cifti_right = os.path.join(workdir, 'cifti_right.func.gii')
        
        # Separate cifti files 
        os.system('%s -cifti-separate %s COLUMN -metric CORTEX_LEFT %s -metric CORTEX_RIGHT %s' % (os.path.join(path_to_workbench, 'wb_command'),
                                                                                                   initial_file_location, os.path.join(workdir, cifti_left),
                                                                                                   os.path.join(workdir, cifti_right)))
        
        # Here we average left and right hemispheres at the gifti stage to make pseudohemispheres
        cifti_left_loaded = nb.load(cifti_left)
        cifti_right_loaded = nb.load(cifti_right)   
        cifti_left_data = cifti_left_loaded.darrays[0].data
        cifti_right_data = cifti_right_loaded.darrays[0].data 
        averaged_hemi_left = nb.load(cifti_left) # We load the left hemi again to use as a averaged map template
        averaged_hemi_right = nb.load(cifti_right) # We load the right hemi again to use as a averaged map template       
        averaged_hemi_left_data = averaged_hemi_left.darrays[0].data          
        averaged_hemi_right_data = averaged_hemi_right.darrays[0].data    
       
        averaged_hemi_left_file = os.path.join(workdir, 'averaged_hemi_left.func.gii')
        averaged_hemi_right_file = os.path.join(workdir, 'averaged_hemi_right.func.gii')    
        
        for val in range(len(cifti_left_data)):
            average_val = (cifti_left_data[val] + cifti_right_data[val])/2
            averaged_hemi_left_data[val] = average_val
            averaged_hemi_right_data[val] = average_val
        nb.save(averaged_hemi_left, averaged_hemi_left_file)    
        nb.save(averaged_hemi_right, averaged_hemi_right_file)  
        
        #  Set paths for the files we use for fsaverage mapping
        current_sphere_left = os.path.join(standard_mesh_atlases_folder, 'resample_fsaverage', 'fs_LR-deformed_to-fsaverage.L.sphere.32k_fs_LR.surf.gii')
        new_sphere_left = os.path.join(standard_mesh_atlases_folder, 'resample_fsaverage', 'fsaverage_std_sphere.L.164k_fsavg_L.surf.gii')
        metric_out_left = os.path.join(workdir, '%s.L.32k_fsavg_L.func.gii' % subject_id)
        metric_out_pseudo_left = os.path.join(workdir, '%s.L.32k_fsavg_pseudo_L.func.gii' % subject_id)
        current_area_left = os.path.join(standard_mesh_atlases_folder, 'resample_fsaverage', 'fs_LR.L.midthickness_va_avg.32k_fs_LR.shape.gii')
        new_area_left = os.path.join(standard_mesh_atlases_folder, 'resample_fsaverage', 'fsaverage.L.midthickness_va_avg.164k_fsavg_L.shape.gii')
        
        current_sphere_right = os.path.join(standard_mesh_atlases_folder, 'resample_fsaverage', 'fs_LR-deformed_to-fsaverage.R.sphere.32k_fs_LR.surf.gii')
        new_sphere_right = os.path.join(standard_mesh_atlases_folder, 'resample_fsaverage', 'fsaverage_std_sphere.R.164k_fsavg_R.surf.gii')
        metric_out_right = os.path.join(workdir, '%s.R.32k_fsavg_R.func.gii' % subject_id)
        metric_out_pseudo_right = os.path.join(workdir, '%s.R.32k_fsavg_pseudo_R.func.gii' % subject_id)
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
        left_hemi_pseudo_run = '%s -metric-resample %s %s %s ADAP_BARY_AREA %s -area-metrics %s %s' % (os.path.join(path_to_workbench, 'wb_command'),
                                                                                                       averaged_hemi_left_file, current_sphere_left, new_sphere_left,
                                                                                                       metric_out_pseudo_left, current_area_left,
                                                                                                       new_area_left)    
        right_hemi_pseudo_run = '%s -metric-resample %s %s %s ADAP_BARY_AREA %s -area-metrics %s %s' % (os.path.join(path_to_workbench, 'wb_command'),
                                                                                                        averaged_hemi_right_file, current_sphere_right, new_sphere_right,
                                                                                                        metric_out_pseudo_right, current_area_right,
                                                                                                        new_area_right)    
        
        os.system(left_hemi_run)
        os.system(right_hemi_run)
        os.system(left_hemi_pseudo_run)
        os.system(right_hemi_pseudo_run)  
        
        # Convert fsaverage gifti to mgz
        metric_out_left_mgz = os.path.join(workdir, 'L_%s.mgz' % amap_name)
        metric_out_right_mgz = os.path.join(workdir, 'R_%s.mgz' % amap_name)
        metric_out_pseudo_left_mgz = os.path.join(workdir, 'L_pseudo_%s.mgz' % amap_name)
        metric_out_pseudo_right_mgz = os.path.join(workdir, 'R_pseudo_%s.mgz' % amap_name)       
        
        os.system('%s %s %s' % (os.path.join(path_to_freesurfer_bin, 'mri_convert'), metric_out_left, metric_out_left_mgz))
        os.system('%s %s %s' % (os.path.join(path_to_freesurfer_bin, 'mri_convert'), metric_out_right, metric_out_right_mgz))
        os.system('%s %s %s' % (os.path.join(path_to_freesurfer_bin, 'mri_convert'), metric_out_pseudo_left, metric_out_pseudo_left_mgz))
        os.system('%s %s %s' % (os.path.join(path_to_freesurfer_bin, 'mri_convert'), metric_out_pseudo_right, metric_out_pseudo_right_mgz))
        
        # Map fsaverage to fsnative
        native_metric_left = os.path.join(native_mgz, 'L_%s.mgz' % amap_name)
        native_metric_right = os.path.join(native_mgz, 'R_%s.mgz' % amap_name)
        native_metric_left_pseudo = os.path.join(native_mgz_pseudo_hemi, 'L_%s.mgz' % amap_name)
        native_metric_right_pseudo = os.path.join(native_mgz_pseudo_hemi, 'R_%s.mgz' % amap_name)
        os.system('SUBJECTS_DIR=%s; %s --srcsubject fsaverage --trgsubject %s --hemi lh --sval %s --tval %s' % (path_to_subject_freesurfer,
                                                                                                                os.path.join(path_to_freesurfer_bin, 'mri_surf2surf'),
                                                                                                                subject_id, metric_out_left_mgz, native_metric_left))
        os.system('SUBJECTS_DIR=%s; %s --srcsubject fsaverage --trgsubject %s --hemi rh --sval %s --tval %s' % (path_to_subject_freesurfer,
                                                                                                                os.path.join(path_to_freesurfer_bin, 'mri_surf2surf'),
                                                                                                                subject_id, metric_out_right_mgz, native_metric_right))  
        os.system('SUBJECTS_DIR=%s; %s --srcsubject fsaverage --trgsubject %s --hemi lh --sval %s --tval %s' % (path_to_subject_freesurfer,
                                                                                                                os.path.join(path_to_freesurfer_bin, 'mri_surf2surf'),
                                                                                                                subject_id, metric_out_pseudo_left_mgz, native_metric_left_pseudo))
        os.system('SUBJECTS_DIR=%s; %s --srcsubject fsaverage --trgsubject %s --hemi rh --sval %s --tval %s' % (path_to_subject_freesurfer,
                                                                                                                os.path.join(path_to_freesurfer_bin, 'mri_surf2surf'),
                                                                                                                subject_id, metric_out_pseudo_right_mgz, native_metric_right_pseudo)) 
cifti_to_freesurfer(*sys.argv[1:])  
