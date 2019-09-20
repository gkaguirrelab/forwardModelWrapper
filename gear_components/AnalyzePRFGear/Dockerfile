FROM flywheel/matlab-mcr:v95
MAINTAINER Ozzy(ozenctaskin@hotmail.com)

#Update and install python
RUN apt-get update
RUN apt-get install python -y
RUN apt-get install zip unzip -y
RUN apt-get install git -y
RUN apt-get install python-pip -y
RUN pip install --upgrade pip
RUN pip install git+https://github.com/noahbenson/neuropythy.git
RUN pip install numpy

#Copy everything into a container
ENV FLYWHEEL /flywheel/v0/
RUN mkdir -p ${FLYWHEEL}
COPY manifest.json run ${FLYWHEEL}
COPY func_input/ /opt/func_input 
COPY workbench /opt/workbench
COPY first_level_output /opt/first_level_output
RUN chmod +x /opt/workbench/bin_linux64/wb_command
RUN chmod +x /flywheel/v0/run
RUN chmod +x /opt/func_input/WrapperAnalyzePRF/*/*            

# Set the entrypoint  
#ENTRYPOINT /flywheel/v0/run



