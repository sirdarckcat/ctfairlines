FROM ubuntu:16.04
# for XCT
RUN apt update && apt install -y wget x11-apps libgl1-mesa-glx libdbus-1-3 libxi6 xkb-data build-essential g++ socat git strace python3-venv

RUN wget -q http://www.wetzel-technology.com/files/XCT/XCT.1.8.9.Ubuntu.16.04.run
RUN chmod +x ./XCT* && ./XCT*
COPY default.xct /root/XCT/bin/default.xct

RUN wget -q https://golang.org/dl/go1.15.3.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf go1.15.3.linux-amd64.tar.gz
RUN /usr/local/go/bin/go get github.com/reiver/go-telnet

COPY cdls /cdls
RUN cd /cdls; make unlock

COPY telnet.go shell.go
RUN /usr/local/go/bin/go build -o /out/shell .
RUN setcap CAP_NET_BIND_SERVICE=+ep /out/shell

# README.ctf: nsjail runs things as uid 1000
RUN groupadd -g 1000 user && useradd -g 1000 -u 1000 -ms /bin/bash user

CMD /cdls/unlock 'CTF{ThisIsATestingFlag}'; /out/shell
