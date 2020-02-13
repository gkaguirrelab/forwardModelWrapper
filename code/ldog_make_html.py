import sys

def ldog_make_html(subject_id, output_dir, maps_folder='images'):

    # This functions places ldog images into an html file for visualization.
    # point the "maps_folder" to the folder that contains the ldog images.
    # If you want Flywheel to be able to view this html, zip it with the folder
    # that contains the images.
    
    # Inputs:
    # subject_id: Subject id that is appended in front of ldog images.
    # maps_folder: Folder that contains the images named below
    # output_dir: The path for the html output folder. The html is named index
    # automatically to prevent Flywheel errors so just point to the folder where
    # it will be written.
    
    html_file = open('%s/index.html' % output_dir,'w')
    html_content = """
    <h1>Surface</h1>
    <img src="./%s" style="float: left; width: 30%%; margin-right: 1%%; margin-bottom: 0.5em;" alt="Left_lateral">
    <img src="./%s" style="float: left; width: 30%%; margin-right: 1%%; margin-bottom: 0.5em;" alt="Right_lateral">
    <p style="clear: both;">      
    <img src="./%s" style="float: left; width: 30%%; margin-right: 1%%; margin-bottom: 0.5em;" alt="Left_medial">
    <img src="./%s" style="float: left; width: 30%%; margin-right: 1%%; margin-bottom: 0.5em;" alt="Right_medial">
    <p style="clear: both;">
    <h1>R2</h1>
    <img src="./%s" style="float: left; width: 30%%; margin-right: 1%%; margin-bottom: 0.5em;" alt="Saggital">
    <img src="./%s" style="float: left; width: 30%%; margin-right: 1%%; margin-bottom: 0.5em;" alt="Axial">
    <img src="./%s" style="float: left; width: 30%%; margin-right: 1%%; margin-bottom: 0.5em;" alt="Coronal">
    <p style="clear: both;">   
    <h1>Eigen1</h1>
    <img src="./%s" style="float: left; width: 30%%; margin-right: 1%%; margin-bottom: 0.5em;" alt="Saggital">
    <img src="./%s" style="float: left; width: 30%%; margin-right: 1%%; margin-bottom: 0.5em;" alt="Axial">
    <img src="./%s" style="float: left; width: 30%%; margin-right: 1%%; margin-bottom: 0.5em;" alt="Coronal">
    <p style="clear: both;">
    <h1>Eigen2</h1>
    <img src="./%s" style="float: left; width: 30%%; margin-right: 1%%; margin-bottom: 0.5em;" alt="Saggital">
    <img src="./%s" style="float: left; width: 30%%; margin-right: 1%%; margin-bottom: 0.5em;" alt="Axial">
    <img src="./%s" style="float: left; width: 30%%; margin-right: 1%%; margin-bottom: 0.5em;" alt="Coronal">
    <p style="clear: both;"> 
    <h1>Eigen3</h1>
    <img src="./%s" style="float: left; width: 30%%; margin-right: 1%%; margin-bottom: 0.5em;" alt="Saggital">
    <img src="./%s" style="float: left; width: 30%%; margin-right: 1%%; margin-bottom: 0.5em;" alt="Axial">
    <img src="./%s" style="float: left; width: 30%%; margin-right: 1%%; margin-bottom: 0.5em;" alt="Coronal">
    <p style="clear: both;">
    <h1>log10pMVN</h1>
    <img src="./%s" style="float: left; width: 30%%; margin-right: 1%%; margin-bottom: 0.5em;" alt="Saggital">
    <img src="./%s" style="float: left; width: 30%%; margin-right: 1%%; margin-bottom: 0.5em;" alt="Axial">
    <img src="./%s" style="float: left; width: 30%%; margin-right: 1%%; margin-bottom: 0.5em;" alt="Coronal">
    <p style="clear: both;">
    """ % ('%s/%s_left_medial.png' % (maps_folder,subject_id),
           '%s/%s_right_lateral.png' % (maps_folder,subject_id),
           '%s/%s_left_lateral.png' % (maps_folder,subject_id),
           '%s/%s_right_medial.png' % (maps_folder,subject_id),
           '%s/%s_R2_statMap_saggital_plots.gif' % (maps_folder,subject_id),
           '%s/%s_R2_statMap_axial_plots.gif' % (maps_folder,subject_id),
           '%s/%s_R2_statMap_coronal_plots.gif' % (maps_folder,subject_id),
           '%s/%s_eigen1_statMap_saggital_plots.gif' % (maps_folder,subject_id),
           '%s/%s_eigen1_statMap_axial_plots.gif' % (maps_folder,subject_id),
           '%s/%s_eigen1_statMap_coronal_plots.gif' % (maps_folder,subject_id),
           '%s/%s_eigen2_statMap_saggital_plots.gif' % (maps_folder,subject_id),
           '%s/%s_eigen2_statMap_axial_plots.gif' % (maps_folder,subject_id),
           '%s/%s_eigen2_statMap_coronal_plots.gif' % (maps_folder,subject_id),
           '%s/%s_eigen3_statMap_saggital_plots.gif' % (maps_folder,subject_id),
           '%s/%s_eigen3_statMap_axial_plots.gif' % (maps_folder,subject_id),
           '%s/%s_eigen3_statMap_coronal_plots.gif' % (maps_folder,subject_id),
           '%s/%s_log10pMVN_statMap_saggital_plots.gif' % (maps_folder,subject_id),
           '%s/%s_log10pMVN_statMap_axial_plots.gif' % (maps_folder,subject_id),
           '%s/%s_log10pMVN_statMap_coronal_plots.gif' % (maps_folder,subject_id))
        
    html_file.write(html_content)
    html_file.close()   

ldog_make_html(*sys.argv[1:])