FROM ubuntu:latest
RUN apt update && apt install -y verilator build-essential g++ strace
WORKDIR /root
COPY Makefile cdls.cpp CDLS.sv ./
COPY CANflight_API CANflight_API
RUN make all
# README.ctf: nsjail runs things as uid 1000
RUN groupadd -g 1000 user && useradd -g 1000 -u 1000 -ms /bin/bash user
CMD /root/main
