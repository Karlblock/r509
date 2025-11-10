#!/bin/bash

# Script pour créer un template Proxmox avec Minikube, kubectl, Helm préinstallés

set -e

echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║     Création d'un template Proxmox avec Kubernetes/Minikube      ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""

# Configuration
VM_ID="${1:-9000}"  # ID du template (par défaut 9000)
TEMPLATE_NAME="ubuntu-k8s-template"
STORAGE="local-lvm"  # Adapter selon votre storage Proxmox
CLOUD_IMAGE_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
IMAGE_FILE="ubuntu-22.04-cloudimg.img"

echo "Configuration :"
echo "  VM ID       : $VM_ID"
echo "  Nom         : $TEMPLATE_NAME"
echo "  Storage     : $STORAGE"
echo "  Image       : Ubuntu 22.04 Cloud Image"
echo ""

read -p "Continuer ? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

echo ""
echo "⚠️  Ce script doit être exécuté sur le serveur Proxmox ou via SSH"
echo ""
read -p "Êtes-vous sur le serveur Proxmox ? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Connectez-vous à votre serveur Proxmox et exécutez ce script."
    echo "Ou copiez le script avec : scp $0 root@proxmox-server:/root/"
    exit 1
fi

# Vérifier que nous sommes sur Proxmox
if ! command -v qm &> /dev/null; then
    echo "❌ Erreur : 'qm' n'est pas disponible. Vous devez être sur un serveur Proxmox."
    exit 1
fi

echo ""
echo "1. Téléchargement de l'image Ubuntu Cloud..."
if [ ! -f "$IMAGE_FILE" ]; then
    wget -O "$IMAGE_FILE" "$CLOUD_IMAGE_URL"
else
    echo "   Image déjà téléchargée."
fi

echo ""
echo "2. Création de la VM $VM_ID..."
qm create $VM_ID --name $TEMPLATE_NAME --memory 4096 --cores 2 --net0 virtio,bridge=vmbr0

echo ""
echo "3. Import du disque..."
qm importdisk $VM_ID $IMAGE_FILE $STORAGE

echo ""
echo "4. Configuration du disque..."
qm set $VM_ID --scsihw virtio-scsi-pci --scsi0 $STORAGE:vm-$VM_ID-disk-0

echo ""
echo "5. Configuration Cloud-Init..."
qm set $VM_ID --ide2 $STORAGE:cloudinit
qm set $VM_ID --boot c --bootdisk scsi0
qm set $VM_ID --serial0 socket --vga serial0
qm set $VM_ID --agent enabled=1

echo ""
echo "6. Redimensionnement du disque à 32GB..."
qm resize $VM_ID scsi0 32G

echo ""
echo "7. Configuration des paramètres Cloud-Init..."
cat > /tmp/cloud-init-user.yml << 'EOFCI'
#cloud-config
users:
  - name: ubuntu
    groups: sudo, docker
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys: []

package_update: true
package_upgrade: true

packages:
  - apt-transport-https
  - ca-certificates
  - curl
  - gnupg
  - lsb-release
  - software-properties-common
  - git
  - vim
  - wget
  - conntrack
  - socat

runcmd:
  # Installation de Docker
  - mkdir -p /etc/apt/keyrings
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  - echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  - apt-get update
  - apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  - usermod -aG docker ubuntu

  # Installation de kubectl
  - curl -LO "https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl"
  - install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  - rm kubectl

  # Installation de Minikube
  - curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  - install minikube-linux-amd64 /usr/local/bin/minikube
  - rm minikube-linux-amd64

  # Installation de Helm
  - curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

  # Installation de crictl
  - wget https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.28.0/crictl-v1.28.0-linux-amd64.tar.gz
  - tar zxvf crictl-v1.28.0-linux-amd64.tar.gz -C /usr/local/bin
  - rm -f crictl-v1.28.0-linux-amd64.tar.gz

  # Configuration des alias
  - echo 'alias k=kubectl' >> /home/ubuntu/.bashrc
  - echo 'alias mk=minikube' >> /home/ubuntu/.bashrc
  - echo 'source <(kubectl completion bash)' >> /home/ubuntu/.bashrc
  - echo 'complete -F __start_kubectl k' >> /home/ubuntu/.bashrc

  # Message de bienvenue
  - echo '#!/bin/bash' > /etc/update-motd.d/99-kubernetes
  - echo 'echo ""' >> /etc/update-motd.d/99-kubernetes
  - echo 'echo "╔════════════════════════════════════════════════════════╗"' >> /etc/update-motd.d/99-kubernetes
  - echo 'echo "║     VM Kubernetes prête avec Minikube + kubectl        ║"' >> /etc/update-motd.d/99-kubernetes
  - echo 'echo "╚════════════════════════════════════════════════════════╝"' >> /etc/update-motd.d/99-kubernetes
  - echo 'echo ""' >> /etc/update-motd.d/99-kubernetes
  - echo 'echo "Pour démarrer Minikube :"' >> /etc/update-motd.d/99-kubernetes
  - echo 'echo "  minikube start --driver=docker"' >> /etc/update-motd.d/99-kubernetes
  - echo 'echo ""' >> /etc/update-motd.d/99-kubernetes
  - echo 'echo "Outils installés :"' >> /etc/update-motd.d/99-kubernetes
  - echo 'echo "  - Docker : $(docker --version)"' >> /etc/update-motd.d/99-kubernetes
  - echo 'echo "  - Minikube : $(minikube version --short)"' >> /etc/update-motd.d/99-kubernetes
  - echo 'echo "  - kubectl : $(kubectl version --client --short 2>/dev/null | head -1)"' >> /etc/update-motd.d/99-kubernetes
  - echo 'echo "  - Helm : $(helm version --short)"' >> /etc/update-motd.d/99-kubernetes
  - echo 'echo ""' >> /etc/update-motd.d/99-kubernetes
  - chmod +x /etc/update-motd.d/99-kubernetes

power_state:
  mode: reboot
  timeout: 300
EOFCI

echo ""
echo "8. Conversion de la VM en template..."
qm template $VM_ID

echo ""
echo "9. Nettoyage..."
rm -f $IMAGE_FILE

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                    ✅ TEMPLATE CRÉÉ AVEC SUCCÈS !                 ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""
echo "Template ID : $VM_ID"
echo "Nom         : $TEMPLATE_NAME"
echo ""
echo "Pour créer une VM à partir de ce template :"
echo "  qm clone $VM_ID <nouveau-vm-id> --name ma-vm-k8s --full"
echo "  qm set <nouveau-vm-id> --sshkey ~/.ssh/id_rsa.pub"
echo "  qm set <nouveau-vm-id> --ipconfig0 ip=dhcp"
echo "  qm start <nouveau-vm-id>"
echo ""
echo "Ou via l'interface web Proxmox :"
echo "  Clic droit sur le template → Clone"
echo ""
