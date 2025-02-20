# syntax=docker/dockerfile:1
FROM debian:bookworm-slim AS baseimage

# satmandu/raspios:lite

# default environment variables
ENV DEBUG="0"
ENV SERVER_ADDRESS="eu1.cloud.thethings.network"
ENV SERVER_PORT_UP="1700"
ENV SERVER_PORT_DOWN="1700"

# labels
LABEL org.opencontainers.image.source=https://github.com/pascal0030/lorawan-gateway-sx1302
LABEL org.opencontainers.image.description="Loarawan Gateway Docker Image"
LABEL org.opencontainers.image.authors="Pasal0030"

# install the required packages
RUN echo "deb http://archive.raspberrypi.org/debian bookworm main" > /etc/apt/sources.list.d/raspi.list \
    apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libtool \
    git \
    make \
    gcc \
    unzip \
    wget \
    dkms \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://github.com/up-division/pinctrl-upboard/releases/download/v1.1.6/pinctrl-upboard_1.1.6_all.deb
RUN dpkg -i pinctrl-upboard_1.1.6_all.deb
RUN rm pinctrl-upboard_1.1.6_all.deb

# raspberry pi 5 installation
FROM baseimage AS raspberrypi5
LABEL org.opencontainers.image.target.system="raspberrypi5"
# install sx1302_hal_rpi5 HAL
WORKDIR /app
RUN wget https://files.waveshare.com/wiki/SX130X/demo/PI5/sx130x_hal_rpi5.zip
RUN unzip sx130x_hal_rpi5.zip
RUN rm sx130x_hal_rpi5.zip
WORKDIR /app/sx1302_hal_rpi5-master
RUN make clean all
RUN make all
RUN cp tools/reset_lgw.sh util_chip_id/ && cp tools/reset_lgw.sh packet_forwarder/

COPY entrypoint.sh /app/sx1302_hal_rpi5-master/entrypoint.sh
RUN chmod +x /app/sx1302_hal_rpi5-master/entrypoint.sh

CMD [ "/bin/bash", "-c", "./entrypoint.sh" ]