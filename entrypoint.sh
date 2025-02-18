#!/bin/bash
DEBUG=0
STARTMODE=0

if [-z {{$GATEWAY_ID}} || -z {{$SERVER_ADDRESS}} || -z {{$SERVER_PORT_UP}} || -z {{$SERVER_PORT_DOWN}} ]; then
  echo "INFO: GatewayID/ServerAddress/ServerPortUp/ServerPortDown is not set."
  STARTMODE=1
else if [ -e /opt/docker/lorawan-gateway/global_conf.json ]; then
  echo "INFO: global_conf.json file is found."
  STARTMODE=2
else
  echo "INFO: global_conf.json file is not found."
  echo "using container in debug mode"
  DEBUG=1
fi

cd ./util_chip_id/
./chip_id > ./chip_id_output.txt
sed -n 's/.*concentrator EUI: //p' ./chip_id_output.txt > ./chip_id.txt

# Print the EUI Output
printf "EUI: " && cat ./chip_id.txt
cd ..

if [ 1 -eq $DEBUG ]; then
  echo "required variables are not set - exiting"
  sleep 5
  exit 1
fi

# Copy the global_conf.json file to the test_conf file
cp ./packet_forwarder/global_conf.json.sx1250.EU868 ./packet_forwarder/test_conf

# Remove unwanted comments from the test_conf file
sed 's|/\*.*\*/||g' ./packet_forwarder/test_conf > ./packet_forwarder/test_conf.json

# Add the Gateway Configuration to the test_conf.json file
# .gateway_conf.gps_tty_path = "" -> is uesed to disable GPS functions because the GPS module does not work in the Docker container

if [ 1 -eq $STARTMODE ]; then
  jq --arg gatewayID $GATEWAY_ID --arg serverAddress $SERVER_ADDRESS --arg serverPortUp $SERVER_PORT_UP --arg serverPortDown $SERVER_PORT_DOWN '
    .gateway_conf.gateway_ID = $gatewayID |
    .gateway_conf.server_address = $serverAddress |
    .gateway_conf.serv_port_up = $serverPortUp |
    .gateway_conf.serv_port_down = $serverPortDown |
    .gateway_conf.gps_tty_path = ""' ./packet_forwarder/test_conf.json > ./packet_forwarder/temp.json && \
    mv ./packet_forwarder/temp.json ./packet_forwarder/test_conf.json    
else if [ 2 -eq $STARTMODE ]; then
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
