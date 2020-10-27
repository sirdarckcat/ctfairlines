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

RUN apt update && apt install -y socat iproute2 util-linux strace net-tools uidmap git tar wget

RUN wget -q https://golang.org/dl/go1.15.3.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf go1.15.3.linux-amd64.tar.gz

RUN groupadd -g 1000 user && useradd -g 1000 -u 1000 -ms /bin/bash user

COPY --chown=user organizers /home/user
USER user
RUN cd /home/user/nsjail && make
RUN /usr/local/go/bin/go get github.com/armon/go-socks5
RUN cd /home/user && /usr/local/go/bin/go build -o socks .
USER root
EXPOSE 23
CMD cd /home/user/ && socat tcp-listen:23,fork system:./start-network.sh
