#!/bin/bash
STARTMODE=0

# Define color codes
RED='\033[31m'
GREEN='\033[32m'
NC='\033[0m' # No Color

cd ./util_chip_id/
./chip_id > ./chip_id_output.txt
sed -n 's/.*concentrator EUI: //p' ./chip_id_output.txt > ./chip_id.txt

# Print the EUI Output
GATEWAY_ID=$(cat ./chip_id.txt)
echo -e ${GREEN}"EUI: "${GATEWAY_ID}${NC}
cd ..

if [ -e /opt/docker/lorawan-gateway/global_conf.json ]; then
  echo "INFO: global_conf.json file is found."
  STARTMODE=2
elif [ -n "$GATEWAY_ID" ] && [ -n "$SERVER_ADDRESS" ] && [ -n "$SERVER_PORT_UP" ] && [ -n "$SERVER_PORT_DOWN" ]; then
  echo "INFO: GatewayID/ServerAddress/ServerPortUp/ServerPortDown is set."
  STARTMODE=1
elif [ 1 "$DEBUG" -eq 1 ]; then
  echo "INFO: Debug mode is enabled. Please note the EUI-NUMBER."
  echo \n
  echo "exiting Container in 10 seconds"
  sleep 10
  exit 1
else
  echo "ERROR: GatewayID/ServerAddress/ServerPortUp/ServerPortDown is not set."
  echo "ERROR: global_conf.json file is not found."
  echo "ERROR: Debug mode is not enabled."
  echo -e ${RED}"ERROR: Please check if the container is running with "--privileged" flag."${NC}
  echo "INFO: Exiting Container in 10 seconds"
  sleep 10
  exit 1
fi

# Copy the global_conf.json file to the test_conf file
cp ./packet_forwarder/global_conf.json.sx1250.EU868 ./packet_forwarder/test_conf

# Remove unwanted comments from the test_conf file
sed 's|/\*.*\*/||g' ./packet_forwarder/test_conf > ./packet_forwarder/test_conf.json

# Add the Gateway Configuration to the test_conf.json file
# .gateway_conf.gps_tty_path = "" -> is uesed to disable GPS functions because the GPS module does not work in the Docker container

if [ 1 -eq "$STARTMODE" ]; then
  jq --arg gatewayID "$GATEWAY_ID" \
     --arg serverAddress "$SERVER_ADDRESS" \
     --arg serverPortUp "$SERVER_PORT_UP" \
     --arg serverPortDown "$SERVER_PORT_DOWN" \
    '
    .gateway_conf.gateway_ID = $gatewayID |
    .gateway_conf.server_address = $serverAddress |
    .gateway_conf.serv_port_up = $serverPortUp |
    .gateway_conf.serv_port_down = $serverPortDown |
    .gateway_conf.gps_tty_path = "" |
    .gateway_conf.servers = [
      {
        "gateway_ID": $gatewayID,
        "server_address": $serverAddress,
        "serv_port_up": $serverPortUp,
        "serv_port_down": $serverPortDown,
        "serv_enabled": true
      }
    ]
    ' ./packet_forwarder/test_conf.json > ./packet_forwarder/temp.json && \
    mv ./packet_forwarder/temp.json ./packet_forwarder/test_conf.json    
elif [ 2 -eq "$STARTMODE" ]; then
  jq --slurpfile src /opt/docker/lorawan-gateway/global_conf.json '
    .gateway_conf.gateway_ID = $src[0].gateway_conf.gateway_ID |
    .gateway_conf.server_address = $src[0].gateway_conf.servers[0].server_address |
    .gateway_conf.serv_port_up = $src[0].gateway_conf.servers[0].serv_port_up |
    .gateway_conf.serv_port_down = $src[0].gateway_conf.servers[0].serv_port_down |
    .gateway_conf.gps_tty_path = "" |
    .gateway_conf.servers = $src[0].gateway_conf.servers
  ' ./packet_forwarder/test_conf.json > ./packet_forwarder/temp.json && \
  mv ./packet_forwarder/temp.json ./packet_forwarder/test_conf.json
fi

# Run the Lora Packet Forwarder
cd ./packet_forwarder/
./lora_pkt_fwd -c ./test_conf.json
