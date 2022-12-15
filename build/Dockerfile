FROM toddwint/transfer
COPY app /opt/eicar
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    HTTPPORT1=8080 \
    HTTPPORT2=8081 \
    HTTPPORT3=8082 \
    HTTPPORT4=8083 \
    HOSTNAME=eicarsrvr \
    APPNAME=eicar
RUN echo $HOSTNAME > /etc/hostname \
    && \
    cd /opt \
    && \
    rm -rf /opt/transfer \
    && \
    apt-get update \
    && \
    apt-get install -y \
    bzip2 \
    xz-utils \
    && \
#    apt-get remove -y \
#    rsyslog \
#    isc-dhcp-server \
#    ftp \
#    vsftpd \
#    tftp-hpa \
#    tftpd-hpa \
#    && \
    apt-get autoremove -y \
    && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /opt/eicar/debug
CMD ["/opt/eicar/scripts/startup.sh"]
