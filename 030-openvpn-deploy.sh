#!/bin/bash
ibmcloud target -g $(terraform output -raw resource_group_name)
ibmcloud ks cluster config --admin --cluster $(terraform output -raw cluster_name)

kubectl apply -f 031-openvpn-namespace.yaml
kubectl config set-context $(kubectl config current-context) --namespace=ovpn

cd config
chown -R $USER:$USER server/*

kubectl create secret generic ovpn0-key --from-file=server/pki/private/VPN.SERVERNAME.COM.key
kubectl create secret generic ovpn0-cert --from-file=server/pki/issued/VPN.SERVERNAME.COM.crt
kubectl create secret generic ovpn0-pki \
  --from-file=server/pki/ca.crt --from-file=server/pki/dh.pem --from-file=server/pki/ta.key
kubectl create configmap ovpn0-conf --from-file=server/
kubectl create configmap ccd0 --from-file=server/ccd

kubectl apply -f ../032-openvpn-app.yaml
kubectl apply -f ../033-user-apps.yaml

kubectl describe services --namespace sample-app