FROM ubuntu:latest
COPY chroots /chroots
RUN apt update && apt install -y busybox-static
RUN ls /chroots/ | xargs -i cp $(which busybox) /chroots/{}/tar
RUN ls /chroots/ | xargs -i chroot /chroots/{} /tar x -zf img.tgz
CMD bash
