import os 
import sys

def compile_mainPRF(path_to_matlab_documents, output_folder):
    
    # This function compiles the mainPRF.m. It works with ToolboxToolbox folder 
    # organization.Therefore, it assumes that the required MATLAB functions are 
    # saved in Documents/MATLAB/toolboxes and the pRFCompileWrapper repository 
    # is located in Documents/MATLAB/projects.
    
    # Note: The latest matlab runtime base image for docker was provided by 
    # flywheel last year. Since the gear will use that image please make sure
    # that you are compiling this funciton with Runtime version v95 (Comes with
    # MATLAB 2018b).
    
    # path_to_matlab_documents: Path to the MATLAB folder in Documents 
    # output_folder: Path to the save folder
    
    # Create the output folder if doesn't exist
    if not os.path.exists(output_folder):
        os.system("mkdir %s"%output_folder)
    
    mcc_path = '/usr/local/MATLAB/R2018b/bin/mcc'
    #mcc_path = 'mcc'
    mcc_call = '%s -m -R -nodisplay %s -a %s -a %s -a %s -a %s -a %s \
    -a %s -a %s -d %s'%(mcc_path, os.path.join(path_to_matlab_documents,'projects/pRFCompileWrapper/code/mainPRF.m'),
    os.path.join(path_to_matlab_documents,'projects/pRFCompileWrapper/code/preprocessPRF.m'),
    os.path.join(path_to_matlab_documents,'projects/pRFCompileWrapper/code/postprocessPRF.m'),
    os.path.join(path_to_matlab_documents,'projects/pRFCompileWrapper/code/wrapperPRF.m'),
    os.path.join(path_to_matlab_documents,'toolboxes/analyzePRF/'),
    os.path.join(path_to_matlab_documents,'toolboxes/HCPpipelines/global/matlab/'),
    os.path.join(path_to_matlab_documents,'toolboxes/freesurferMatlab/matlab/MRIwrite.m'),
    os.path.join(path_to_matlab_documents,'toolboxes/freesurferMatlab/matlab/MRIread.m'),
    output_folder)
    
    print('Compiling mainPRF.m')
    os.system(mcc_call)
    
compile_mainPRF(*sys.argv[1:])

