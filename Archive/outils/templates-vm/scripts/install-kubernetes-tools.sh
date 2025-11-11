#!/bin/bash

# Script d'installation de tous les outils Kubernetes pour l'image Proxmox

set -e

echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║     Installation des outils Kubernetes (Minikube, kubectl...)    ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""

# Détection de l'utilisateur (ubuntu ou autre)
TARGET_USER="${SUDO_USER:-ubuntu}"

# 1. Mise à jour du système
echo "1. Mise à jour du système..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
echo "   ✓ Système à jour"

# 2. Installation des dépendances de base
echo "2. Installation des dépendances..."
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    wget \
    git \
    vim \
    nano \
    htop \
    net-tools \
    conntrack \
    socat \
    ipvsadm \
    jq \
    unzip
echo "   ✓ Dépendances installées"

# 3. Installation de Docker
echo "3. Installation de Docker..."
if ! command -v docker &> /dev/null; then
    # Ajouter la clé GPG officielle de Docker
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Ajouter le dépôt Docker
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Installer Docker
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Ajouter l'utilisateur au groupe docker
    usermod -aG docker $TARGET_USER

    # Activer et démarrer Docker
    systemctl enable docker
    systemctl start docker

    echo "   ✓ Docker installé : $(docker --version)"
else
    echo "   ✓ Docker déjà installé : $(docker --version)"
fi

# 4. Installation de kubectl
echo "4. Installation de kubectl..."
KUBECTL_VERSION="v1.28.0"
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl
echo "   ✓ kubectl installé : $(kubectl version --client --short 2>/dev/null || kubectl version --client)"

# 5. Installation de Minikube
echo "5. Installation de Minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64
echo "   ✓ Minikube installé : $(minikube version --short)"

# 6. Installation de Helm
echo "6. Installation de Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
echo "   ✓ Helm installé : $(helm version --short)"

# 7. Installation de crictl
echo "7. Installation de crictl..."
CRICTL_VERSION="v1.28.0"
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz
tar zxvf crictl-${CRICTL_VERSION}-linux-amd64.tar.gz -C /usr/local/bin
rm -f crictl-${CRICTL_VERSION}-linux-amd64.tar.gz
echo "   ✓ crictl installé : $(crictl --version)"

# 8. Installation de k9s (UI terminal pour Kubernetes)
echo "8. Installation de k9s..."
K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | jq -r '.tag_name')
wget https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz
tar -xzf k9s_Linux_amd64.tar.gz -C /usr/local/bin k9s
rm k9s_Linux_amd64.tar.gz
chmod +x /usr/local/bin/k9s
echo "   ✓ k9s installé : ${K9S_VERSION}"

# 9. Installation de kubectx et kubens
echo "9. Installation de kubectx et kubens..."
git clone https://github.com/ahmetb/kubectx /opt/kubectx
ln -sf /opt/kubectx/kubectx /usr/local/bin/kubectx
ln -sf /opt/kubectx/kubens /usr/local/bin/kubens
echo "   ✓ kubectx et kubens installés"

# 10. Configuration des alias et auto-complétion
echo "10. Configuration des alias et auto-complétion..."
cat >> /home/$TARGET_USER/.bashrc << 'EOF'

# Kubernetes aliases
alias k='kubectl'
alias mk='minikube'
alias h='helm'

# kubectl completion
source <(kubectl completion bash)
complete -F __start_kubectl k

# minikube completion
source <(minikube completion bash)
complete -F __start_minikube mk

# helm completion
source <(helm completion bash)

# kubectx and kubens completion
if [ -f /opt/kubectx/completion/kubectx.bash ]; then
    source /opt/kubectx/completion/kubectx.bash
fi
if [ -f /opt/kubectx/completion/kubens.bash ]; then
    source /opt/kubectx/completion/kubens.bash
fi

# Prompt avec contexte Kubernetes
export PS1='\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\[\e[1;33m\]$(kubectl config current-context 2>/dev/null | sed "s/^/ (k8s: /" | sed "s/$/)/")\ \[\e[0m\]\$ '
EOF
chown $TARGET_USER:$TARGET_USER /home/$TARGET_USER/.bashrc
echo "   ✓ Alias et auto-complétion configurés"

# 11. Créer un script de démarrage rapide de Minikube
echo "11. Création des scripts utiles..."
cat > /usr/local/bin/start-k8s << 'EOFSTART'
#!/bin/bash
echo "Démarrage de Minikube..."
minikube start --driver=docker --memory=3000mb --cpus=2
echo ""
echo "✓ Minikube démarré !"
echo ""
echo "Status :"
minikube status
echo ""
echo "Cluster info :"
kubectl cluster-info
echo ""
echo "Pour accéder au dashboard :"
echo "  minikube dashboard"
EOFSTART
chmod +x /usr/local/bin/start-k8s

cat > /usr/local/bin/stop-k8s << 'EOFSTOP'
#!/bin/bash
echo "Arrêt de Minikube..."
minikube stop
echo "✓ Minikube arrêté"
EOFSTOP
chmod +x /usr/local/bin/stop-k8s

echo "   ✓ Scripts start-k8s et stop-k8s créés"

# 12. Message MOTD personnalisé
echo "12. Configuration du message de bienvenue..."
cat > /etc/update-motd.d/99-kubernetes << 'EOFMOTD'
#!/bin/bash
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║     VM Kubernetes prête - Minikube + kubectl + Helm       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "🛠️  Outils installés :"
if command -v docker &> /dev/null; then
    echo "  ✓ Docker    : $(docker --version | cut -d' ' -f3 | tr -d ',')"
fi
if command -v minikube &> /dev/null; then
    echo "  ✓ Minikube  : $(minikube version --short 2>/dev/null | cut -d' ' -f3)"
fi
if command -v kubectl &> /dev/null; then
    echo "  ✓ kubectl   : $(kubectl version --client --short 2>/dev/null | head -1 | cut -d' ' -f3)"
fi
if command -v helm &> /dev/null; then
    echo "  ✓ Helm      : $(helm version --short 2>/dev/null | cut -d':' -f2 | tr -d ' ')"
fi
if command -v k9s &> /dev/null; then
    echo "  ✓ k9s       : $(k9s version --short 2>/dev/null | head -1 | cut -d' ' -f2)"
fi
echo ""
echo "🚀 Démarrage rapide :"
echo "  start-k8s      # Démarrer Minikube"
echo "  stop-k8s       # Arrêter Minikube"
echo "  k get nodes    # Vérifier les nodes (alias de kubectl)"
echo "  k9s            # Interface TUI pour Kubernetes"
echo ""
if systemctl is-active --quiet docker && command -v minikube &> /dev/null; then
    MINIKUBE_STATUS=$(minikube status --format='{{.Host}}' 2>/dev/null || echo "Stopped")
    if [ "$MINIKUBE_STATUS" = "Running" ]; then
        echo "📊 Statut Minikube : 🟢 Running"
        echo "   Contexte : $(kubectl config current-context 2>/dev/null)"
    else
        echo "📊 Statut Minikube : 🔴 Stopped"
        echo "   Démarrer avec : start-k8s"
    fi
fi
echo ""
EOFMOTD
chmod +x /etc/update-motd.d/99-kubernetes
echo "   ✓ Message de bienvenue configuré"

# 13. Nettoyage
echo "13. Nettoyage..."
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*
echo "   ✓ Nettoyage effectué"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║            ✅ INSTALLATION TERMINÉE AVEC SUCCÈS !                 ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""
echo "Outils installés :"
echo "  ✓ Docker $(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',')"
echo "  ✓ Minikube $(minikube version --short 2>/dev/null | cut -d' ' -f3)"
echo "  ✓ kubectl $(kubectl version --client --short 2>/dev/null | head -1 | cut -d' ' -f3)"
echo "  ✓ Helm $(helm version --short 2>/dev/null)"
echo "  ✓ crictl $(crictl --version 2>/dev/null | cut -d' ' -f3)"
echo "  ✓ k9s"
echo "  ✓ kubectx & kubens"
echo ""
echo "Scripts disponibles :"
echo "  ✓ start-k8s  - Démarrer Minikube"
echo "  ✓ stop-k8s   - Arrêter Minikube"
echo ""
echo "Alias configurés :"
echo "  ✓ k = kubectl"
echo "  ✓ mk = minikube"
echo "  ✓ h = helm"
echo ""
