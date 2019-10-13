# Bayesian Fitting
# This script builds a docker image constructed on ubuntu.

# Usage: 
# cd into the directory that contains this directory and run "docker build -t analyzeprfbase ."

# If you want to bash into the image run "docker run -ti bayesianfitting" after the configuration  # is done. 

# To upload first login with "docker login" then tag your image with "docker tag <imageID> <username>/<imagename>" and push with "docker push <username>/<imagename>"

#################################################
FROM ubuntu:latest

# Update system
RUN apt-get update -y
RUN apt-get install wget -y

# Install python and pip
RUN apt-get install python3 -y
RUN apt-get install python3-pip -y

# Install git and zip
RUN apt-get install zip unzip -y
RUN apt-get install git -y

# Install script dependencies
RUN pip3 install git+https://github.com/noahbenson/neuropythy.git
RUN apt-get install default-jre -y
RUN apt-get install default-jdk -y

# Install MCR. Install path: usr/local/MATLAB/MATLAB_Runtime/v97
RUN wget -O opt/mcr.zip http://ssd.mathworks.com/supportfiles/downloads/R2019b/Release/0/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2019b_glnxa64.zip
RUN unzip opt/mcr.zip -d opt/
RUN opt/install -mode silent -agreeToLicense yes


