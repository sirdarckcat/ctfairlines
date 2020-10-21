FROM ubuntu:16.04
RUN apt update && apt install -y wget
RUN apt update && apt-get install -y x11-apps libgl1-mesa-glx libdbus-1-3 libxi6
RUN wget http://www.wetzel-technology.com/files/XCT/XCT.1.8.9.Ubuntu.16.04.run
RUN chmod +x ./XCT* && ./XCT*
CMD cd /root/XCT/bin && ./XCT
