#!/bin/bash
mkdir config
cd config

## Generate server config and certificates
echo ">>> Generating server config..."
docker run --net=none --rm -it -v $PWD:/etc/openvpn \
  kylemanna/openvpn ovpn_genconfig \
  -u udp://VPN.SERVERNAME.COM:1194 \
  -C 'AES-256-GCM' -a 'SHA384' -T 'TLS-ECDHE-ECDSA-WITH-AES-256-GCM-SHA384' \
  -b
  # additional network to route
  #-n 185.121.177.177 -n 185.121.177.53 -n 87.98.175.85 \

docker run \
  -e EASYRSA_ALGO=ec \
  -e EASYRSA_CURVE=secp384r1 \
  -e EASYRSA_BATCH=yes \
  -e EASYRSA_REQ_CN=localserver \
  --net=none --rm -it -v $PWD:/etc/openvpn kylemanna/openvpn ovpn_initpki nopass

docker run --net=none --rm -it -v $PWD:/etc/openvpn \
  kylemanna/openvpn ovpn_copy_server_files

## Generate client ECC certificate and retrieve client configuration with embedded certificates
echo ">>> Generating client config..."
export CLIENTNAME="client"
docker run -e EASYRSA_ALGO=ec -e EASYRSA_CURVE=secp384r1 \
  --net=none --rm -it -v $PWD:/etc/openvpn kylemanna/openvpn easyrsa build-client-full $CLIENTNAME nopass
docker run --net=none --rm -v $PWD:/etc/openvpn kylemanna/openvpn ovpn_getclient $CLIENTNAME > $CLIENTNAME.ovpn

## Generate client RSA certificates if your client doesn't support ECC
# docker run --net=none --rm -it -v $PWD:/etc/openvpn kylemanna/openvpn easyrsa build-client-full $CLIENTNAME
# docker run --net=none --rm -v $PWD:/etc/openvpn kylemanna/openvpn ovpn_getclient $CLIENTNAME > $CLIENTNAME.ovpn
