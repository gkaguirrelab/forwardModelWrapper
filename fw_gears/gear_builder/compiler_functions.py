import os 

def compile_calcCorticalMag(path_to_matlab_documents, output_folder):
    
    # Create the output folder if doesn't exist
    if not os.path.exists(output_folder):
        os.system("mkdir %s"%output_folder)
    
    mcc_path = 'mcc'
    mcc_call1 = '%s -m -R -nodisplay %s -I %s -I %s -a %s -d %s -v'%(mcc_path,
                                                                     os.path.join(path_to_matlab_documents,'projects/forwardModelWrapper/code/calcCorticalMag.m'),
                                                                     os.path.join(path_to_matlab_documents,'toolboxes/freesurferMatlab/matlab/'),
                                                                     os.path.join(path_to_matlab_documents,'projects/forwardModelWrapper/code/utilities'),
                                                                     os.path.join(path_to_matlab_documents,'toolboxes/matlabcentral/TheilSen/'),
                                                                     output_folder)
    
    print('Compiling calcCorticalMag.m')
    os.system(mcc_call1)

def compile_forwardModel(path_to_matlab_documents, output_folder):
    
    # Create the output folder if doesn't exist
    if not os.path.exists(output_folder):
        os.system("mkdir %s"%output_folder)
    
    mcc_path = 'mcc'
    mcc_call2 = '%s -m -R -nodisplay %s -I %s -I %s -I %s -I %s -I %s \
    -I %s -I %s -d %s -v'%(mcc_path, os.path.join(path_to_matlab_documents,'projects/forwardModelWrapper/code/mainWrapper.m'),
    os.path.join(path_to_matlab_documents,'projects/forwardModelWrapper/code/'),
    os.path.join(path_to_matlab_documents,'projects/forwardModelWrapper/code/bayesPRF/'),
    os.path.join(path_to_matlab_documents,'toolboxes/forwardModel/'),
    os.path.join(path_to_matlab_documents,'toolboxes/HCPpipelines/global/matlab/'),
    os.path.join(path_to_matlab_documents,'projects/forwardModelWrapper/code/utilities/'),    
    os.path.join(path_to_matlab_documents,'toolboxes/freesurferMatlab/matlab/'),
    os.path.join(path_to_matlab_documents,'toolboxes/progressBar/'),
    output_folder)
    
    print('Compiling mainPRF.m')
    os.system(mcc_call2)

def compile_postprocessBayes(path_to_matlab_documents, output_folder):
    
    # Create the output folder if doesn't exist
    if not os.path.exists(output_folder):
        os.system("mkdir %s"%output_folder)
    
    mcc_path = 'mcc'
    mcc_call3 = '%s -m -R -nodisplay %s -I %s -I %s -d %s -v'%(mcc_path,
                                                              os.path.join(path_to_matlab_documents,'projects/forwardModelWrapper/code/postprocessBayes.m'),
                                                              os.path.join(path_to_matlab_documents,'toolboxes/HCPpipelines/global/matlab/'),
                                                              os.path.join(path_to_matlab_documents,'toolboxes/freesurferMatlab/matlab/'),
                                                              output_folder)
    
    print('Compiling postprocessBayes.m')
    os.system(mcc_call3)
    
def compile_renderInferredMaps(path_to_matlab_documents, output_folder):
    
    # Create the output folder if doesn't exist
    if not os.path.exists(output_folder):
        os.system("mkdir %s"%output_folder)
    
    mcc_path = 'mcc'
    mcc_call4 = '%s -m -R -nodisplay %s -I %s -I %s -I %s -d %s -v'%(mcc_path,
                                                     os.path.join(path_to_matlab_documents,'projects/forwardModelWrapper/code/renderInferredMaps.m'),
                                                     os.path.join(path_to_matlab_documents,'projects/forwardModelWrapper/code/'),
                                                     os.path.join(path_to_matlab_documents,'projects/forwardModelWrapper/code/utilities/'),
                                                     os.path.join(path_to_matlab_documents,'toolboxes/freesurferMatlab/matlab/'),
                                                     output_folder)
    
    print('Compiling renderInferredMaps.m')
    os.system(mcc_call4)
    
def compile_regressMotion(path_to_matlab_documents, output_folder):

    # Create the output folder if doesn't exist
    if not os.path.exists(output_folder):
        os.system("mkdir %s"%output_folder)
    
    #mcc_path = '/usr/local/MATLAB/R2018b/bin/mcc'
    mcc_path = 'mcc'
    mcc_call = '%s -m -R -nodisplay %s -I %s -d %s -v'%(mcc_path, os.path.join(path_to_matlab_documents,'/home/ozzy/Documents/MATLAB/projects/mriLDOGAnalysis/matlab/regressMotion.m'),  
                                                        os.path.join(path_to_matlab_documents,'toolboxes/freesurferMatlab/matlab/'),
                                                        output_folder)
    
    print('Compiling regressMotion.m')
    os.system(mcc_call)
