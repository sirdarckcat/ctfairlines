FROM ubuntu:latest
RUN apt update && apt install -y python2 socat iproute2 binutils strace

COPY example.py libcanaero.so /

# CMD (echo 1337; sleep 3; echo 1234; sleep 3; sleep 1d) | python2 example.py
CMD strace socat UDP-RECVFROM:50707,ip-add-membership=239.40.41.42:172.20.4.2,fork,reuseaddr STDOUT
