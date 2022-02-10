# ubunu-config

## Install Docker

The following commands to install the Docker engine (all hosts)

```bash
# remove old versions
sudo apt remove docker docker-engine docker.io containerd runc

# update the apt package index
sudo apt update

# install prereqs to allow apt ot install packages over https
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release -y

# add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# set up the stable repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# install Docker engine
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io -y

# add user to Docker group
sudo usermod -a -G docker $USER

# set Docker to start automatically
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
```

Or you can run as a script using the command below:

```bash
curl https://raw.githubusercontent.com/markkerry/ubuntu-config/main/installDocker.sh > installDocker.sh

sudo chmod +x ./installDocker.sh && ./installDocker.sh
```

Verify the install is complete by running 

```bash
docker --version
```

Restart the server 

```bash
sudo systemctl reboot
```

And ensure Docker is running by typing

```bash
docker image ls
```

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
sudo kubeadm init --control-plane-endpoint ctrlplane:6443 --pod-network-cidr 10.10.0.0/16
```

Can get the name of the host the cluster is running on by typing

```bash
kubectl cluster-info
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
vim calico.yaml
```

Uncomment the `CALICO_IPV4POOL_CIDR` variable in the manifest and set it to the same value as your chosen pod CIDR

```yaml
- name: CALICO_IPV4POOL_CIDR
  value: "10.10.0.0/16"
```

Apply the deployment:

```bash
kubectl apply -f calico.yaml

# Ensure you copy the sudo kubeadm join --token command to be used later
```

Can put a watch on it and wait for it to complete

```bash
watch -n2 'kubectl get pods -A'
```

Once complete, check the ctrlplane node is the only node and state is ready

```bash
kubectl get nodes
```

Join Nodes (Only on Worker nodes) from the command copied earlier

```bash
sudo kubeadm join --token TOKEN_ID CONTROL_PLANE_HOSTNAME:CONTROL_PLANE_PORT --discovery-token-ca-cert-hash sha256:HASH
```


(ctrlplane) Once complete, check the ctrlplane has the nodes added

```bash
kubectl get nodes
```

Create a sample deployment file

```bash
vim sample-deployment.yaml
```

Sample Deployment file with 2 replicas running nginx:

```yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 2
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
kubectl apply -f sample-deployment.yaml

kubctl get deployments

kubctl get pods -o wide
```

If you want to run workloads on Control Plane it has to be untained (Only on Master Node)

```bash
kubectl taint nodes --all node-role.kubernetes.io/master-

# Change the replicas from 2 to 4
kubectl apply -f sample-deployment.yaml

kubctl get deployments

kubctl get pods -o wide
```


## Generate Token For Future Nodes

If you plan to add new nodes to the cluster at a later date and have lost the original token, can create a new one. Before we can use the manifest we need to be authenticated to the cluster. Generate a token to add worker Node (Only on Master node)

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
