import os 
import sys

def compile_calcCorticalMag(path_to_matlab_documents='/home/ozzy/Documents/MATLAB/', output_folder='/home/ozzy/Documents/MATLAB/projects/forwardModelWrapper/fw_gears/bayesianFitting/bayesianFittingGear_frame/cortmag_func'):
    
    # This function compiles the renderInferredMaps.m MATLAB function for the 
    # BayesPRF gear.
    
    # Run this script from the terminal: python <path_to_this_function> <path_to_matlab_documents> <output_folder>

    # Create the output folder if doesn't exist
    if not os.path.exists(output_folder):
        os.system("mkdir %s"%output_folder)
    
    #mcc_path = '/usr/local/MATLAB/R2018b/bin/mcc'
    mcc_path = 'mcc'
    mcc_call = '%s -m -R -nodisplay %s -I %s -I %s -d %s -v'%(mcc_path,
                                                              os.path.join(path_to_matlab_documents,'projects/forwardModelWrapper/code/calcCorticalMag.m'),
                                                              os.path.join(path_to_matlab_documents,'toolboxes/freesurferMatlab/matlab/'),
                                                              os.path.join(path_to_matlab_documents,'projects/forwardModelWrapper/code/utilities'),
                                                              output_folder)
    
    print('Compiling calcCorticalMag.m')
    os.system(mcc_call)

    
compile_calcCorticalMag(*sys.argv[1:])
