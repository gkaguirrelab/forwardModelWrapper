# This makes a container for the gear. Replace the first path next to the second COPY function 
# below with a path to your local compiled matlab function

FROM gkaguirrelab/gearbase:v1
MAINTAINER Ozzy(ozenctaskin@hotmail.com)

#Copy everything into a container
ENV FLYWHEEL /flywheel/v0/
RUN mkdir -p ${FLYWHEEL}
COPY manifest.json run ${FLYWHEEL}
COPY make_fsaverage.py /opt/make_fsaverage.py
COPY func_input/ /opt/func_input 
COPY flywheel.mlsettings /usr/flywheel.mlsettings
RUN chmod +x /flywheel/v0/run
RUN chmod +x /opt/func_input/*          

# Set the entrypoint  
ENTRYPOINT /flywheel/v0/run



