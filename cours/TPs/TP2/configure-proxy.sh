#!/bin/bash

# Script de configuration automatique du proxy IUT pour Kubernetes
# Ce script configure le proxy avec authentification pour l'environnement IUT

set -e  # Arrêter en cas d'erreur

echo "=========================================="
echo "Configuration Proxy IUT pour Kubernetes"
echo "=========================================="
echo ""

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérifier si on est root
if [ "$EUID" -eq 0 ]; then
   error "Ne PAS exécuter ce script en tant que root/sudo"
   exit 1
fi

echo "⚠️  ATTENTION : Ce script va configurer le proxy IUT avec authentification"
echo "   Adresse proxy : 192.168.0.2:3128"
echo ""

# Demander les identifiants
read -p "Username du compte C3 Proxmox: " PROXY_USER
read -sp "Password du compte C3 Proxmox: " PROXY_PASS
echo ""

if [ -z "$PROXY_USER" ] || [ -z "$PROXY_PASS" ]; then
    error "Les identifiants ne peuvent pas être vides"
    exit 1
fi

PROXY_URL="http://${PROXY_USER}:${PROXY_PASS}@192.168.0.2:3128"

echo ""
info "Configuration du proxy..."
echo ""

# 1. Configuration APT
info "1/5 Configuration du proxy pour APT..."
sudo tee /etc/apt/apt.conf.d/95proxies > /dev/null <<EOF
Acquire::http::Proxy "${PROXY_URL}";
Acquire::https::Proxy "${PROXY_URL}";
EOF
info "✓ Proxy APT configuré"

# 2. Configuration Docker daemon
info "2/5 Configuration du proxy pour Docker daemon..."
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf > /dev/null <<EOF
[Service]
Environment="HTTP_PROXY=${PROXY_URL}"
Environment="HTTPS_PROXY=${PROXY_URL}"
Environment="NO_PROXY=localhost,127.0.0.1,.local,.cluster.local,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
EOF

# Vérifier si Docker est installé
if command -v docker &> /dev/null; then
    info "Redémarrage de Docker..."
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    info "✓ Proxy Docker configuré et Docker redémarré"
else
    warn "Docker n'est pas installé, configuration enregistrée pour plus tard"
fi

# 3. Configuration du fichier ~/.docker/config.json
info "3/5 Configuration du proxy pour les conteneurs Docker..."
mkdir -p ~/.docker
cat > ~/.docker/config.json <<EOF
{
  "proxies": {
    "default": {
      "httpProxy": "${PROXY_URL}",
      "httpsProxy": "${PROXY_URL}",
      "noProxy": "localhost,127.0.0.1,.local,.cluster.local,192.168.0.0/16"
    }
  }
}
EOF
info "✓ Proxy conteneurs Docker configuré"

# 4. Création des alias et fonctions
info "4/5 Ajout des alias et fonctions dans ~/.bashrc..."

# Vérifier si déjà configuré
if grep -q "# Proxy IUT - Configuration automatique" ~/.bashrc 2>/dev/null; then
    warn "Alias déjà présents dans ~/.bashrc, passage ignoré"
else
    cat >> ~/.bashrc <<'EOF'

# Proxy IUT - Configuration automatique
proxy-on() {
    if [ -z "$PROXY_USER" ] || [ -z "$PROXY_PASS" ]; then
        read -p "Username du compte C3 Proxmox: " PROXY_USER
        read -sp "Password du compte C3 Proxmox: " PROXY_PASS
        echo
    fi
    export HTTP_PROXY="http://${PROXY_USER}:${PROXY_PASS}@192.168.0.2:3128"
    export HTTPS_PROXY="http://${PROXY_USER}:${PROXY_PASS}@192.168.0.2:3128"
    export NO_PROXY="localhost,127.0.0.1,.local,.cluster.local,192.168.0.0/16"
    echo "✓ Proxy activé"
}

proxy-off() {
    unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy NO_PROXY no_proxy
    echo "✓ Proxy désactivé"
}

proxy-status() {
    echo "=== Variables shell ==="
    env | grep -i proxy || echo "Aucune variable proxy"
    echo ""
    echo "=== Docker daemon ==="
    sudo systemctl show --property=Environment docker 2>/dev/null | grep PROXY || echo "Docker non configuré ou non installé"
}

proxy-check() {
    echo "Test 1: Variables shell (devrait être vide pour K8s)"
    VARS=$(env | grep -i proxy)
    if [ -z "$VARS" ]; then
        echo "✓ OK - Aucune variable proxy"
    else
        echo "❌ ERREUR - Variables proxy détectées:"
        echo "$VARS"
        echo "Solution: Exécuter 'proxy-off'"
    fi
    echo ""
    echo "Test 2: Docker daemon (devrait afficher le proxy avec 192.168.0.2:3128)"
    DOCKER_PROXY=$(sudo systemctl show --property=Environment docker 2>/dev/null | grep PROXY)
    if [ -z "$DOCKER_PROXY" ]; then
        echo "❌ ERREUR - Proxy Docker non configuré"
    else
        echo "✓ OK - Proxy Docker configuré"
        echo "$DOCKER_PROXY"
    fi
}
EOF
    info "✓ Alias et fonctions ajoutés"
fi

# 5. Désactivation du proxy shell (CRUCIAL pour Kubernetes)
info "5/5 Désactivation du proxy shell (requis pour Kind/Kubernetes)..."
unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy NO_PROXY no_proxy
info "✓ Proxy shell désactivé"

echo ""
echo "=========================================="
echo "Configuration terminée avec succès !"
echo "=========================================="
echo ""

info "Résumé de la configuration :"
echo "  ✓ Proxy APT : /etc/apt/apt.conf.d/95proxies"
echo "  ✓ Proxy Docker daemon : /etc/systemd/system/docker.service.d/http-proxy.conf"
echo "  ✓ Proxy conteneurs : ~/.docker/config.json"
echo "  ✓ Alias shell : ~/.bashrc"
echo "  ✓ Variables proxy shell : DÉSACTIVÉES (requis pour K8s)"
echo ""

warn "IMPORTANT : Vos identifiants sont stockés en clair dans les fichiers de configuration"
warn "Ces fichiers sont protégés par les permissions du système (root/user uniquement)"
echo ""

info "Commandes disponibles :"
echo "  • proxy-on       : Activer le proxy shell (rarement nécessaire)"
echo "  • proxy-off      : Désactiver le proxy shell (TOUJOURS pour K8s)"
echo "  • proxy-status   : Afficher l'état du proxy"
echo "  • proxy-check    : Vérifier la configuration complète"
echo ""

info "Prochaines étapes :"
echo "  1. Ouvrir un nouveau terminal OU exécuter : source ~/.bashrc"
echo "  2. Vérifier la configuration : proxy-check"
echo "  3. Tester APT : sudo apt update"
echo "  4. Tester Docker : docker pull hello-world"
echo "  5. Continuer avec le TP01/TP02"
echo ""

warn "RAPPEL : Pour Kubernetes/Kind, les variables shell doivent être DÉSACTIVÉES"
warn "Vérifiez toujours avec : env | grep -i proxy (ne doit RIEN afficher)"
echo ""

# Vérification finale
echo "=========================================="
echo "Vérification de la configuration"
echo "=========================================="
echo ""

# Test APT
info "Test APT..."
if sudo apt update > /dev/null 2>&1; then
    echo "✓ APT fonctionne avec le proxy"
else
    error "Erreur avec APT, vérifier /etc/apt/apt.conf.d/95proxies"
fi

# Test Docker
if command -v docker &> /dev/null; then
    info "Test Docker..."
    if docker pull hello-world > /dev/null 2>&1; then
        echo "✓ Docker peut télécharger des images"
        docker rmi hello-world > /dev/null 2>&1
    else
        error "Docker ne peut pas télécharger d'images"
        error "Vérifier : sudo systemctl show --property=Environment docker"
    fi
else
    warn "Docker n'est pas installé, test ignoré"
fi

# Vérification proxy shell
info "Vérification proxy shell..."
if env | grep -i proxy > /dev/null; then
    error "Des variables proxy sont encore actives !"
    error "Cela va causer des problèmes avec Kind/Kubernetes"
    error "Exécutez : proxy-off"
else
    echo "✓ Aucune variable proxy shell (correct pour K8s)"
fi

echo ""
echo "=========================================="
info "Configuration terminée !"
echo "=========================================="
