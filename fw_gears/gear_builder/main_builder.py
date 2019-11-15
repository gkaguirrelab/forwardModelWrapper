import os
from compiler_functions import *

def main_builder(which_gear='bayesianfittinggear', path_to_matlab_doc='/home/ozzy/Documents/MATLAB/', gear_version):
    
###################### Set some initial paths #################################
    
    # Please login to docker with the "docker login" command first and to flywheel 
    # using "fw login <API-key>"
    
    # which_gear = bayesianfittinggear or forwardmodelgear
    
    cont = raw_input('The script renames your matlab startup file to nostartup.m for the compiling process and renames it again to discard the change at the end of the compiling process. Do you want to continue ? y/n')
    if cont == 'y':
        
        os.system('mv %s %s' % (os.path.join(path_to_matlab_doc, 'startup.m'), os.path.join(path_to_matlab_doc, 'nostartup.m')))
        os.system('rm /home/ozzy/matlab/*')
        
    ################### Compile Require Matlab Functions ##########################
        
        if which_gear == "bayesianfittinggear":   
            frame = os.path.join(path_to_matlab_doc, 'projects', 
                                 'forwardMtheodelWrapper', 
                                 'fw_gears', 'bayesianFitting',
                                 'bayesianFittingGear_frame')
            cortmag_func = os.path.join(frame, 'cortmag_func')
            postproc_func = os.path.join(frame, 'postproc_func')
            render_func = os.path.join(frame, 'render_func')
            os.system('rm -r %s' % cortmag_func)
            os.system('rm -r %s' % postproc_func)
            os.system('rm -r %s' % render_func)
            compile_calcCorticalMag(path_to_matlab_doc, cortmag_func)
            compile_postprocessBayes(path_to_matlab_doc, postproc_func)
            compile_renderInferredMaps(path_to_matlab_doc, render_func)
            mainfold = os.path.join(path_to_matlab_doc, 'projects', 
                                    'forwardModelWrapper', 
                                    'fw_gears', 'bayesianFitting',
                                    'main_gear')
            
        if which_gear == "forwardmodelgear":  
            frame = os.path.join(path_to_matlab_doc, 'projects', 
                                 'forwardModelWrapper', 
                                 'fw_gears', 'forwardModel',
                                 'forwardModel_frame')       
            func_input = os.path.join(frame, 'func_input')
            os.system('rm -r %s' % func_input)
            compile_forwardModel(path_to_matlab_doc, func_input)
            mainfold = os.path.join(path_to_matlab_doc, 'projects', 
                                    'forwardModelWrapper', 
                                    'fw_gears', 'forwardModel',
                                    'main_gear')
        
        os.system('mv %s %s' % (os.path.join(path_to_matlab_doc, 'nostartup.m'), os.path.join(path_to_matlab_doc, 'startup.m')))
    
    ##################### Build the docker images #################################
        
        # This process might take a while if you have not pulled the gear base before     
        os.system('cd %s; docker build -t gkaguirrelab/%s:%s .' % (frame,
                                                                   which_gear,
                                                                   gear_version))
        
        os.system('cd %s; rm *' % mainfold)
        
        if which_gear == 'bayesianfittinggear':
            print('\nWhen asked to chose a human readable name enter the following without the quotation marks:  "bayesPRF: template fitting of retinotopic maps using neuropythy"')
            print('\n')
            print('When asked for a gear ID enter the following without the quotation marks:  "bayesprf"')
        
        if which_gear == 'forwardmodelgear':
            print('When asked to chose a human readable name use the following without the quotation marks:  "forwardModel: non-linear fitting of models to fMRI data"')
            print('\n')
            print('When asked for a gear ID enter the following without the quotation marks:  "forwardmodel"')
        
        print('\nSelect Other for the third question and enter the following as the contianer:   gkaguirrelab/%s:%s'% (which_gear, gear_version))
         
        os.system('cd %s; fw gear create' % mainfold)
        
        print('Do not forget the modify main gear json file')
        
    ############################## Test ###########################################
        
        if test == True:
            if which_gear == 'bayesianfittinggear':
                os.system('cd %s; fw gear local --nativeMgzMaps /home/ozzy/Desktop/gear_test_files/TOME_3045_maps_nativeMGZ.zip --structZip /home/ozzy/Desktop/gear_test_files/TOME_3045_hcpstruct.zip' % mainfold)
            if which_gear == 'forwardmodelgear':
                os.system('cd %s; fw gear local --funcZip01 /home/ozzy/Desktop/gear_test_files/TOME_3045_ICAFIX_multi_tfMRI_RETINO_PA_run1_tfMRI_RETINO_PA_run2_tfMRI_RETINO_AP_run3_tfMRI_RETINO_AP_run4_hcpicafix.zip --stimFile /home/ozzy/Documents/MATLAB/projects/forwardModelWrapper/demo/pRFStimulus_108x108x420.mat --structZip /home/ozzy/Desktop/gear_test_files/helloTOME_3045_hcpstruct.zip --tr 0.8 --maskFile /home/ozzy/Desktop/gear_test_files/hello.dscalar.nii --averageAcquisitions 1' % mainfold)
            
        print('Do not forget the modify main gear json file. After the changes, cd into the main_gear folder and call fw gear upload.')
    
    else:
        print("process stopped")
    