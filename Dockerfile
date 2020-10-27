FROM ubuntu:latest
COPY chroots /chroots
RUN apt update && apt install -y busybox-static
RUN ls /chroots/ | xargs -i cp $(which busybox) /chroots/{}/tar
RUN ls /chroots/ | xargs -i chroot /chroots/{} /tar x -zf img.tgz

RUN apt-get -y update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    autoconf \
    bison \
    flex \
    gcc \
    g++ \
    git \
    libprotobuf-dev \
    libnl-route-3-dev \
    libtool \
    make \
    pkg-config \
    protobuf-compiler

RUN apt update && apt install -y socat iproute2 util-linux strace net-tools

RUN groupadd -g 1000 user && useradd -g 1000 -u 1000 -ms /bin/bash user

COPY organizers /home/user
RUN cd /home/user/nsjail && make clean && make
CMD cd /home/user/ && ./start-network.sh
