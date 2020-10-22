FROM ubuntu:16.04
RUN apt update && apt install -y wget
RUN apt update && apt-get install -y x11-apps libgl1-mesa-glx libdbus-1-3 libxi6
RUN wget -q http://www.wetzel-technology.com/files/XCT/XCT.1.8.9.Ubuntu.16.04.run
RUN chmod +x ./XCT* && ./XCT*
COPY default.xct /root/XCT/bin/default.xct

RUN apt update && apt install -y socat git strace xkb-data

RUN wget -q https://golang.org/dl/go1.15.3.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf go1.15.3.linux-amd64.tar.gz
RUN /usr/local/go/bin/go get github.com/reiver/go-telnet

COPY telnet.go shell.go
RUN /usr/local/go/bin/go build -o /out/shell .

CMD /out/shell
