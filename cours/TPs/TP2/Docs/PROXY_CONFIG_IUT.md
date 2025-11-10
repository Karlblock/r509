# Configuration Proxy IUT - Guide Rapide

Guide ultra-rapide pour configurer le proxy IUT avec authentification.

## 📋 Informations Proxy IUT

```
Adresse  : 192.168.0.2
Port     : 3128
Auth     : username:password (vos identifiants IUT)
Format   : http://username:password@192.168.0.2:3128
NO_PROXY : localhost,127.0.0.1,.local,.cluster.local,192.168.0.0/16
```

## 🚀 Configuration Automatique (RECOMMANDÉ)

### Une seule commande pour tout configurer

```bash
cd ~/IUT/r509/TPs/TP2
./configure-proxy.sh
```

Le script vous demandera votre login et mot de passe IUT et configurera automatiquement :
- ✅ Proxy APT
- ✅ Proxy Docker daemon
- ✅ Proxy conteneurs Docker
- ✅ Alias shell (proxy-on, proxy-off, proxy-check)
- ✅ Désactivation du proxy shell pour Kind/Kubernetes

### Après l'exécution du script

```bash
# Recharger la configuration
source ~/.bashrc

# Vérifier que tout est OK
proxy-check

# Tester APT
sudo apt update

# Tester Docker
docker pull hello-world
```

## 🔧 Configuration Manuelle

Si vous préférez configurer manuellement ou si le script ne fonctionne pas :

### 1. Proxy APT

```bash
# Remplacer username:password par vos identifiants
sudo tee /etc/apt/apt.conf.d/95proxies > /dev/null <<'EOF'
Acquire::http::Proxy "http://username:password@192.168.0.2:3128";
Acquire::https::Proxy "http://username:password@192.168.0.2:3128";
EOF

sudo apt update
```

### 2. Proxy Docker daemon

```bash
sudo mkdir -p /etc/systemd/system/docker.service.d

# Remplacer username:password par vos identifiants
sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf > /dev/null <<'EOF'
[Service]
Environment="HTTP_PROXY=http://username:password@192.168.0.2:3128"
Environment="HTTPS_PROXY=http://username:password@192.168.0.2:3128"
Environment="NO_PROXY=localhost,127.0.0.1,.local,.cluster.local,192.168.0.0/16"
EOF

sudo systemctl daemon-reload
sudo systemctl restart docker

# Vérifier
sudo systemctl show --property=Environment docker | grep PROXY
```

### 3. Alias shell

```bash
cat >> ~/.bashrc <<'EOF'

# Proxy IUT - Remplacer username:password
alias proxy-on='export HTTP_PROXY="http://username:password@192.168.0.2:3128"; export HTTPS_PROXY="http://username:password@192.168.0.2:3128"; export NO_PROXY="localhost,127.0.0.1,.local,.cluster.local,192.168.0.0/16"'
alias proxy-off='unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy NO_PROXY no_proxy'
alias proxy-status='env | grep -i proxy'
alias proxy-check='echo "=== Variables shell ==="; env | grep -i proxy || echo "OK - Vide"; echo "=== Docker daemon ==="; sudo systemctl show --property=Environment docker | grep PROXY'
EOF

source ~/.bashrc
```

### 4. Désactiver le proxy shell (CRUCIAL)

```bash
proxy-off
env | grep -i proxy  # Ne doit RIEN afficher
```

## ✅ Vérification

### Checklist complète

```bash
# 1. Proxy shell désactivé (CRITIQUE pour K8s)
env | grep -i proxy
# ➜ Ne doit RIEN afficher

# 2. Proxy Docker configuré
sudo systemctl show --property=Environment docker | grep PROXY
# ➜ Doit afficher HTTP_PROXY et HTTPS_PROXY avec 192.168.0.2:3128

# 3. APT fonctionne
sudo apt update
# ➜ Doit réussir

# 4. Docker peut pull
docker pull hello-world
# ➜ Doit télécharger l'image

# 5. Commande proxy-check
proxy-check
# ➜ Variables shell : vides
# ➜ Docker daemon : avec proxy
```

## 🎯 Règles à retenir

### Pour Kind/Kubernetes

```bash
# AVANT de travailler avec Kind ou kubectl
proxy-off
env | grep -i proxy  # Vérifier que c'est vide

# Si des variables apparaissent
unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy NO_PROXY no_proxy
```

### Pour télécharger des packages

```bash
# APT : fonctionne automatiquement (configuré dans /etc/apt/apt.conf.d/95proxies)
sudo apt update
sudo apt install package-name

# Docker : fonctionne automatiquement (configuré dans systemd)
docker pull image-name

# curl/wget : activer le proxy temporairement si nécessaire
proxy-on
curl https://example.com
proxy-off  # Remettre off immédiatement
```

## 🔴 Problèmes fréquents

### ImagePullBackOff sur les pods

```bash
# Cause : Proxy Docker mal configuré
# Solution :
sudo systemctl show --property=Environment docker | grep PROXY
# Si vide, reconfigurer :
./configure-proxy.sh
# OU manuellement comme expliqué ci-dessus
```

### Kind ne démarre pas

```bash
# Cause : Variables proxy actives
# Solution :
proxy-off
env | grep -i proxy  # Vérifier que c'est vide
kind delete cluster --name tp-cluster
kind create cluster --name tp-cluster --config kind-cluster-config.yaml
```

### apt update échoue

```bash
# Cause : Proxy APT mal configuré
# Solution :
cat /etc/apt/apt.conf.d/95proxies
# Si vide ou incorrect, reconfigurer :
./configure-proxy.sh
# OU manuellement
```

### kubectl très lent

```bash
# Cause : Variables proxy actives
# Solution :
proxy-off
env | grep -i proxy  # Vérifier que c'est vide
```

## 📝 Sécurité

### ⚠️ Avertissement

Les fichiers de configuration contiennent vos identifiants en clair :
- `/etc/apt/apt.conf.d/95proxies` (accessible root uniquement)
- `/etc/systemd/system/docker.service.d/http-proxy.conf` (accessible root uniquement)
- `~/.bashrc` (accessible par vous uniquement)
- `~/.docker/config.json` (accessible par vous uniquement)

**Protection :** Ces fichiers ont des permissions restrictives par défaut.

**Recommandation :** Ne pas commiter `~/.bashrc` dans un repo Git public.

### Alternative plus sécurisée

Utiliser la **Méthode 2** du script avec fonctions interactives :

```bash
# Dans ~/.bashrc, utiliser les fonctions au lieu des alias
proxy-on() {
    read -p "Username du compte C3 Proxmox: " PROXY_USER
    read -sp "Password du compte C3 Proxmox: " PROXY_PASS
    echo
    export HTTP_PROXY="http://${PROXY_USER}:${PROXY_PASS}@192.168.0.2:3128"
    export HTTPS_PROXY="http://${PROXY_USER}:${PROXY_PASS}@192.168.0.2:3128"
    export NO_PROXY="localhost,127.0.0.1,.local,.cluster.local,192.168.0.0/16"
}
```

Ainsi, le mot de passe est demandé à chaque utilisation.

## 🚀 Workflow quotidien

```bash
# 1. Au début de votre session
proxy-check

# 2. Vérifier que le proxy shell est désactivé
env | grep -i proxy  # Doit être vide

# 3. Si pas vide
proxy-off

# 4. Travailler avec Kubernetes
kubectl get nodes
kind get clusters

# 5. Si besoin de télécharger quelque chose avec curl
proxy-on
curl https://example.com
proxy-off  # Immédiatement après
```

## 📚 Ressources

- [Guide complet](PROXY_GUIDE.md) - Documentation détaillée
- [Guide TP01](INSTALL_TP1_RAPIDE.md) - Installation avec proxy
- [Guide TP02](INSTALL_TP2_RAPIDE.md) - Déploiement d'applications
- [README](README.md) - Vue d'ensemble

## 💡 Astuces

### Vérification rapide avant de travailler

```bash
# Créer un alias de vérification rapide
alias k8s-ready='proxy-off && env | grep -i proxy && echo "---" && sudo systemctl show --property=Environment docker | grep PROXY'

# Utilisation
k8s-ready
# Si rien n'apparaît avant "---" et que le proxy Docker est affiché après, vous êtes prêt !
```

### Reset complet de la configuration

```bash
# Si tout est cassé, recommencer à zéro
sudo rm -f /etc/apt/apt.conf.d/95proxies
sudo rm -f /etc/systemd/system/docker.service.d/http-proxy.conf
rm -f ~/.docker/config.json

# Puis reconfigurer
./configure-proxy.sh
```

---

**Dernière mise à jour** : 2025-01-24
**Configuration proxy** : 192.168.0.2:3128 avec authentification
