# Dockerfile for asterisk-13 
# v0.1 05-16-2017
#
# usage is as follows:
# docker build <--build-arg 13.15.0> <-t asterisk:0.1> .

FROM alpine:3.5
LABEL maintainer "Darren McGrandle <darren@mcgrandle.com>"
ARG ASTERISK_VER=13.15.0

RUN apk update
WORKDIR /tmp/
ADD musl-glob-compat.patch /tmp/musl-glob-compat.patch

# To optimize final size of image need to add all the dev packages, do the compile then 
# remove all those same packages and clean up left over files in the same layer ...
# ... which means one giant RUN statement.  Someday I hope docker can optimize this better.

RUN apk add --no-cache build-base ncurses-dev util-linux-dev libxml2-dev bsd-compat-headers \
    bash jansson-dev sqlite-dev openssl-dev patch && \
    wget http://www.mcgrandle.com/asterisk-13.15.0.tar.gz && \
#   wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-$ASTERISK_VER.tar.gz && \
    tar -xf asterisk-$ASTERISK_VER.tar.gz && \
    cd /tmp/asterisk-$ASTERISK_VER && \
# take out the 'timeout' and 'continue' parameters for compatibility with simplified wget in Alpine
    sed -i 's/--timeout=$1//' configure configure.ac && sed -i 's/--continue//' sounds/Makefile && \
# patch for musl c compiler in Alpine
    patch -p1 < ../musl-glob-compat.patch && \
    ./configure --with-pjproject-bundled && \
    make menuselect.makeopts && \
    menuselect/menuselect --disable BUILD_NATIVE --enable cdr_csv --enable chan_pjsip menuselect.makeopts && \
#RUN menuselect/menuselect --disable BUILD_NATIVE --enable cdr_csv --enable chan_pjsip \
#    --enable chan_sip --enable res_snmp --enable res_http_websocket --enable core-sounds-en-g722 \
#    --enable core-sounds-en-ulaw --enable moh-opsound-ulaw --enable moh-opsound-g722 \
#    --enable extra-sounds-en-ulaw --enable extra-sounds-en-g722 menuselect.makeopts
    make && make install && \
    cd / && \
    rm -rf /tmp/* && \
    apk del --update build-base ncurses-dev util-linux-dev libxml2-dev bsd-compat-headers \
    jansson-dev openssl-dev patch
