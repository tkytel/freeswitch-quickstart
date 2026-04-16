FROM debian:trixie-slim

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -yq install \
    # tools
    git build-essential cmake automake autoconf 'libtool-bin|libtool' \
    pkg-config \
    # general
    libssl-dev zlib1g-dev libdb-dev unixodbc-dev libncurses5-dev \
    libexpat1-dev libgdbm-dev bison erlang-dev libtpl-dev libtiff5-dev \
    uuid-dev \
    # core
    libpcre2-dev libedit-dev libsqlite3-dev libcurl4-openssl-dev nasm \
    # core codecs
    libogg-dev libspeex-dev libspeexdsp-dev \
    # mod_enum
    libldns-dev \
    # mod_python3
    python3-dev \
    # mod_av
    libavformat-dev libswscale-dev \
    # mod_lua
    liblua5.2-dev \
    # mod_opus
    libopus-dev \
    # mod_pgsql
    libpq-dev \
    # mod_sndfile
    libsndfile1-dev libflac-dev libogg-dev libvorbis-dev \
    # mod_shout
    libshout3-dev libmpg123-dev libmp3lame-dev

RUN git clone https://github.com/signalwire/freeswitch /usr/src/freeswitch
RUN git clone https://github.com/signalwire/libks /usr/src/libs/libks
RUN git clone https://github.com/freeswitch/sofia-sip /usr/src/libs/sofia-sip
RUN git clone https://github.com/freeswitch/spandsp /usr/src/libs/spandsp
RUN git clone https://github.com/signalwire/signalwire-c /usr/src/libs/signalwire-c

WORKDIR /usr/src/libs/libks
RUN cmake . -DCMAKE_INSTALL_PREFIX=/usr -DWITH_LIBBACKTRACE=1 && make install
WORKDIR /usr/src/libs/sofia-sip
RUN ./bootstrap.sh && ./configure --with-pic --with-glib=no --without-doxygen --disable-stun --prefix=/usr && make -j$(nproc) && make install
WORKDIR /usr/src/libs/spandsp
RUN ./bootstrap.sh && ./configure --with-pic --prefix=/usr && make -j$(nproc)` && make install
WORKDIR /usr/src/libs/signalwire-c
RUN PKG_CONFIG_PATH=/usr/lib/pkgconfig cmake . -DCMAKE_INSTALL_PREFIX=/usr && make install

WORKDIR /usr/src/freeswitch

RUN sed -i 's|#formats/mod_shout|formats/mod_shout|' ./build/modules.conf.in

RUN ./bootstrap.sh -j
RUN ./configure
RUN make -j$(nproc) && make install

RUN apt-get clean
RUN rm -rf /usr/src/*

COPY ./conf/ /etc/freeswitch/

# Ports
# H.323 Gatekeeper RAS port
EXPOSE 1719/udp
# H.323 Call Signaling
EXPOSE 1720/tcp
# MSRP
EXPOSE 2855-2856/tcp
# STUN service
EXPOSE 3478/udp
EXPOSE 3479/udp
# MLP protocol server
EXPOSE 5002/tcp
# Neighborhood service
EXPOSE 5003/udp
# SIP UAS
EXPOSE 5060
EXPOSE 5070
EXPOSE 5080
# ESL
EXPOSE 8021/tcp
# RTP / RTCP multimedia streaming
EXPOSE 16384-32768/udp
# Websocket
EXPOSE 5066/tcp
EXPOSE 7443/tcp
EXPOSE 8081-8082/tcp

CMD ["/usr/bin/freeswitch"]
