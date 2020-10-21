FROM ubuntu:latest
RUN apt update && apt install -y python2 socat iproute2 binutils strace

# CMD socat STDOUT UDP4-RECV:34568,broadcast
CMD sleep 1d