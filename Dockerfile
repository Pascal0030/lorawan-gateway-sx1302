# syntax=docker/dockerfile:1
FROM debian:bookworm-slim AS baseimage

# working image: satmandu/raspios:lite
# try to test debian:bookworm-slim socker image

# Arguments during build
ARG TARGETPLATFORM
ARG BUILDPLATFORM

ENV DEBUG="0"
ENV SERVER_ADDRESS="eu1.cloud.thethings.network"
ENV SERVER_PORT_UP="1700"
ENV SERVER_PORT_DOWN="1700"

#Labels
LABEL org.opencontainers.image.source=https://github.com/pascal0030/lorawan-gateway-sx1302
LABEL org.opencontainers.image.description="Loarawan Gateway Docker Image"
LABEL org.opencontainers.image.authors="Pasal0030"

# Install the required packages
# wget is for image debian:bookworm-slim
RUN apt update \
&& apt install -y \
        wget \
        make \
        gcc \
        jq \
        git \
        && rm -rf /var/lib/apt/lists/*


FROM baseimage AS raspberrypi4
LABEL org.opencontainers.image.target.system="raspberrypi4"
# Raspberry Pi 4 Installation
# Install sx1302_hal HAL
WORKDIR /app
RUN git clone https://github.com/Lora-net/sx1302_hal.git
WORKDIR /app/sx1302_hal
RUN make clean all
RUN make all
RUN cp tools/reset_lgw.sh util_chip_id/
RUN cp tools/reset_lgw.sh packet_forwarder/
WORKDIR /app/sx1302_hal/

COPY entrypoint.sh /app/sx1302_hal/entrypoint.sh
RUN chmod +x /app/sx1302_hal/entrypoint.sh

CMD [ "/bin/bash", "-c", "./entrypoint.sh" ]


FROM baseimage AS raspberrypi5
LABEL org.opencontainers.image.target.system="raspberrypi5"
# Raspberry Pi 5 Installation
# Install sx1302_hal_rpi5 HAL
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

RUN apt remove -y \
        jq

CMD [ "/bin/bash", "-c", "./entrypoint.sh" ]