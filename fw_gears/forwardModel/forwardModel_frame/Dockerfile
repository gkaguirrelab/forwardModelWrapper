# This makes a container for the gear. Replace the first path next to the second COPY function 
# below with a path to your local compiled matlab function

FROM neurodebian:xenial
MAINTAINER Ozzy(ozenctaskin@hotmail.com)

#Copy everything into a container 
ENV FLYWHEEL /flywheel/v0/
RUN mkdir -p ${FLYWHEEL}
COPY manifest.json run ${FLYWHEEL}

COPY /python_functions/make_fsaverage.py /opt/make_fsaverage.py
COPY /python_functions/plot_maps.py /opt/plot_maps.py
COPY /python_functions/plot_surface.py /opt/plot_surface.py
COPY /python_functions/ldog_make_html.py /opt/ldog_make_html.py
COPY func_input/ /opt/func_input 
COPY flywheel.mlsettings /usr/flywheel.mlsettings
RUN chmod +x /flywheel/v0/run
RUN chmod +x /opt/func_input/*  

# Install required packages     
RUN apt-get update \
    && apt-get install -y \
    software-properties-common
RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt-get update
RUN apt-get install -y \
    wget \
    python3.7 \
    python3-pip \
    zip \
    unzip \
    fsl-core \
    ants

# Install python packages   
RUN python3.7 -m pip install --upgrade pip
RUN python3.7 -m pip install matplotlib nibabel==2.5.1 numpy imageio nilearn neuropythy

# Download and install MCR on call
RUN wget http://ssd.mathworks.com/supportfiles/downloads/R2019b/Release/2/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2019b_Update_2_glnxa64.zip
RUN mkdir matlabins
RUN unzip MATLAB_Runtime_R2019b_Update_2_glnxa64.zip -d /matlabins/
RUN /matlabins/install -mode silent -agreeToLicense yes

# Download and install Freesurfer on call
RUN wget https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/6.0.0/freesurfer-Linux-centos6_x86_64-stable-pub-v6.0.0.tar.gz
RUN mkdir freesurfer
RUN tar -zxf freesurfer-Linux-centos6_x86_64-stable-pub-v6.0.0.tar.gz 
COPY license.txt /freesurfer/license.txt
ENV FREESURFER_HOME /freesurfer

# Set the entrypoint  
ENTRYPOINT /flywheel/v0/run



