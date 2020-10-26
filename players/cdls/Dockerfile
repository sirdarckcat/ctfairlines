FROM ubuntu:latest
RUN apt update && apt install -y verilator build-essential g++ strace
WORKDIR /root
COPY Makefile cdls.cpp CDLS.sv ./
COPY CANflight_API CANflight_API
RUN make all
CMD /root/main
