FROM ubuntu:20.04

# build sybil
RUN apt-get update
RUN apt-get install -y gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf python3-pip 
RUN apt-get install -y automake m4 libtool zip

WORKDIR /rmHarmony
COPY . /rmHarmony/
RUN pip3 install -r requirements.txt
RUN rm src/build -fr
