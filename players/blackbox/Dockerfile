FROM ubuntu:latest
RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y wget python3-pip python3-venv openjdk-8-jdk net-tools netcat unzip curl strace
RUN wget -q https://dl.bintray.com/kaitai-io/universal/0.9/kaitai-struct-compiler-0.9.zip
RUN unzip kaitai-struct-compiler-0.9.zip
COPY . fdr
RUN cd kaitai-struct-compiler-0.9/bin && ./kaitai-struct-compiler --target python /fdr/arinc825.ksy && mv pcm825.py /fdr
RUN pip3 install kaitaistruct jsonpickle

VOLUME /fdr/log

# README.ctf: nsjail runs things as uid 1000
RUN groupadd -g 1000 user && useradd -g 1000 -u 1000 -ms /bin/bash user

CMD cd /fdr && ./fdr.sh
