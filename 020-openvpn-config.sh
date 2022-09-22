#!/bin/bash
mkdir config
cd config

# from https://github.com/kylemanna/docker-openvpn/blob/master/bin/ovpn_genconfig
cidr2mask()
{
    local i
    local subnetmask=""
    local cidr=${1#*/}
    local full_octets=$(($cidr/8))
    local partial_octet=$(($cidr%8))

    for ((i=0;i<4;i+=1)); do
        if [ $i -lt $full_octets ]; then
            subnetmask+=255
        elif [ $i -eq $full_octets ]; then
            subnetmask+=$((256 - 2**(8-$partial_octet)))
        else
            subnetmask+=0
        fi
        [ $i -lt 3 ] && subnetmask+=.
    done
    echo $subnetmask
}

# Used often enough to justify a function
getroute() {
    echo ${1%/*} $(cidr2mask $1)
}

## Generate server config and certificates
echo ">>> Generating server config..."
docker run --net=none --rm -it -v $PWD:/etc/openvpn \
  kylemanna/openvpn ovpn_genconfig \
  -u udp://VPN.SERVERNAME.COM:1194 \
  -C 'AES-256-GCM' -a 'SHA384' -T 'TLS-ECDHE-ECDSA-WITH-AES-256-GCM-SHA384' \
  -b \
  -p "route $(getroute $(cd .. && terraform output -raw pod_subnet))" \
  -p "route $(getroute $(cd .. && terraform output -raw service_subnet))"

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
