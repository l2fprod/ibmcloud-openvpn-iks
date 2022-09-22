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

Once everything is deployed, find the OpenVPN domain name with:

```sh
OPENVPN_DOMAIN_NAME=$(ibmcloud is load-balancers --output json | jq -r '.[] | select(.profile.family=="Network") | .hostname')
echo "OpenVPN domain is $OPENVPN_DOMAIN_NAME"
```

Start the OpenVPN client with:

```sh
openvpn --config config/client.ovpn --remote $OPENVPN_DOMAIN_NAME
```

From there you can access the `nginx` deployed in another namespace:

```sh
NGINX_IP=$(kubectl get service nginx-service --namespace sample-app -o json | jq -r .spec.clusterIP)
echo "NGINX Cluster IP is $NGINX_IP"
curl http://$NGINX_IP
```

## Destroy

```
./100-openvpn-remove.sh
./110-infrastructure-destroy.sh
```
