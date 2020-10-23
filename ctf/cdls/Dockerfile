FROM ubuntu:latest
RUN apt update && apt install -y verilator build-essential g++
COPY Makefile cdls.cpp CDLS.sv ./
RUN make all
CMD make run