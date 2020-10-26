FROM ubuntu:latest
RUN apt update && DEBIAN_FRONTEND="noninteractive" apt install -y wget python3-pip openjdk-8-jdk net-tools netcat unzip curl strace
RUN wget -q https://dl.bintray.com/kaitai-io/universal/0.9/kaitai-struct-compiler-0.9.zip
RUN unzip kaitai-struct-compiler-0.9.zip
COPY . .
RUN cd kaitai-struct-compiler-0.9/bin && ./kaitai-struct-compiler --target python /arinc825.ksy && mv pcm825.py /
RUN pip3 install kaitaistruct jsonpickle

CMD ./fdr.sh
