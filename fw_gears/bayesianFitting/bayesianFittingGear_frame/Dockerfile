# This makes a container for the gear. Replace the first path next to the second COPY function 
# below with a path to your local compiled matlab function

FROM gkaguirrelab/gearbase:v1
MAINTAINER Ozzy(ozenctaskin@hotmail.com)

#Copy everything into a container
ENV FLYWHEEL /flywheel/v0/
RUN mkdir -p ${FLYWHEEL}
COPY manifest.json run ${FLYWHEEL}
COPY interpolate_cifti.py /opt/
COPY render_func/ /opt/render_func
COPY postproc_func/ /opt/postproc_func 
COPY cortmag_func/ /opt/cortmag_func 
COPY template.dtseries.nii /opt/
RUN chmod +x /flywheel/v0/run
RUN chmod +x /opt/interpolate_cifti.py  
RUN chmod +x /opt/render_func/* 
RUN chmod +x /opt/postproc_func/*   
RUN chmod +x /opt/cortmag_func/*      


# Set the entrypoint  
ENTRYPOINT /flywheel/v0/run



