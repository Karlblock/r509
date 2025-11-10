#!/bin/bash

# Script pour configurer le proxy 192.168.0.2:3128 pour tout le système

set -e

PROXY_HOST="192.168.0.2"
PROXY_PORT="3128"
PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}"

echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║           Configuration du proxy système                         ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""
echo "Proxy configuré : $PROXY_URL"
echo ""

# 1. Configuration du proxy pour APT
echo "1. Configuration APT..."
sudo tee /etc/apt/apt.conf.d/95proxy > /dev/null << EOF
Acquire::http::Proxy "$PROXY_URL";
Acquire::https::Proxy "$PROXY_URL";
Acquire::ftp::Proxy "$PROXY_URL";
EOF
echo "   ✓ APT configuré"

# 2. Configuration du proxy système (environment)
echo "2. Configuration des variables d'environnement système..."
sudo tee /etc/environment.d/proxy.conf > /dev/null << EOF
http_proxy=$PROXY_URL
https_proxy=$PROXY_URL
ftp_proxy=$PROXY_URL
HTTP_PROXY=$PROXY_URL
HTTPS_PROXY=$PROXY_URL
FTP_PROXY=$PROXY_URL
no_proxy=localhost,127.0.0.1,::1,10.0.0.0/8,192.168.0.0/16,172.16.0.0/12
NO_PROXY=localhost,127.0.0.1,::1,10.0.0.0/8,192.168.0.0/16,172.16.0.0/12
EOF

# Aussi dans /etc/profile.d pour tous les shells
sudo tee /etc/profile.d/proxy.sh > /dev/null << EOF
export http_proxy="$PROXY_URL"
export https_proxy="$PROXY_URL"
export ftp_proxy="$PROXY_URL"
export HTTP_PROXY="$PROXY_URL"
export HTTPS_PROXY="$PROXY_URL"
export FTP_PROXY="$PROXY_URL"
export no_proxy="localhost,127.0.0.1,::1,10.0.0.0/8,192.168.0.0/16,172.16.0.0/12"
export NO_PROXY="localhost,127.0.0.1,::1,10.0.0.0/8,192.168.0.0/16,172.16.0.0/12"
EOF
echo "   ✓ Variables d'environnement configurées"

# 3. Configuration pour Docker
echo "3. Configuration Docker..."
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf > /dev/null << EOF
[Service]
Environment="HTTP_PROXY=$PROXY_URL"
Environment="HTTPS_PROXY=$PROXY_URL"
Environment="NO_PROXY=localhost,127.0.0.1,::1,10.0.0.0/8,192.168.0.0/16,172.16.0.0/12"
EOF

# Configuration pour le daemon Docker (pull d'images)
sudo mkdir -p /root/.docker
sudo tee /root/.docker/config.json > /dev/null << EOF
{
  "proxies": {
    "default": {
      "httpProxy": "$PROXY_URL",
      "httpsProxy": "$PROXY_URL",
      "noProxy": "localhost,127.0.0.1,::1,10.0.0.0/8,192.168.0.0/16,172.16.0.0/12"
    }
  }
}
EOF

# Pour l'utilisateur ubuntu aussi
if [ -d "/home/ubuntu" ]; then
    sudo mkdir -p /home/ubuntu/.docker
    sudo tee /home/ubuntu/.docker/config.json > /dev/null << EOF
{
  "proxies": {
    "default": {
      "httpProxy": "$PROXY_URL",
      "httpsProxy": "$PROXY_URL",
      "noProxy": "localhost,127.0.0.1,::1,10.0.0.0/8,192.168.0.0/16,172.16.0.0/12"
    }
  }
}
EOF
    sudo chown -R ubuntu:ubuntu /home/ubuntu/.docker
fi

# Recharger Docker si le service existe
if systemctl is-active --quiet docker; then
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    echo "   ✓ Docker redémarré avec le proxy"
else
    echo "   ⚠ Docker n'est pas encore installé, sera configuré au démarrage"
fi

# 4. Configuration pour Snap
echo "4. Configuration Snap..."
if command -v snap &> /dev/null; then
    sudo snap set system proxy.http="$PROXY_URL"
    sudo snap set system proxy.https="$PROXY_URL"
    echo "   ✓ Snap configuré"
else
    echo "   ⚠ Snap n'est pas installé"
fi

# 5. Configuration pour wget
echo "5. Configuration wget..."
sudo tee /etc/wgetrc > /dev/null << EOF
http_proxy = $PROXY_URL
https_proxy = $PROXY_URL
ftp_proxy = $PROXY_URL
use_proxy = on
EOF

# Pour l'utilisateur ubuntu
if [ -d "/home/ubuntu" ]; then
    tee /home/ubuntu/.wgetrc > /dev/null << EOF
http_proxy = $PROXY_URL
https_proxy = $PROXY_URL
ftp_proxy = $PROXY_URL
use_proxy = on
EOF
    sudo chown ubuntu:ubuntu /home/ubuntu/.wgetrc
fi
echo "   ✓ wget configuré"

# 6. Configuration pour curl (via .curlrc)
echo "6. Configuration curl..."
if [ -d "/home/ubuntu" ]; then
    tee /home/ubuntu/.curlrc > /dev/null << EOF
proxy = "$PROXY_URL"
EOF
    sudo chown ubuntu:ubuntu /home/ubuntu/.curlrc
fi
echo "   ✓ curl configuré"

# 7. Configuration pour Git
echo "7. Configuration Git..."
sudo git config --system http.proxy "$PROXY_URL"
sudo git config --system https.proxy "$PROXY_URL"

if [ -d "/home/ubuntu" ]; then
    sudo -u ubuntu git config --global http.proxy "$PROXY_URL"
    sudo -u ubuntu git config --global https.proxy "$PROXY_URL"
fi
echo "   ✓ Git configuré"

# 8. Configuration pour containerd (si utilisé avec Minikube)
echo "8. Configuration containerd..."
sudo mkdir -p /etc/systemd/system/containerd.service.d
sudo tee /etc/systemd/system/containerd.service.d/http-proxy.conf > /dev/null << EOF
[Service]
Environment="HTTP_PROXY=$PROXY_URL"
Environment="HTTPS_PROXY=$PROXY_URL"
Environment="NO_PROXY=localhost,127.0.0.1,::1,10.0.0.0/8,192.168.0.0/16,172.16.0.0/12"
EOF

if systemctl is-active --quiet containerd; then
    sudo systemctl daemon-reload
    sudo systemctl restart containerd
    echo "   ✓ containerd redémarré avec le proxy"
else
    echo "   ⚠ containerd n'est pas encore installé"
fi

# 9. Source les nouvelles variables pour la session courante
if [ -f /etc/profile.d/proxy.sh ]; then
    source /etc/profile.d/proxy.sh
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                ✅ PROXY CONFIGURÉ AVEC SUCCÈS !                   ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""
echo "Proxy configuré pour :"
echo "  ✓ APT (installation de paquets)"
echo "  ✓ Variables d'environnement système"
echo "  ✓ Docker (daemon et client)"
echo "  ✓ Snap"
echo "  ✓ wget"
echo "  ✓ curl"
echo "  ✓ Git"
echo "  ✓ containerd"
echo ""
echo "Proxy : $PROXY_URL"
echo "No proxy : localhost, 127.0.0.1, réseaux privés (10.x, 172.16-31.x, 192.168.x)"
echo ""
echo "⚠️  Redémarrez votre session ou la VM pour que tous les changements soient actifs"
echo ""
echo "Pour vérifier :"
echo "  echo \$http_proxy"
echo "  curl -I http://google.com"
echo "  docker pull hello-world"
echo ""

# 10. Créer un script pour désactiver le proxy si nécessaire
echo "10. Création du script de désactivation..."
sudo tee /usr/local/bin/disable-proxy > /dev/null << 'EOFDIS'
#!/bin/bash
echo "Désactivation du proxy..."
sudo rm -f /etc/apt/apt.conf.d/95proxy
sudo rm -f /etc/environment.d/proxy.conf
sudo rm -f /etc/profile.d/proxy.sh
sudo rm -f /etc/systemd/system/docker.service.d/http-proxy.conf
sudo rm -f /etc/systemd/system/containerd.service.d/http-proxy.conf
sudo git config --system --unset http.proxy 2>/dev/null || true
sudo git config --system --unset https.proxy 2>/dev/null || true
unset http_proxy https_proxy ftp_proxy HTTP_PROXY HTTPS_PROXY FTP_PROXY no_proxy NO_PROXY
echo "✓ Proxy désactivé. Redémarrez votre session."
EOFDIS
sudo chmod +x /usr/local/bin/disable-proxy
echo "   ✓ Script de désactivation créé : /usr/local/bin/disable-proxy"

echo ""
echo "Pour désactiver le proxy plus tard, exécutez :"
echo "  sudo /usr/local/bin/disable-proxy"
echo ""
