# This makes a container for the gear. Replace the first path next to the second COPY function 
# below with a path to your local compiled matlab function

FROM neurodebian:xenial
MAINTAINER Ozzy(ozenctaskin@hotmail.com)

#Copy everything into a container 
ENV FLYWHEEL /flywheel/v0/
RUN mkdir -p ${FLYWHEEL}
COPY manifest.json run ${FLYWHEEL}
COPY make_fsaverage.py /opt/make_fsaverage.py
COPY plot_maps.py /opt/plot_maps.py
COPY func_input/ /opt/func_input 
COPY flywheel.mlsettings /usr/flywheel.mlsettings
RUN chmod +x /flywheel/v0/run
RUN chmod +x /opt/func_input/*  

# Install required packages    
RUN apt-get update \
    && apt-get install -y \
    wget \
    python3 \
    python3-pip \
    zip \
    unzip \
    fsl-core

# Install python packages   
RUN pip3 install --upgrade pip
RUN pip3 install matplotlib nibabel==2.5.1 numpy imageio nilearn

# Install MCR on call
RUN wget http://ssd.mathworks.com/supportfiles/downloads/R2019b/Release/2/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2019b_Update_2_glnxa64.zip
RUN mkdir matlabins
RUN unzip MATLAB_Runtime_R2019b_Update_2_glnxa64.zip -d /matlabins/
RUN /matlabins/install -mode silent -agreeToLicense yes

# Set the entrypoint  
ENTRYPOINT /flywheel/v0/run



