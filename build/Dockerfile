FROM toddwint/mybaseimage
COPY app /opt/eicar
LABEL LICENSE="GPL-3.0-or-later"
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    TZ=UTC \
    HTTPPORT1=8080 \
    HTTPPORT2=8081 \
    HTTPPORT3=8082 \
    HTTPPORT4=8083 \
    HUID=59900 \
    HGID=59900 \
    HOSTNAME=eicarsrvr \
    APPNAME=eicar
RUN apt-get update \
    && \
    apt-get install -y \
    bzip2 \
    xz-utils \
    webfs \
    && \
    echo $HOSTNAME > /etc/hostname \
    && \
    apt-get autoremove -y \
    && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /opt/eicar/debug
CMD ["/opt/eicar/scripts/startup.sh"]
