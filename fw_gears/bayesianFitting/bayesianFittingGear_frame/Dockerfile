# This makes a container for the gear. Replace the first path next to the second COPY function 
# below with a path to your local compiled matlab function

FROM gkaguirrelab/bayesianfittingbase:0.1.1
MAINTAINER Ozzy(ozenctaskin@hotmail.com)

#Copy everything into a container
ENV FLYWHEEL /flywheel/v0/
RUN mkdir -p ${FLYWHEEL}
COPY manifest.json run ${FLYWHEEL}
RUN chmod +x /flywheel/v0/run
COPY plot_func/ /opt/plot_func
RUN chmod +x /opt/plot_func/*          

# Set the entrypoint  
ENTRYPOINT /flywheel/v0/run



