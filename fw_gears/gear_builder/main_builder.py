import os
from compiler_functions import *

###################### Set some initial paths #################################

# Please login to docker with the "docker login" command first and to flywheel 
# using "fw login <API-key>"

which_gear = "bayesianfittinggear" # or forwardmodelgear
gear_version = "0.1.1" 
path_to_matlab_doc = '/home/ozzy/Documents/MATLAB/'

################### Compile Require Matlab Functions ##########################

if which_gear == "bayesianfittinggear":   
    frame = os.path.join(path_to_matlab_doc, 'projects', 
                         'forwardModelWrapper', 
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
   