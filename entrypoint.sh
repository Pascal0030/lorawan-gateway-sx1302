#!/bin/bash
cd ./util_chip_id/
./chip_id > ./chip_id_output.txt
sed -n 's/.*concentrator EUI: //p' ./chip_id_output.txt > ./chip_id.txt

# Print the EUI Output
printf "EUI: " && cat ./chip_id.txt
cd ..

# Copy the global_conf.json file to the test_conf file
cp ./packet_forwarder/global_conf.json.sx1250.EU868 ./packet_forwarder/test_conf

# Remove unwanted comments from the test_conf file
sed 's|/\*.*\*/||g' ./packet_forwarder/test_conf > ./packet_forwarder/test_conf.json

# Add the Gateway Configuration to the test_conf.json file

# .gateway_conf.gps_tty_path = "" is uesed to disable GPS functions because the GPS module does not work in the Docker container
jq --slurpfile src /opt/docker/lorawan-gateway/global_conf.json '
  .gateway_conf.gateway_ID = $src[0].gateway_conf.gateway_ID |
  .gateway_conf.server_address = $src[0].gateway_conf.servers[0].server_address |
  .gateway_conf.serv_port_up = $src[0].gateway_conf.servers[0].serv_port_up |
  .gateway_conf.serv_port_down = $src[0].gateway_conf.servers[0].serv_port_down |
  .gateway_conf.gps_tty_path = "" |
  .gateway_conf.servers = $src[0].gateway_conf.servers
' ./packet_forwarder/test_conf.json > ./packet_forwarder/temp.json && \
mv ./packet_forwarder/temp.json ./packet_forwarder/test_conf.json

# Run the Lora Packet Forwarder
cd ./packet_forwarder/
./lora_pkt_fwd -c ./test_conf.json
