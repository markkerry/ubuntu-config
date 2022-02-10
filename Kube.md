## Install Kubernetes

Add K8S key and Repo (All hosts)

```bash
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

Update the package repository and Install K8S components (All hosts):

```bash
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

Disable SWAP (All hosts)

```bash
sudo swapoff -a
```

Edit `/etc/fstab` to remove the swap entry by commenting it out

```bash
sudo vim /etc/fstab

# /swap.img   none  swap  sw  0   0
```

Then restart the servers.

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
curl https://projectcalico.docs.tigera.io/manifests/calico.yaml -O
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
