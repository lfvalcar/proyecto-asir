# Docker Runtime

## Add Docker's official GPG key:
sudo apt-get update

sudo apt-get install ca-certificates curl

sudo install -m 0755 -d /etc/apt/keyrings

sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc

sudo chmod a+r /etc/apt/keyrings/docker.asc

## Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo containerd config default > /etc/containerd/config.toml

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
  SystemdCgroup = true

## Comprobación
sudo systemctl restart containerd.service

# Kubeadm, Kubelet, Kubectl

sudo apt-get update

sudo apt-get install -y apt-transport-https gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update

sudo apt-get install -y kubelet kubeadm kubectl

sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl enable --now kubelet

## Comprobación
sudo systemctl status kubelet

# Prerequisitos antes de iniciar un cluster con kubeadm

sudo modprobe br_netfilter
echo br_netfilter | sudo tee /etc/modules-load.d/kubernetes.conf

sudo swapoff -a
\# /swapfile                                 none            swap    sw              0       0

# Kubeadm-config.yaml

sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Postinstalación

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
 
# Instalación de un complemento de red de pod

kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# Agregar otro nodo

sudo kubeadm token create --print-join-command

kubeadm join 10.244.0.0:6443 \
    --token <token> \
    --discovery-token-ca-cert-hash sha256:<token-ca-cert-hash>
