import os
import nibabel as nb
import matplotlib.pyplot as plt
import numpy as np
import imageio
import re 
import sys
import warnings
warnings.filterwarnings("ignore")

def plot_maps(template_path, map_path, threshold, stem_name, output):
    
    threshold = float(threshold)	    
    
    def natural_key(string_):
        return [int(s) if s.isdigit() else s for s in re.split(r'(\d+)', string_)]
    
    template_load = nb.load(template_path)
    raw_map_load = nb.load(map_path)   
    template_header = template_load.header
    map_header = raw_map_load.header
    template_dimensions = [template_header['pixdim'][1], template_header['pixdim'][2], template_header['pixdim'][3]]
    map_dimensions = [map_header['pixdim'][1], map_header['pixdim'][2], map_header['pixdim'][3]]
    
    if template_dimensions == map_dimensions:        
        map_load = nb.load(map_path) 
    else:
        resampled_image_folder = '/tmp/resampled_image_folder'
        if not os.path.exists(resampled_image_folder):
            os.system('mkdir %s' % resampled_image_folder)
        os.system('FSLDIR=/usr/lib/fsl/5.0;. /etc/fsl/5.0/fsl.sh;PATH=${FSLDIR}:${PATH};export FSLDIR PATH;/usr/lib/fsl/5.0/flirt -in %s -ref %s -out %s -applyxfm' % (map_path,
                                                                                                                                                                       template_path,
                                                                                                                                                                       os.path.join(resampled_image_folder, 'resampled_map.nii.gz')))
        map_load = nb.load(os.path.join(resampled_image_folder, 'resampled_map.nii.gz'))
     
    template_data = template_load.get_data()
    map_data = map_load.get_data()
    map_data = np.ma.masked_where(map_data < threshold, map_data)
    
    saggital_temp = os.path.join(output, 'saggital_temp') 
    if not os.path.exists(saggital_temp):
        os.system('mkdir %s' % saggital_temp)
    for i in range(map_data.shape[0]):
        if np.nanmax(template_data[i,:,:]) != 0:
            plt.imshow(template_data[i,:,:], cmap='gray', aspect=template_dimensions[0])
            plt.imshow(map_data[i,:,:], cmap='hot', aspect=template_dimensions[0])
            plt.colorbar()
            plt.title('max voxel value= %s \nThreshold=%s' % (str(np.nanmax(map_data)), str(threshold)))
            plt.clim(threshold, np.nanmax(map_data));
            plt.savefig('%s/saggital_plot_%s.png' % (saggital_temp,i))
            plt.close()
    
    axial_temp = os.path.join(output, 'axial_temp')
    if not os.path.exists(axial_temp):
        os.system('mkdir %s' % axial_temp)
    for i in range(map_data.shape[1]):
        if np.nanmax(template_data[:,i,:]) != 0:
            plt.imshow(template_data[:,i,:], cmap='gray', aspect=template_dimensions[1])
            plt.imshow(map_data[:,i,:], cmap='hot', aspect=template_dimensions[1])
            plt.colorbar()
            plt.title('max voxel value= %s \nThreshold=%s' % (str(np.nanmax(map_data)), str(threshold)))
            plt.clim(threshold, np.nanmax(map_data));
            plt.savefig('%s/axial_plot_%s.png' % (axial_temp,i))
            plt.close()    
        
    coronal_temp = os.path.join(output, 'coronal_temp')
    if not os.path.exists(coronal_temp):
        os.system('mkdir %s' % coronal_temp)    
    for i in range(map_data.shape[2]):
        if np.nanmax(template_data[:,:,i]) != 0:        
            plt.imshow(template_data[:,:,i], cmap='gray', aspect=template_dimensions[2])
            plt.imshow(map_data[:,:,i], cmap='hot', aspect=template_dimensions[2])
            plt.colorbar()
            plt.title('max voxel value= %s \nThreshold=%s' % (str(np.nanmax(map_data)), str(threshold)))
            plt.clim(threshold, np.nanmax(map_data));
            plt.savefig('%s/coronal_plot_%s.png' % (coronal_temp,i))
            plt.close()       
    
    images = []
    image_names = []
    for filename in os.listdir(saggital_temp):
        image_names.append(filename)
    image_names = sorted(image_names, key=natural_key)
    for image in image_names:
        images.append(imageio.imread(os.path.join(saggital_temp, image)))
    imageio.mimsave('/%s/%s_%s.gif' % (output, stem_name, 'saggital_plots'), images, duration=0.30) 
    # saggital_gif = os.path.join(output, stem_name + '_saggital_plots.gif')
        
    images = []
    image_names = []
    for filename in os.listdir(axial_temp):
        image_names.append(filename)
    image_names = sorted(image_names, key=natural_key)
    for image in image_names:
        images.append(imageio.imread(os.path.join(axial_temp, image)))
    imageio.mimsave('/%s/%s_%s.gif' % (output, stem_name, 'axial_plots'), images, duration=0.30)  
    # axial_gif = os.path.join(output, stem_name + '_axial_plots.gif')

    images = []
    image_names = []
    for filename in os.listdir(coronal_temp):
        image_names.append(filename)
    image_names = sorted(image_names, key=natural_key)
    for image in image_names:
        images.append(imageio.imread(os.path.join(coronal_temp, image)))
    imageio.mimsave('/%s/%s_%s.gif' % (output, stem_name, 'coronal_plots'), images, duration=0.30)    
    # coronal_gif = os.path.join(output, stem_name + '_coronal_plots.gif')
    
    os.system('rm -r %s' % saggital_temp)
    os.system('rm -r %s' % coronal_temp)
    os.system('rm -r %s' % axial_temp)
    
    # html_file = open('%s/%s_R2maps.html' % (output, stem_name),'w')
    # content = '<html>\n<body>\n<h1>Saggital</h1>\n<img src="%s">\n</body>\n</html>''<html>\n<body>\n<h1>Axial</h1>\n<img src="%s">\n</body>\n</html>''<html>\n<body>\n<h1>Coronal</h1>\n<img src="%s">\n</body>\n</html>' % (saggital_gif,
    #                                                                                                                                                                                                                          axial_gif,
    #                                                                                                                                                                                                                          coronal_gif)
    # html_file.write(content)
    # html_file.close()
        
plot_maps(*sys.argv[1:])   
    
