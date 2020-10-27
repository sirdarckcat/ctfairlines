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

RUN apt update && apt install -y socat iproute2 util-linux

RUN useradd -ms /bin/bash user
USER user
COPY --chown=user organizers /home/user
RUN cd /home/user/nsjail && make clean && make
USER root
CMD cd /home/user/ && ./start-network.sh
