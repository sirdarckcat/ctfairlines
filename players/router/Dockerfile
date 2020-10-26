FROM ubuntu:16.04
RUN apt update && apt install -y socat git strace wget

RUN wget -q https://golang.org/dl/go1.15.3.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf go1.15.3.linux-amd64.tar.gz
RUN /usr/local/go/bin/go get github.com/reiver/go-telnet

COPY telnet.go router.go
RUN /usr/local/go/bin/go build -o /out/router .

COPY unlock.sh unlock.sh
RUN chmod +x unlock.sh

CMD /out/router
