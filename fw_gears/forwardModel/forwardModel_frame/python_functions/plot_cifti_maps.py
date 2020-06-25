import os, sys, nilearn
from nilearn import plotting
import matplotlib.pyplot as plt
import hcp_utils as hcp
import nibabel as nb
import numpy as np

def plot_cifti_maps(cifti_R2_map_path, subject_id, temporary_file_folder, wb_command_path, output_folder):
    
    if os.path.split(cifti_R2_map_path)[1][-13:] == '.dtseries.nii' or os.path.split(cifti_R2_map_path)[1][-13:] == '.dscalar.nii':
        image_name = os.path.split(cifti_R2_map_path)[1][:-13]
    else:
        RuntimeError('Cifti type is not recognized. Only can process dtseries and dscalar')
    image_name = str(image_name)
    
    volume_path = os.path.join(temporary_file_folder, image_name + '.nii.gz')
    surf_left_path = os.path.join(temporary_file_folder, 'l.' + image_name + '.func.gii')
    surf_right_path = os.path.join(temporary_file_folder, 'r.' + image_name + '.func.gii')
    
    # Separate volume 
    volume_sep_command = '%s -cifti-separate %s COLUMN -volume-all %s -metric CORTEX_LEFT %s -metric CORTEX_RIGHT %s' % (wb_command_path,
                                                                                                                          cifti_R2_map_path,
                                                                                                                          volume_path,
                                                                                                                          surf_left_path,
                                                                                                                          surf_right_path)
    # Run the command
    os.system(volume_sep_command)

    # Initialize figures
    fig1 = plt.figure(figsize=[11,6])
    fig2 = plt.figure(figsize=[11,6])
    fig3 = plt.figure(figsize=[11,6])
    fig4 = plt.figure(figsize=[11,6])
    fig5 = plt.figure(figsize=[11,6])
    
    # Create a temporary html and image folder
    temporary_html_folder = os.path.join(temporary_file_folder, image_name)
    if ~os.path.exists(temporary_html_folder):
        os.system('mkdir %s' % temporary_html_folder)    
    temporary_image_folder = os.path.join(temporary_html_folder, 'images')
    if ~os.path.exists(temporary_image_folder):
        os.system('mkdir %s' % temporary_image_folder)
    
    # Load images
    surf_left = nilearn.surface.load_surf_data(surf_left_path)
    surf_right = nilearn.surface.load_surf_data(surf_right_path)
    surf_left_no_zer = surf_left.copy()
    surf_right_no_zer = surf_right.copy()
    surf_left_no_zer[surf_left_no_zer == 0] = 'nan'
    surf_right_no_zer[surf_right_no_zer == 0] = 'nan'
    volume = nb.load(volume_path)
    volume_dat = volume.get_fdata()
    
    if len(surf_left.shape) != 1:
        surf_left = surf_left[:,0]
        surf_right = surf_right[:,0]  
        affine = volume.affine
        header = volume.header
        extra = volume.extra
        file_map = volume.file_map
        data = volume_dat[:,:,:,0]
        volume = nb.Nifti1Image(data,affine,header,extra,file_map)
    
    # Save plots 
    plotting.plot_surf(hcp.mesh.inflated_left, surf_left, bg_map=hcp.mesh.sulc_left,
                            hemi='left',view='medial', colorbar=True, cmap='hot', title='gifti left',
                            cbar_vmin=np.nanmin(surf_left_no_zer), cbar_vmax=np.nanmax(surf_left_no_zer), figure=fig1,
                            output_file=os.path.join(temporary_image_folder, 'med_gifti_left.png')) 
    plotting.plot_surf(hcp.mesh.inflated_left, surf_left, bg_map=hcp.mesh.sulc_left,
                            hemi='left',view='lateral', colorbar=True, cmap='hot', title='gifti left',
                            cbar_vmin=np.nanmin(surf_left_no_zer), cbar_vmax=np.nanmax(surf_left_no_zer), figure=fig2,
                            output_file=os.path.join(temporary_image_folder, 'lat_gifti_left.png'))    
    plotting.plot_surf(hcp.mesh.inflated_right, surf_right, bg_map=hcp.mesh.sulc_right,
                            hemi='right',view='medial', colorbar=True, cmap='hot', title='gifti right',
                            cbar_vmin=np.nanmin(surf_right_no_zer), cbar_vmax=np.nanmax(surf_right_no_zer), figure=fig3,
                            output_file=os.path.join(temporary_image_folder, 'med_gifti_right.png'))
    plotting.plot_surf(hcp.mesh.inflated_right, surf_right, bg_map=hcp.mesh.sulc_right,
                            hemi='right',view='lateral', colorbar=True, cmap='hot', title='gifti right',
                            cbar_vmin=np.nanmin(surf_right_no_zer), cbar_vmax=np.nanmax(surf_right_no_zer), figure=fig4,
                            output_file=os.path.join(temporary_image_folder, 'lat_gifti_right.png'))
    nilearn.plotting.plot_anat(volume, output_file=os.path.join(temporary_image_folder, 'volume.png'),
                                colorbar=True, cmap='hot', title='volume', figure=fig5,
                                cbar_vmin=np.nanmin(volume_dat), cbar_vmax=np.nanmax(volume_dat))
    
    # Create the html
    html_file = open('%s/index.html' % temporary_html_folder,'w')
    html_content = '''
    <h1>Surface</h1>
    <img src="./%s" style="float: left; width: 30%%; margin-right: 1%%; margin-bottom: 0.5em;" alt="Left_lateral">
    <img src="./%s" style="float: left; width: 30%%; margin-right: 1%%; margin-bottom: 0.5em;" alt="Right_lateral">   
    <img src="./%s" style="float: left; width: 30%%; margin-right: 1%%; margin-bottom: 0.5em;" alt="Left_medial">
    <img src="./%s" style="float: left; width: 30%%; margin-right: 1%%; margin-bottom: 0.5em;" alt="Right_medial">
    <p style="clear: both;">
    <h1>Volume</h1>
    <img src="./%s" style="float: left; width: 30%%; margin-right: 1%%; margin-bottom: 0.5em;" alt="Volume">    
    <p style="clear: both;"> ''' % ('images/lat_gifti_left.png', 'images/lat_gifti_right.png', 
                                    'images/med_gifti_left.png', 'images/med_gifti_right.png',
                                    'images/volume.png')
    html_file.write(html_content)
    html_file.close()
    
    os.system('cd %s; zip -r -q %s *' % (temporary_html_folder, os.path.join(output_folder, 'diagnostics_%s.html.zip' % image_name)))
    os.system('rm -r %s' % temporary_html_folder)
    os.system('rm %s %s %s' % (volume_path, surf_left_path, surf_right_path))
    
plot_cifti_maps(*sys.argv[1:])