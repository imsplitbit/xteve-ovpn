# Jackett and OpenVPN, JackettVPN

FROM debian:buster
MAINTAINER imsplitbit

ENV DEBIAN_FRONTEND noninteractive

WORKDIR /opt

# Make directories
RUN mkdir -p /config/openvpn /config/iptv-vpn

# Update, upgrade and install required packages
RUN apt update \
    && apt -y upgrade \
    && apt -y install \
    apt-transport-https \
    wget \
    curl \
    gnupg \
    sed \
    openvpn \
    emacs-nox \
    curl \
    moreutils \
    net-tools \
    dos2unix \
    kmod \
    iptables \
    procps \
    ipcalc\
    grep \
    libcurl4 \
    liblttng-ust0 \
    libkrb5-3 \
    zlib1g \
    tzdata \
    tmux \
    && apt-get clean \
    && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*

# Install xteve
RUN wget https://github.com/xteve-project/xTeVe-Downloads/raw/master/xteve_linux_amd64.zip -O temp.zip; unzip temp.zip -d /usr/bin/; rm temp.zip
RUN chmod +x /usr/bin/xteve


VOLUME /config

ADD openvpn/ /etc/openvpn
ADD xteve /etc/xteve

RUN chmod +x /etc/xteve/*.sh /etc/openvpn/*.sh

EXPOSE 8080
CMD ["/bin/bash", "/etc/openvpn/start.sh"]