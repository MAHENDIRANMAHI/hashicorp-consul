# hashicorp-consul
Consul deployment with private link
### Demo project accompanying a [Consul crash course video](https://www.youtube.com/watch?v=s3I1kKKfjtQ) on YouTube

#### Get access to EKS cluster
```sh
# install and configure awscli with access creds
aws configure

# check existing clusters list
aws eks list-clusters --region eu-central-1 --output table --query 'clusters'

# check config of specific cluster - VPC config shows whether public access enabled on cluster API endpoint
aws eks describe-cluster --region eu-central-1 --name myapp-eks-cluster --query 'cluster.resourcesVpcConfig'

# create kubeconfig file for cluster in ~/.kube
aws eks update-kubeconfig --region eu-central-1 --name myapp-eks-cluster

kubectl get svc

=================%%%%%%%%%%%%%%%%%%=================

server-0 pod:
We need the server or the control plan to manage the proxies to inject the proxies.

Connect-Injector pod:
This is the responsible for injecting pods

Transparent-proxy:
Means you can use kubernetes DNS to access upstream services and all inbound and outbound traffic within the pods 
is redirected to go through the proxy

Pods:
In pods 2 containers running, one is app and other is injected proxy

Init container:
mahi@Mahendirans-MacBook-Air kubernetes % kubectl -n app logs adservice-5f8c767f66-x94gj
Defaulted container "server" out of: server, consul-dataplane, consul-connect-inject-init (init)

consul-connect-inject-init: 
-> Init container this is the consul process it prepares the environment for the proxy.
-> Proxy needs information about the other services are there so that if its host service wants to talk to other services.
-> It also gets the TLS certificate for the secure, so all of that is actually handled by the init container that injects all this information,
   into the pod so that the proxy has access to them.


####COMMANDS####

Intentions:
Defines access control for services via connect
Consule intention create source-service dest-service ##create intention, allow rule
higher precedence (higher number) will evaluate and will not check others
 #consul intention list
 #consul intention create web db 
 #consul intention create -deny web db 
 #consul intention check web db

#Get all clusters
$kubectl config get-contexts

=================%%%%%%%%%%%%%%%%%%=================
# Create the NLB in Dc1
Listiner Use TCP 443 for TG

SG 
Inbound
HTTPS 443 anywhere
Outbound
ALL trafic and anywhere

TG
TCP 8443#

Endpoint Servcie
com.amazonaws.vpce.us-east-1.vpce-svc-0b3635dff3b06140d
Choose NLB
ent-nlb

Endpoint
SG
we need to pass VPC cidr

# Create the NLB in Dc2 (l1 sandbox)
Listiner Use TCP 443 for TG

SG 
Inbound
HTTPS 443 anywhere
Outbound
ALL trafic and anywhere

TG
TCP 8443

Endpoint Servcie
com.amazonaws.vpce.us-east-1.vpce-svc-030abe84b8cf6d684
Choose NLB
l1-ent-nlb 

Endpoint
SG
we need to pass VPC cidr

# Install the Consul
$ helm command

# Apply the targetbinding
# Apply the mesh gateway
# Apply the procy default

# Create the NLB in Dc1


# Create the NLB in Dc2

=================%%%%%%%%%%%%%%%%%%=================
Delete namespace
Step 1:
kubectl get namespace <YOUR_NAMESPACE> -o json > <YOUR_NAMESPACE>.json
remove kubernetes from finalizers array which is under spec

Step 2:
kubectl replace --raw "/api/v1/namespaces/<YOUR_NAMESPACE>/finalize" -f ./<YOUR_NAMESPACE>.json

Step 3:
kubectl get namespace

=================%%%%%%%%%%%%%%%%%%=================
Alias
aws eks \
    update-kubeconfig \
    --region $(terraform -chdir=aws/dc2 output -raw region) \
    --name $(terraform -chdir=aws/dc2 output -raw cluster_name) \
    --alias=dc2

aws eks \
    update-kubeconfig \
    --region us-east-1 \
    --name consul-private-cluster \
    --alias=consul-ent

=================%%%%%%%%%%%%%%%%%%=================

#Secret creation
secret=$(cat 1931d1f4-bdfd-6881-f3f5-19349374841f.hclic)
kubectl -n consul create secret generic consul-ent-license --from-literal="key=${secret}"

#delete crds manually
kubectl edit crds <name>

=================%%%%%%%%%%%%%%%%%%=================

#Uninstall consul
https://developer.hashicorp.com/consul/docs/k8s/operations/uninstall
kubectl delete crd --selector app=consul
helm uninstall eks -n consul --no-hooks
kubectl -n consul delete secrets consul-ca-cert consul-ca-key consul-gossip-encryption-key consul-server-cert consul-bootstrap-acl-token consul-enterprise-license-acl-token
kubectl -n consul delete serviceaccount consul-tls-init 
kubectl -n consul delete pvc data-consul-consul-server-0
kubectl delete all --all -n consul

#helm repo delete
cd /home/ec2-user/.cache/helm/repository/

#Install
helm install -n consul eks hashicorp/consul --values consul-ent-values.yaml --debug
helm get values eks -n consul
kubectl -n consul apply -f mesh.yaml 
kubectl -n consul apply -f proxydefaults.yaml 
kubectl -n consul apply -f targetbinding.yaml


=================%%%%%%%%%%%%%%%%%%=================

#dc1
kubectl apply -f acceptor-on-dc1-for-dc2.yaml
kubectl get peeringacceptors -o yaml
kubectl get secrets peering-token-dc2
kubectl get secrets peering-token-dc2 -o yaml
kubectl get secret peering-token-dc2 -o yaml | kubectl apply -f -

#Later
kubectl apply -f public-api-peer.yaml

#Delete
kubectl delete peeringacceptors dc2

#dc2 
cat peering-dc2.yaml | kubectl apply -f -
kubectl apply -f dialer-dc2.yaml 
kubectl get peeringdialer
kubectl apply -f exportedsvc-products-api.yaml
kubectl get exportedservices
kubectl apply -f intention-dc1-public-api-to-dc2-products-api.yaml
kubectl get serviceintentions

#Delete
kubectl delete secrets peering-token-dc2
kubectl delete peeringdialer dc1
kubectl delete exportedservices default
kubectl delete serviceintentions dc1-public-api-to-dc2-products-api


=================%%%%%%%%%%%%%%%%%%=================
Get the Acl token
  kubectl get secrets/consul-bootstrap-acl-token  --template={{.data.token}} -n consul| base64 -d


1. Genreate the token in eks ---research

2. And peer in the lke --- l1sandbox

3. Apply the export in lke with peer eks 
Apply the export in l1sandbox with peer research
export in l1
import in research  

4. Apply the service resolver in eks -- research
   
5. Delete the shipping in eks -- research

=================%%%%%%%%%%%%%%%%%%=================


kubectl exec --namespace=consul -it --context=dc1 consul-server-0 \
-- curl --cacert /consul/tls/ca/tls.crt --header "X-Consul-Token: $(kubectl --context=dc1 --namespace=consul get secrets consul-bootstrap-acl-token -o go-template='{{.data.token|base64decode}}')" "https://127.0.0.1:8501/v1/peering/dc2" \ | jq

kubectl exec --namespace=consul -it consul-server-0 -- curl --cacert /consul/tls/ca/tls.crt --header "X-Consul-Token: " "https://127.0.0.1:8501/v1/peering/dc2" | jq

=================%%%%%%%%%%%%%%%%%%=================