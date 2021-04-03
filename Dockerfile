FROM ubuntu:focal

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y software-properties-common --no-install-recommends \
 && rm -rf /var/lib/apt/lists/*

RUN add-apt-repository ppa:nfs-ganesha/nfs-ganesha-3.0 \
 && add-apt-repository ppa:nfs-ganesha/libntirpc-3.0 \
 && apt-get install -y nfs-ganesha nfs-ganesha-vfs --no-install-recommends \
 && apt-get autoremove -y \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
 && mkdir -p /export /var/run/dbus \
 && chown messagebus:messagebus /var/run/dbus

# Add startup script
COPY start.sh /

# NFS ports and portmapper
EXPOSE 2049 38465-38467 662 111/udp 111

# Start Ganesha NFS daemon by default
CMD ["/start.sh"]