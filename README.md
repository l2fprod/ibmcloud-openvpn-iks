# OpenVPN running in Kubernetes cluster on IBM Cloud

Based on:
- https://hub.docker.com/r/kylemanna/openvpn
- https://cloud.ibm.com/docs/containers?topic=containers-vpc-lbaas#setup_vpc_nlb


## Deploy

```
./010-infrastructure.sh
./020-openvpn-config.sh
./030-openvpn-deploy.sh
```

## Connect

Once everything is deployed:

```
openvpn --config config/client.ovpn --remote <load-balancer-domain-or-public-ip>
```

## Destroy

```
./100-openvpn-remove.sh
./110-infrastructure-destroy.sh
```
