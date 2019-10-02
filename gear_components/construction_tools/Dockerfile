# This script builds a docker image constructed on flywheel's mcr image.

# Usage: 
# cd into the directory that contains this directory and run "docker build -t analyzeprfbase ."

# If you want to bash into the image run "docker run -ti analyzeprfbase" after the configuration  # is done. 

# To upload first login with "docker login" then tag your image with "docker tag <imageID> <username>/<imagename>" and push with "docker push <username>/<imagename>"

#################################################
# Get the base flywheel image
FROM flywheel/matlab-mcr:v95

# Update system
RUN apt-get update

# Install python and pip
RUN apt-get install python -y
RUN apt-get install python-pip -y
RUN pip install --upgrade pip

# Install git and zip
RUN apt-get install zip unzip -y
RUN apt-get install git -y

# Install script dependencies
RUN pip install git+https://github.com/noahbenson/neuropythy.git
RUN pip install numpy

# Install workbench. Installed in usr/bin/ 
RUN apt-get install connectome-workbench -y
