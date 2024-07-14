#Delete the Consul crds
kubectl delete crd --selector app=consul

#Uninstall the consul
helm uninstall eks -n consul --no-hooks

#Delete the secrets
kubectl -n consul delete secrets consul-ca-cert consul-ca-key consul-gossip-encryption-key consul-server-cert consul-bootstrap-acl-token consul-enterprise-license-acl-token

#Delete the serviceaccount
kubectl -n consul delete serviceaccount consul-tls-init 

#Delete the Consul PVC
kubectl -n consul delete pvc data-consul-consul-server-0 data-consul-consul-server-1 data-consul-consul-server-2

#Delete all the services if any exists
kubectl delete all --all -n consul