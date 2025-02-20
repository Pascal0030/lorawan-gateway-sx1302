# syntax=docker/dockerfile:1
FROM alpine AS baseimage

ENV DEBUG="0"
ENV SERVER_ADDRESS="eu1.cloud.thethings.network"
ENV SERVER_PORT_UP="1700"
ENV SERVER_PORT_DOWN="1700"

# labels
LABEL org.opencontainers.image.source=https://github.com/pascal0030/lorawan-gateway-sx1302
LABEL org.opencontainers.image.description="Loarawan Gateway Docker Image"
LABEL org.opencontainers.image.authors="Pasal0030"

# Install the required packages
RUN apk add --no-cache \
        wget \
        unzip \
        make \
        gcc \
        jq \
        git \
        raspberrypi-utils \
        raspberrypi-utils-pinctrl \
        libc-dev \
        gcompat \
        linux-headers \
        raspberrypi-dev \
        raspberrypi-libs

FROM satmandu/raspios:lite AS baseimage2

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
RUN apt update \
&& apt install -y \
        wget \
        unzip \
        make \
        gcc \
        jq \
        git \
        && rm -rf /var/lib/apt/lists/*


FROM baseimage AS raspberrypi5
LABEL org.opencontainers.image.target.system="raspberrypi5"
# raspberry pi 5 installation
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