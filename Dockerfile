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

RUN apt update && apt install -y socat iproute2 util-linux strace net-tools uidmap git tar wget python3

RUN wget -q https://golang.org/dl/go1.15.3.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf go1.15.3.linux-amd64.tar.gz

RUN groupadd -g 1000 user && useradd -g 1000 -u 1000 -ms /bin/bash user

COPY --chown=user router /home/user
USER user
RUN cd /home/user/nsjail && make
RUN /usr/local/go/bin/go get github.com/armon/go-socks5
RUN cd /home/user && /usr/local/go/bin/go build -o socks .
USER root

RUN echo nameserver 127.0.0.1 > /chroots/blackbox/etc/resolv.conf
EXPOSE 23
CMD /home/user/nsjail/nsjail -t 630 --max_cpus 1 -Ml --port 23 -u 0:0:65536 -g 0:0:65536 --proc_rw --keep_caps -D /home/user --disable_clone_newcgroup --disable_clone_newuts --disable_clone_newipc --disable_clone_newpid --disable_clone_newns --disable_clone_newuser --disable_clone_newnet --keep_caps --keep_env --rw --chroot / ./start-network.sh
