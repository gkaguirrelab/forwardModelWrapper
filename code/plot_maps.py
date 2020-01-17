import os
import nibabel as nb
import matplotlib.pyplot as plt
import numpy as np
import imageio
import re 
import sys

def plot_maps(template_path, map_path, threshold, stem_name, output):
    
    def natural_key(string_):
        return [int(s) if s.isdigit() else s for s in re.split(r'(\d+)', string_)]
    
    threshold = float(threshold)	
    template_load = nb.load(template_path)
    map_load = nb.load(map_path)
    template_data = template_load.get_data()
    map_data = map_load.get_data()
    map_data = np.ma.masked_where(map_data < threshold, map_data)
    
    saggital_temp = os.path.join(output, 'saggital_temp') 
    if not os.path.exists(saggital_temp):
        os.system('mkdir %s' % saggital_temp)
    for i in range(map_data.shape[0]):
        if np.nanmax(template_data[i,:,:]) != 0:
            plt.imshow(template_data[i,:,:], cmap='gray')
            plt.imshow(map_data[i,:,:], cmap='hot')
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
            plt.imshow(template_data[:,i,:], cmap='gray')
            plt.imshow(map_data[:,i,:], cmap='hot')
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
            plt.imshow(template_data[:,:,i], cmap='gray')
            plt.imshow(map_data[:,:,i], cmap='hot')
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
    imageio.mimsave('/%s/%s_%s.gif' % (output, stem_name, '_saggital_plots'), images, duration=0.35) 
        
    images = []
    image_names = []
    for filename in os.listdir(axial_temp):
        image_names.append(filename)
    image_names = sorted(image_names, key=natural_key)
    for image in image_names:
        images.append(imageio.imread(os.path.join(axial_temp, image)))
    imageio.mimsave('/%s/%s_%s.gif' % (output, stem_name, '_axial_plots'), images, duration=0.35)  

    images = []
    image_names = []
    for filename in os.listdir(coronal_temp):
        image_names.append(filename)
    image_names = sorted(image_names, key=natural_key)
    for image in image_names:
        images.append(imageio.imread(os.path.join(coronal_temp, image)))
    imageio.mimsave('/%s/%s_%s.gif' % (output, stem_name, '_coronal_plots'), images, duration=0.35)    
    
    os.system('rm -r %s' % saggital_temp)
    os.system('rm -r %s' % coronal_temp)
    os.system('rm -r %s' % axial_temp)
    
plot_maps(*sys.argv[1:])   
