# Guide de Configuration Proxy - IUT

Guide complet pour configurer correctement le proxy dans l'environnement de TP Kubernetes.

## ⚠️ Règle d'or

```
Proxy Docker daemon : OUI ✅
Proxy variables shell : NON ❌ (pour Kind/Kubernetes)
```

---

## Schéma de configuration

```
┌─────────────────────────────────────────────────────────────┐
│                    Votre Machine                            │
│                                                             │
│  ┌────────────┐  Proxy actif    ┌──────────────┐            │
│  │    APT     │ ────────────>   │ Proxy IUT    │            │
│  │ curl/wget  │                 │ :3128        │            │
│  └────────────┘                 └──────────────┘            │
│                                        │                    │
│  ┌────────────┐                        │                    │
│  │   Docker   │  Proxy actif           │                    |
│  │  daemon    │ ───────────────────────┘                    │
│  └────────────┘                                             │
│       │                                                     │
│       │ Pas de proxy                                        │
│       ▼                                                     │
│  ┌────────────────────────────────────┐                     │
│  │         Cluster Kind               │                     │
│  │  ┌──────┐  ┌──────┐  ┌──────┐      │                     │
│  │  │ CP1  │  │ CP2  │  │Worker│      │ Pas de proxy        │
│  │  └──────┘  └──────┘  └──────┘      │                     │
│  │          Kubernetes                │                     │
│  └────────────────────────────────────┘                     │
└─────────────────────────────────────────────────────────────┘
```

---

## Configuration initiale (une seule fois)

### 1. Configuration du proxy système

**IMPORTANT** : Le proxy IUT nécessite une authentification !
- **Adresse** : `192.168.0.2:3128`
- **Identifiants** : Votre login et mot de passe IUT

**Méthode 1 : Configuration simple (identifiants en clair)**

```bash
# REMPLACER username et password par vos identifiants IUT !
export HTTP_PROXY="http://username:password@192.168.0.2:3128"
export HTTPS_PROXY="http://username:password@192.168.0.2:3128"
export NO_PROXY="localhost,127.0.0.1,.local,.cluster.local,192.168.0.0/16"

# Rendre permanent
cat >> ~/.bashrc <<'EOF'
# Proxy IUT avec authentification
# REMPLACER username:password par vos identifiants
export HTTP_PROXY="http://username:password@192.168.0.2:3128"
export HTTPS_PROXY="http://username:password@192.168.0.2:3128"
export NO_PROXY="localhost,127.0.0.1,.local,.cluster.local,192.168.0.0/16"
EOF

source ~/.bashrc
```

**Méthode 2 : Configuration sécurisée (demande les identifiants)**

```bash
# Demander les identifiants
read -p "Username du compte C3 Proxmox: " PROXY_USER
read -sp "Password du compte C3 Proxmox: " PROXY_PASS
echo

# Configurer le proxy
export HTTP_PROXY="http://${PROXY_USER}:${PROXY_PASS}@192.168.0.2:3128"
export HTTPS_PROXY="http://${PROXY_USER}:${PROXY_PASS}@192.168.0.2:3128"
export NO_PROXY="localhost,127.0.0.1,.local,.cluster.local,192.168.0.0/16"

# Rendre permanent (optionnel)
cat >> ~/.bashrc <<EOF
export HTTP_PROXY="http://${PROXY_USER}:${PROXY_PASS}@192.168.0.2:3128"
export HTTPS_PROXY="http://${PROXY_USER}:${PROXY_PASS}@192.168.0.2:3128"
export NO_PROXY="localhost,127.0.0.1,.local,.cluster.local,192.168.0.0/16"
EOF

source ~/.bashrc
```

### 2. Configuration du proxy APT

**REMPLACER username:password par vos identifiants C3 !**

```bash
# Méthode 1 : Simple (identifiants en clair)
sudo tee /etc/apt/apt.conf.d/95proxies > /dev/null <<'EOF'
Acquire::http::Proxy "http://username:password@192.168.0.2:3128";
Acquire::https::Proxy "http://username:password@192.168.0.2:3128";
EOF

# Méthode 2 : Avec variables
read -p "Username du compte C3 Proxmox: " PROXY_USER
read -sp "Password du compte C3 Proxmox: " PROXY_PASS
echo

sudo tee /etc/apt/apt.conf.d/95proxies > /dev/null <<EOF
Acquire::http::Proxy "http://${PROXY_USER}:${PROXY_PASS}@192.168.0.2:3128";
Acquire::https::Proxy "http://${PROXY_USER}:${PROXY_PASS}@192.168.0.2:3128";
EOF

# Tester
sudo apt update
```

### 3. Configuration du proxy Docker daemon

**CRUCIAL : Docker daemon a BESOIN du proxy pour télécharger les images !**

**REMPLACER username:password par vos identifiants IUT !**

```bash
# Créer le répertoire
sudo mkdir -p /etc/systemd/system/docker.service.d

# Méthode 1 : Simple (identifiants en clair)
sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf > /dev/null <<'EOF'
[Service]
Environment="HTTP_PROXY=http://username:password@192.168.0.2:3128"
Environment="HTTPS_PROXY=http://username:password@192.168.0.2:3128"
Environment="NO_PROXY=localhost,127.0.0.1,.local,.cluster.local,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
EOF

# Méthode 2 : Avec variables
read -p "Username du compte C3 Proxmox: " PROXY_USER
read -sp "Password du compte C3 Proxmox: " PROXY_PASS
echo

sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf > /dev/null <<EOF
[Service]
Environment="HTTP_PROXY=http://${PROXY_USER}:${PROXY_PASS}@192.168.0.2:3128"
Environment="HTTPS_PROXY=http://${PROXY_USER}:${PROXY_PASS}@192.168.0.2:3128"
Environment="NO_PROXY=localhost,127.0.0.1,.local,.cluster.local,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
EOF

# Recharger systemd
sudo systemctl daemon-reload

# Redémarrer Docker
sudo systemctl restart docker

# Vérifier (devrait afficher le proxy avec 192.168.0.2:3128)
sudo systemctl show --property=Environment docker
```

**Sécurité** : Le mot de passe est en clair dans `/etc/systemd/system/docker.service.d/http-proxy.conf`, mais ce fichier n'est accessible qu'en root.

### 4. Création des alias utiles

```bash
# Ajouter les alias dans ~/.bashrc
cat >> ~/.bashrc <<'EOF'

# Alias pour gérer le proxy IUT
# MÉTHODE 1 : Identifiants en clair (REMPLACER username:password)
alias proxy-on='export HTTP_PROXY="http://username:password@192.168.0.2:3128"; export HTTPS_PROXY="http://username:password@192.168.0.2:3128"; export NO_PROXY="localhost,127.0.0.1,.local,.cluster.local,192.168.0.0/16"'
alias proxy-off='unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy NO_PROXY no_proxy'
alias proxy-status='echo "=== Variables shell ==="; env | grep -i proxy; echo "=== Docker daemon ==="; sudo systemctl show --property=Environment docker | grep PROXY'
alias proxy-check='echo "Test 1: Variables shell (devrait être vide pour K8s)"; env | grep -i proxy; echo ""; echo "Test 2: Docker daemon (devrait afficher le proxy)"; sudo systemctl show --property=Environment docker | grep PROXY'
EOF

# MÉTHODE 2 : Fonctions interactives (plus sécurisé)
cat >> ~/.bashrc <<'EOF'

# Fonctions proxy avec authentification
proxy-on() {
    if [ -z "$PROXY_USER" ] || [ -z "$PROXY_PASS" ]; then
        read -p "Username du compte C3 Proxmox: " PROXY_USER
        read -sp "Password du compte C3 Proxmox: " PROXY_PASS
        echo
    fi
    export HTTP_PROXY="http://${PROXY_USER}:${PROXY_PASS}@192.168.0.2:3128"
    export HTTPS_PROXY="http://${PROXY_USER}:${PROXY_PASS}@192.168.0.2:3128"
    export NO_PROXY="localhost,127.0.0.1,.local,.cluster.local,192.168.0.0/16"
}

proxy-off() {
    unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy NO_PROXY no_proxy
}

proxy-status() {
    echo "=== Variables shell ==="
    env | grep -i proxy
    echo "=== Docker daemon ==="
    sudo systemctl show --property=Environment docker | grep PROXY
}

proxy-check() {
    echo "Test 1: Variables shell (devrait être vide pour K8s)"
    env | grep -i proxy
    echo ""
    echo "Test 2: Docker daemon (devrait afficher le proxy avec 192.168.0.2:3128)"
    sudo systemctl show --property=Environment docker | grep PROXY
}
EOF

# Recharger
source ~/.bashrc
```

---

## Utilisation quotidienne

### Workflow standard pour les TPs Kubernetes

```bash
# 1. Au démarrage de votre session
# Vérifier la configuration
proxy-check

# 2. Désactiver le proxy shell pour Kind/Kubernetes
proxy-off

# 3. Vérifier que c'est bien désactivé
proxy-status
# Section "Variables shell" devrait être vide
# Section "Docker daemon" devrait afficher le proxy

# 4. Travailler normalement avec kubectl/kind
kubectl get nodes
kind get clusters

# 5. Si vous devez télécharger quelque chose avec curl/wget
proxy-on
curl https://example.com
proxy-off  # Remettre off immédiatement après

# 6. Avant de quitter
# Rien à faire, la configuration Docker reste active
```

---

## Tests de validation

### Test complet de la configuration

```bash
#!/bin/bash
echo "======================================"
echo "Test de configuration Proxy pour K8s"
echo "======================================"
echo ""

# Test 1 : Variables shell
echo "Test 1: Variables shell (DOIVENT être vides)"
PROXY_VARS=$(env | grep -i proxy)
if [ -z "$PROXY_VARS" ]; then
    echo "✅ OK - Aucune variable proxy active"
else
    echo "❌ ERREUR - Variables proxy détectées:"
    echo "$PROXY_VARS"
    echo "Solution: Exécuter 'proxy-off'"
fi
echo ""

# Test 2 : Docker daemon
echo "Test 2: Proxy Docker daemon (DOIT être configuré)"
DOCKER_PROXY=$(sudo systemctl show --property=Environment docker | grep PROXY)
if [ -z "$DOCKER_PROXY" ]; then
    echo "❌ ERREUR - Proxy Docker non configuré"
    echo "Solution: Voir section 'Configuration du proxy Docker daemon'"
else
    echo "✅ OK - Proxy Docker configuré"
    echo "$DOCKER_PROXY"
fi
echo ""

# Test 3 : Docker pull
echo "Test 3: Test de pull Docker"
if docker pull hello-world:latest > /dev/null 2>&1; then
    echo "✅ OK - Docker peut télécharger des images"
else
    echo "❌ ERREUR - Docker ne peut pas télécharger d'images"
    echo "Solution: Vérifier la configuration du proxy Docker"
fi
echo ""

# Test 4 : kubectl
echo "Test 4: Test kubectl"
if kubectl get nodes > /dev/null 2>&1; then
    echo "✅ OK - kubectl fonctionne"
else
    echo "⚠️  WARNING - kubectl ne peut pas se connecter"
    echo "Note: Normal si le cluster n'est pas démarré"
fi
echo ""

echo "======================================"
echo "Résumé"
echo "======================================"
echo "Pour corriger les erreurs:"
echo "1. Variables proxy : proxy-off"
echo "2. Proxy Docker : voir section 'Configuration du proxy Docker daemon'"
echo "======================================"
```

Sauvegarder ce script dans `~/test-proxy.sh` et exécuter :

```bash
# Rendre exécutable
chmod +x ~/test-proxy.sh

# Exécuter
~/test-proxy.sh
```

---

## Dépannage

### Problème 1 : "ImagePullBackOff" sur les pods

**Symptôme** :
```bash
kubectl get pods
NAME                    READY   STATUS             RESTARTS   AGE
nginx-5d5dd5dd-abc123   0/1     ImagePullBackOff   0          2m
```

**Diagnostic** :
```bash
kubectl describe pod nginx-5d5dd5dd-abc123
# Chercher "Failed to pull image"
```

**Solution** :
```bash
# Vérifier le proxy Docker
sudo systemctl show --property=Environment docker | grep PROXY

# Si pas de proxy affiché, le configurer
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf > /dev/null <<'EOF'
[Service]
Environment="HTTP_PROXY=http://proxy.iut.univ:3128"
Environment="HTTPS_PROXY=http://proxy.iut.univ:3128"
Environment="NO_PROXY=localhost,127.0.0.1,.local,.cluster.local"
EOF

sudo systemctl daemon-reload
sudo systemctl restart docker

# Redémarrer le cluster Kind
kind delete cluster --name tp-cluster
kind create cluster --name tp-cluster --config kind-cluster-config.yaml
```

---

### Problème 2 : Kind ne démarre pas

**Symptôme** :
```bash
kind create cluster --name tp-cluster
ERROR: failed to create cluster: ...proxy...
```

**Diagnostic** :
```bash
# Vérifier les variables proxy
env | grep -i proxy
```

**Solution** :
```bash
# Désactiver TOUTES les variables proxy
unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy NO_PROXY no_proxy
export http_proxy=""
export https_proxy=""

# Vérifier
env | grep -i proxy
# Ne doit RIEN afficher

# Recréer le cluster
kind delete cluster --name tp-cluster
kind create cluster --name tp-cluster --config kind-cluster-config.yaml
```

---

### Problème 3 : kubectl est lent ou timeout

**Symptôme** :
```bash
kubectl get nodes
# Très lent ou timeout
```

**Diagnostic** :
```bash
# Vérifier les variables proxy
env | grep -i proxy
```

**Solution** :
```bash
# Désactiver le proxy
proxy-off

# Vérifier
kubectl get nodes
```

---

### Problème 4 : Apt ne peut pas télécharger

**Symptôme** :
```bash
sudo apt update
# Erreurs de connexion
```

**Solution** :
```bash
# Vérifier le fichier de configuration APT
cat /etc/apt/apt.conf.d/95proxies

# Si vide ou inexistant, créer
sudo tee /etc/apt/apt.conf.d/95proxies > /dev/null <<'EOF'
Acquire::http::Proxy "http://proxy.iut.univ:3128";
Acquire::https::Proxy "http://proxy.iut.univ:3128";
EOF

# Réessayer
sudo apt update
```

---

## Tableau récapitulatif

| Composant | Proxy nécessaire ? | Configuration | Vérification |
|-----------|-------------------|---------------|--------------|
| **APT** | ✅ OUI | `/etc/apt/apt.conf.d/95proxies` | `sudo apt update` |
| **curl/wget** | ✅ OUI (optionnel) | Variables d'environnement | `proxy-on; curl https://google.com` |
| **Docker daemon** | ✅ OUI | `/etc/systemd/system/docker.service.d/http-proxy.conf` | `sudo systemctl show --property=Environment docker` |
| **Docker CLI** | ❌ NON | Pas de config | - |
| **Kind** | ❌ NON | `proxy-off` | `env \| grep -i proxy` (vide) |
| **kubectl** | ❌ NON | `proxy-off` | `env \| grep -i proxy` (vide) |
| **Pods Kubernetes** | ❌ NON | Pas de config | - |

---

## Commandes de référence rapide

```bash
# Activer le proxy shell (téléchargements)
proxy-on

# Désactiver le proxy shell (Kubernetes)
proxy-off

# Vérifier l'état complet
proxy-check

# Vérifier uniquement les variables shell
env | grep -i proxy

# Vérifier uniquement le proxy Docker
sudo systemctl show --property=Environment docker

# Test complet
~/test-proxy.sh

# Redémarrer Docker (après changement de config)
sudo systemctl daemon-reload
sudo systemctl restart docker
```

---

## Configuration pour autres outils (optionnel)

### Git (si besoin)

```bash
git config --global http.proxy http://proxy.iut.univ:3128
git config --global https.proxy http://proxy.iut.univ:3128

# Désactiver
git config --global --unset http.proxy
git config --global --unset https.proxy
```

### npm (si utilisé)

```bash
npm config set proxy http://proxy.iut.univ:3128
npm config set https-proxy http://proxy.iut.univ:3128

# Désactiver
npm config delete proxy
npm config delete https-proxy
```

### pip (Python, si utilisé)

```bash
# Créer/éditer ~/.pip/pip.conf
mkdir -p ~/.pip
cat > ~/.pip/pip.conf <<EOF
[global]
proxy = http://proxy.iut.univ:3128
EOF
```

---

## FAQ

### Q : Pourquoi Kind ne fonctionne pas avec le proxy ?

**R :** Kind crée des conteneurs Docker qui doivent communiquer entre eux sur le réseau local. Les variables proxy interfèrent avec cette communication locale. Le daemon Docker a besoin du proxy pour télécharger les images, mais les commandes Kind/kubectl ne doivent PAS avoir de proxy.

### Q : Je dois activer/désactiver le proxy à chaque fois ?

**R :** Non. Configuration à faire **une seule fois** :
- Proxy Docker daemon : Configuré dans systemd, **permanent**
- Variables shell : Désactivées avec `proxy-off`, **à faire au début de chaque session** si elles sont dans votre `.bashrc`

### Q : Comment savoir si ma configuration est correcte ?

**R :** Exécutez :
```bash
proxy-check
```
Vous devriez voir :
- Variables shell : vides
- Docker daemon : avec proxy

### Q : Puis-je utiliser un proxy différent ?

**R :** Oui, remplacez `http://proxy.iut.univ:3128` par l'adresse de votre proxy dans tous les fichiers de configuration.

### Q : Que mettre dans NO_PROXY ?

**R :** Les réseaux qui ne doivent PAS passer par le proxy :
- `localhost, 127.0.0.1` : machine locale
- `.local, .cluster.local` : domaines locaux et Kubernetes
- `10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16` : réseaux privés

---

## Aide-mémoire pour le compte-rendu

Si vous devez documenter les problèmes proxy dans votre compte-rendu :

### Template de documentation

```markdown
## Problèmes rencontrés : Configuration Proxy

### Symptôme
[Description du problème observé]
Exemple : Les pods restent en état "ImagePullBackOff"

### Diagnostic
[Comment j'ai identifié la cause]
Exemple :
- Exécuté `kubectl describe pod nginx-xxx`
- Vu "Failed to pull image"
- Vérifié avec `sudo systemctl show --property=Environment docker`
- Constaté que le proxy Docker n'était pas configuré

### Solution appliquée
[Étapes de résolution]
Exemple :
1. Configuration du proxy Docker dans systemd
2. Redémarrage du daemon Docker
3. Recréation du cluster Kind
4. Redéploiement de l'application

### Vérification
[Comment j'ai vérifié que c'était résolu]
Exemple :
- `docker pull nginx:latest` fonctionne
- `kubectl get pods` montre les pods en "Running"
- Application accessible via navigateur
```

---

## Ressources

- [Guide TP01](INSTALL_TP1_RAPIDE.md) - Installation complète avec proxy
- [Guide TP02](INSTALL_TP2_RAPIDE.md) - Déploiement d'applications
- [Documentation Docker - Configure proxy](https://docs.docker.com/config/daemon/systemd/#httphttps-proxy)
- [Documentation Kind](https://kind.sigs.k8s.io/)

---

**Dernière mise à jour** : 2025-01-24
**Auteur** : Guide TP R5.09 - IUT Ifs
