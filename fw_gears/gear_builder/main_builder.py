import os
from compiler_functions import *
import sys

def main_builder():
    
###################### Set some initial paths #################################
    
    # Please login to docker with the "docker login" command first and to flywheel 
    # using "fw login <API-key>"
    
    # which_gear = bayesianfittinggear or forwardmodelgear
    # path_to_matlab_doc = path to your main MATLAB folder (usually in documents)
    # gear_version = the version number you want to bump the gear
    # test = Is whether you want to test the gear after building. Default n - false 
    print("The gear builder is starting. Make sure you pulled all changes on github")    
    path_to_matlab_doc = '/home/%s/Documents/MATLAB/' % os.getlogin()
 
    cont = input('Warning! This script temporarily renames your matlab startup file to nostartup.m for the compiling process. The script discards this change at the end of the compiling process. Do you want to continue ? y/n ')
    if cont == 'y':
        os.system('mv %s %s' % (os.path.join(path_to_matlab_doc, 'startup.m'), os.path.join(path_to_matlab_doc, 'nostartup.m')))
        startuptwo = '/home/ozzy/matlab/'
        if os.listdir(startuptwo) != []:
            os.system('rm /home/ozzy/matlab/*')    
    else:
        sys.exit("Application Stopped")

####################### Compile the required functions ########################        
    which_number = input('Enter the number of the gear you want to update:\n1-forwardmodel\n2-bayesianfitting\n3-ldogstruct\n4-ldogfunc\n5-ldogfix\nEnter a number:')
    if which_number == '1':
        gear_name = 'forwardmodel'
        gear_version = input('What will be the new gear version:')
        print('starting forwardmodel building')
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
    if which_number == '2':
        gear_name = 'bayesianfitting'        
        gear_version = input('What will be the new gear version:')
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
        
        
    os.system('mv %s %s' % (os.path.join(path_to_matlab_doc, 'nostartup.m'), os.path.join(path_to_matlab_doc, 'startup.m')))

    ##################### Build the docker images #################################
        
    # This process might take a while if you have not pulled the gear base before     
    os.system('cd %s; docker build -t gkaguirrelab/%s:%s .' % (frame,
                                                               which_gear,
                                                               gear_version))        
    # Delete the content of the main_gear folder
    if os.listdir(mainfold) != []:
        os.system('cd %s; rm *' % mainfold)
        
    if gear_name == 'bayesianfitting':
        print('\n')
        print('-- When asked to chose a human readable name enter the following without the quotation marks:  "bayesPRF: template fitting of retinotopic maps using neuropythy"')
        print('\n')
        print('-- When asked for a gear ID enter the following without the quotation marks:  "bayesprf"')
        
    if gear_name == 'forwardmodel':
        print('\n')
        print('-- When asked to chose a human readable name use the following without the quotation marks:  "forwardModel: non-linear fitting of models to fMRI data"')
        print('\n')
        print('-- When asked for a gear ID enter the following without the quotation marks:  "forwardmodel"')
        
    print('\n-- Select Other for the third question and enter the following as the contianer:   "gkaguirrelab/%s:%s"'% (which_gear, gear_version))
         
    os.system('cd %s; fw gear create' % mainfold)
        
    ############################## Test ###########################################
        cont2 = input('Make the json changes now (fix the version, author and suite fields). Make the run script changes if applicable. Press y to continue: y/n ')
        if cont2 == 'y':  
            cont4 = input('Do you want to test the gear (Only available on Ozzy\'s Linux machine): y/n ')
            if cont4 == 'y':
                if which_gear == 'bayesianfittinggear':
                    os.system('cd %s; fw gear local --nativeMgzMaps /home/ozzy/Desktop/gear_test_files/TOME_3045_maps_nativeMGZ.zip --structZip /home/ozzy/Desktop/gear_test_files/TOME_3045_hcpstruct.zip' % mainfold)
                if which_gear == 'forwardmodelgear':
                    os.system('cd %s; fw gear local --funcZip01 /home/ozzy/Desktop/gear_test_files/TOME_3045_ICAFIX_multi_tfMRI_RETINO_PA_run1_tfMRI_RETINO_PA_run2_tfMRI_RETINO_AP_run3_tfMRI_RETINO_AP_run4_hcpicafix.zip --stimFile /home/ozzy/Documents/MATLAB/projects/forwardModelWrapper/demo/pRFStimulus_108x108x420.mat --structZip /home/ozzy/Desktop/gear_test_files/TOME_3045_hcpstruct.zip --tr 0.8 --maskFile /home/ozzy/Desktop/gear_test_files/masks/hello.dscalar.nii --averageAcquisitions 1' % mainfold)
        cont4 = input('Make the final changes now if applicable (e.g fix the flywheel flag back to 1 if you changed it for a test. Press y to continue: y/n ')          
        if cont4 == 'y':
            uploadcall = input('Do you want to upload the gear? : y/n ')  
            if uploadcall == 'y':
                os.system('cd %s; fw gear upload' % mainfold)

    else:
        print("process stopped")

main_builder(*sys.argv[1:]) 
