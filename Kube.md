## Install Kubernetes

Add K8S key and Repo (All hosts)

```bash
curl -s https://packages.cloud.google.com/apt... | sudo apt-key add -
cat (ADD 2 "LESS THAN" SIGNS HERE WITHOUT BRACKETS)EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
```

Update the package repository and Install K8S components (All hosts):

```bash
sudo apt-get update
sudo apt-get install -y kubelet=1.18.1-00 
sudo apt-get install -y kubeadm=1.18.1-00 
sudo apt-get install -y kubectl=1.18.1-00
sudo apt-mark hold kubelet kubeadm kubectl
```

Add the hosts entry (All hosts)

```bash
edit the file "/etc/hosts"
```

Disable SWAP (All hosts)

```bash
sudo swapoff -a
```

edit /etc/fstab to remove the swap entry by commenting it out

Initiate the Cluster(Only on Master node)

```bash
sudo kubeadm init --control-plane-endpoint kube-master:6443 --pod-network-cidr 10.10.0.0/16
```

Set the kubectl context auth to connect to the cluster(Only on Master node)

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Pod Network Addon(Calico) (Only on Master node)

```bash
vi calico.yaml
```

Generate Token to add worker Node(Only on Master node)

```bash
#Create a new Token
sudo kubeadm token create
#List Tokens created
sudo kubeadm token list
#Find Certificate Hash on Master
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | 
   openssl rsa -pubin -outform der 2(GREATER THAN SYMBOL)/dev/null | 
   openssl dgst -sha256 -hex | sed 's/^.* //'
```

Join Nodes (Only on Worker nodes)

```bash
sudo kubeadm join --token TOKEN_ID CONTROL_PLANE_HOSTNAME:CONTROL_PLANE_PORT --discovery-token-ca-cert-hash sha256:HASH
```

(Formed using outputs, treat CAPS as variables to be replaced)

Want to run workloads on Master?(Only on Master Node)

```bash
kubectl taint nodes --all node-role.kubernetes.io/master-
```

Sample Deployment file:

```yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
```

Apply the deployment:

```bash
kubectl apply -f FILE_NAME
```
