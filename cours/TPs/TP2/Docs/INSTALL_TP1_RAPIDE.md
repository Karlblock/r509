# Installation Rapide - TP01 : Création d'un Cluster Kind

Guide d'installation rapide pour préparer l'environnement du TP01 et être prêt pour le TP02.

## Prérequis

- Ubuntu 20.04 LTS ou supérieur
- Minimum 4 Go de RAM (recommandé : 8 Go)
- 4 CPUs (2 cœurs minimum au TP01, ajoutez 2 cœurs pour le TP02)
- Accès sudo/root
- Connexion Internet
- Accès au proxy IUT configuré

## 1. Configuration du Proxy IUT (IMPORTANT)

### Détection du proxy actuel

```bash
# Vérifier si un proxy est configuré
env | grep -i proxy
```

### Configuration du proxy système

Si vous êtes à l'IUT, configurez le proxy pour APT et le système :

**IMPORTANT** : Remplacez `username` et `password` par vos identifiants IUT !

```bash
# Configuration du proxy IUT avec authentification
# REMPLACER username et password par vos identifiants !
export HTTP_PROXY="http://username:password@192.168.0.2:3128"
export HTTPS_PROXY="http://username:password@192.168.0.2:3128"
export NO_PROXY="localhost,127.0.0.1,.local,.cluster.local,192.168.0.0/16"

# Rendre permanent (ajouter dans ~/.bashrc)
# ATTENTION : Vos identifiants seront en clair dans ce fichier !
cat >> ~/.bashrc <<'EOF'
# Proxy IUT avec authentification
# REMPLACER username et password par vos identifiants
export HTTP_PROXY="http://username:password@192.168.0.2:3128"
export HTTPS_PROXY="http://username:password@192.168.0.2:3128"
export NO_PROXY="localhost,127.0.0.1,.local,.cluster.local,192.168.0.0/16"
EOF

# Recharger
source ~/.bashrc
```

**Alternative plus sécurisée** (variables séparées) :

```bash
# Définir les identifiants dans des variables séparées
read -p "Username du compte C3 Proxmox: " PROXY_USER
read -sp "Password du compte C3 Proxmox: " PROXY_PASS
echo

# Configurer le proxy
export HTTP_PROXY="http://${PROXY_USER}:${PROXY_PASS}@192.168.0.2:3128"
export HTTPS_PROXY="http://${PROXY_USER}:${PROXY_PASS}@192.168.0.2:3128"
export NO_PROXY="localhost,127.0.0.1,.local,.cluster.local,192.168.0.0/16"

# Pour rendre permanent (optionnel, mais mot de passe en clair)
cat >> ~/.bashrc <<EOF
# Proxy IUT
export HTTP_PROXY="http://${PROXY_USER}:${PROXY_PASS}@192.168.0.2:3128"
export HTTPS_PROXY="http://${PROXY_USER}:${PROXY_PASS}@192.168.0.2:3128"
export NO_PROXY="localhost,127.0.0.1,.local,.cluster.local,192.168.0.0/16"
EOF
```

### Configuration du proxy pour APT

**ATTENTION** : Remplacez `username` et `password` par vos identifiants IUT !

```bash
# Méthode 1 : Avec identifiants en clair (simple mais moins sécurisé)
sudo tee /etc/apt/apt.conf.d/95proxies > /dev/null <<'EOF'
Acquire::http::Proxy "http://username:password@192.168.0.2:3128";
Acquire::https::Proxy "http://username:password@192.168.0.2:3128";
EOF

# Méthode 2 : Avec variables (demande les identifiants)
read -p "Username du compte C3 Proxmox: " PROXY_USER
read -sp "Password du compte C3 Proxmox: " PROXY_PASS
echo

sudo tee /etc/apt/apt.conf.d/95proxies > /dev/null <<EOF
Acquire::http::Proxy "http://${PROXY_USER}:${PROXY_PASS}@192.168.0.2:3128";
Acquire::https::Proxy "http://${PROXY_USER}:${PROXY_PASS}@192.168.0.2:3128";
EOF
```

**Sécurité** : Le mot de passe sera en clair dans le fichier `/etc/apt/apt.conf.d/95proxies`.

## 2. Mise à jour du système

```bash
sudo apt update && sudo apt upgrade -y
```

## 3. Installation de Docker avec configuration proxy

```bash
# Installation des dépendances
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Ajout de la clé GPG Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Ajout du dépôt Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Installation de Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Ajouter votre utilisateur au groupe docker
sudo usermod -aG docker $USER
newgrp docker

# Vérification
docker --version
```

**IMPORTANT** : Déconnectez-vous et reconnectez-vous pour que les permissions du groupe docker soient appliquées.

### Configuration du proxy pour Docker

**ATTENTION** : Cette étape est CRUCIALE si vous êtes derrière le proxy de l'IUT !

**Remplacez `username` et `password` par vos identifiants IUT !**

```bash
# Créer le répertoire de configuration Docker systemd
sudo mkdir -p /etc/systemd/system/docker.service.d

# Méthode 1 : Avec identifiants en clair (simple)
sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf > /dev/null <<'EOF'
[Service]
Environment="HTTP_PROXY=http://username:password@192.168.0.2:3128"
Environment="HTTPS_PROXY=http://username:password@192.168.0.2:3128"
Environment="NO_PROXY=localhost,127.0.0.1,.local,.cluster.local,192.168.0.0/16"
EOF

# Méthode 2 : Avec variables (demande les identifiants)
read -p "Username du compte C3 Proxmox: " PROXY_USER
read -sp "Password du compte C3 Proxmox: " PROXY_PASS
echo

sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf > /dev/null <<EOF
[Service]
Environment="HTTP_PROXY=http://${PROXY_USER}:${PROXY_PASS}@192.168.0.2:3128"
Environment="HTTPS_PROXY=http://${PROXY_USER}:${PROXY_PASS}@192.168.0.2:3128"
Environment="NO_PROXY=localhost,127.0.0.1,.local,.cluster.local,192.168.0.0/16"
EOF

# Recharger la configuration systemd
sudo systemctl daemon-reload

# Redémarrer Docker
sudo systemctl restart docker

# Vérifier que Docker a bien pris en compte le proxy
sudo systemctl show --property=Environment docker
```

**Sécurité** : Le mot de passe sera en clair dans `/etc/systemd/system/docker.service.d/http-proxy.conf`.
Ce fichier n'est accessible qu'en root, ce qui est acceptable pour cet usage.

### Configuration du proxy pour les conteneurs Docker (optionnel)

Si vos conteneurs ont besoin d'accéder à Internet :

**Remplacez `username` et `password` par vos identifiants IUT !**

```bash
# Créer/éditer le fichier de configuration Docker
mkdir -p ~/.docker

# Méthode 1 : Avec identifiants en clair
cat > ~/.docker/config.json <<'EOF'
{
  "proxies": {
    "default": {
      "httpProxy": "http://username:password@192.168.0.2:3128",
      "httpsProxy": "http://username:password@192.168.0.2:3128",
      "noProxy": "localhost,127.0.0.1,.local,.cluster.local,192.168.0.0/16"
    }
  }
}
EOF

# Méthode 2 : Avec variables
read -p "Username du compte C3 Proxmox: " PROXY_USER
read -sp "Password du compte C3 Proxmox: " PROXY_PASS
echo

cat > ~/.docker/config.json <<EOF
{
  "proxies": {
    "default": {
      "httpProxy": "http://${PROXY_USER}:${PROXY_PASS}@192.168.0.2:3128",
      "httpsProxy": "http://${PROXY_USER}:${PROXY_PASS}@192.168.0.2:3128",
      "noProxy": "localhost,127.0.0.1,.local,.cluster.local,192.168.0.0/16"
    }
  }
}
EOF
```

### Test de Docker avec le proxy

```bash
# Tester le pull d'une image
docker pull hello-world

# Exécuter l'image de test
docker run hello-world

# Si ça fonctionne, votre proxy est bien configuré !
```

## 4. Installation de kubectl

```bash
# Téléchargement de la dernière version
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Installation
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Nettoyage
rm kubectl

# Vérification
kubectl version --client
```

## 5. Installation de Kind

Kind (Kubernetes in Docker) permet de créer des clusters Kubernetes locaux.

```bash
# Téléchargement de Kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64

# Installation
sudo install -o root -g root -m 0755 kind /usr/local/bin/kind

# Nettoyage
rm ./kind

# Vérification
kind version
```

## 6. Désactivation du proxy pour Kind (CRITIQUE)

**TRÈS IMPORTANT** : Kind et Kubernetes ne fonctionnent PAS bien avec les proxies !

```bash
# Sauvegarder les variables de proxy actuelles
echo "export HTTP_PROXY_BACKUP=$HTTP_PROXY" >> ~/.proxy_backup
echo "export HTTPS_PROXY_BACKUP=$HTTPS_PROXY" >> ~/.proxy_backup

# Désactiver les variables de proxy pour la session courante
unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy NO_PROXY no_proxy

# Vérifier qu'elles sont bien désactivées
env | grep -i proxy
# Cette commande ne devrait rien retourner

# Créer un alias pour faciliter la gestion du proxy
# ATTENTION : Remplacer username:password par vos identifiants !
cat >> ~/.bashrc <<'EOF'

# Alias pour gérer le proxy IUT
# REMPLACER username:password par vos identifiants
alias proxy-on='export HTTP_PROXY="http://username:password@192.168.0.2:3128"; export HTTPS_PROXY="http://username:password@192.168.0.2:3128"; export NO_PROXY="localhost,127.0.0.1,.local,.cluster.local,192.168.0.0/16"'
alias proxy-off='unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy NO_PROXY no_proxy'
alias proxy-status='env | grep -i proxy'
EOF

source ~/.bashrc

# OU avec variables (plus sécurisé, mais à saisir à chaque session)
# Ajouter ces fonctions dans ~/.bashrc
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
    env | grep -i proxy
}
EOF

source ~/.bashrc
```

**Workflow recommandé** :
1. `proxy-on` : Activer le proxy pour télécharger des packages
2. `proxy-off` : Désactiver le proxy avant de travailler avec Kind/Kubernetes
3. `proxy-status` : Vérifier l'état du proxy

## 7. Création du cluster Kind pour TP01/TP02

Créez un fichier de configuration pour Kind :

```bash
cat > kind-cluster-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    kubeadmConfigPatches:
    - |
      kind: InitConfiguration
      nodeRegistration:
        kubeletExtraArgs:
          node-labels: "ingress-ready=true"
    extraPortMappings:
    - containerPort: 80
      hostPort: 80
      protocol: TCP
    - containerPort: 443
      hostPort: 443
      protocol: TCP
  - role: control-plane
  - role: worker
EOF
```

### Explications de la configuration

- **2 control-plane nodes** : haute disponibilité du control plane
- **1 worker node** : nœud pour exécuter les applications
- **Port forwarding 80:80 et 443:443** : permet d'accéder aux applications depuis l'extérieur
- **Label "ingress-ready=true"** : identifie le nœud avec les ports exposés pour l'Ingress Controller

### Création du cluster

```bash
# IMPORTANT : Vérifier que le proxy est bien désactivé
proxy-status
# Ne devrait rien afficher !

# Si un proxy apparaît, le désactiver
proxy-off

# Créer le cluster avec la configuration
kind create cluster --name tp-cluster --config kind-cluster-config.yaml

# Vérifier que le cluster est créé
kind get clusters

# Vérifier les nœuds
kubectl get nodes
```

**Si vous obtenez une erreur liée au proxy** :
```bash
# Supprimer le cluster défectueux
kind delete cluster --name tp-cluster

# Vérifier qu'aucune variable de proxy n'est définie
env | grep -i proxy

# Supprimer toutes les variables de proxy
unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy NO_PROXY no_proxy

# Recréer le cluster
kind create cluster --name tp-cluster --config kind-cluster-config.yaml
```

Vous devriez voir :
```
NAME                       STATUS   ROLES           AGE   VERSION
tp-cluster-control-plane   Ready    control-plane   1m    v1.27.x
tp-cluster-control-plane2  Ready    control-plane   1m    v1.27.x
tp-cluster-worker          Ready    <none>          1m    v1.27.x
```

## 8. Installation de l'Ingress Controller NGINX

```bash
# IMPORTANT : Vérifier que le proxy est désactivé
proxy-off

# Installer l'Ingress Controller NGINX pour Kind
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Attendre que l'Ingress Controller soit prêt
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

# Vérifier que l'Ingress Controller est déployé
kubectl get pods -n ingress-nginx
```

**Si l'Ingress Controller ne démarre pas** :
```bash
# Vérifier les logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Vérifier les events
kubectl get events -n ingress-nginx --sort-by='.lastTimestamp'

# Si problème de pull d'image, vérifier le proxy Docker
sudo systemctl show --property=Environment docker
```

## 9. Test avec un déploiement Nginx (Fin de TP01)

```bash
# Créer un namespace pour les tests
kubectl create namespace tp-test

# Déployer nginx
kubectl create deployment nginx --image=nginx:latest -n tp-test

# Exposer nginx avec un Service
kubectl expose deployment nginx --port=80 --type=ClusterIP -n tp-test

# Créer un Ingress pour accéder à nginx
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
  namespace: tp-test
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  - host: nginx.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx
            port:
              number: 80
EOF

# Vérifier le déploiement
kubectl get all -n tp-test
kubectl get ingress -n tp-test
```

### Accéder à l'application

Ajoutez une entrée dans `/etc/hosts` :

```bash
# Ajouter nginx.local au fichier hosts
echo "127.0.0.1 nginx.local" | sudo tee -a /etc/hosts
```

Testez dans votre navigateur : [http://nginx.local](http://nginx.local)

Ou avec curl :
```bash
curl http://nginx.local
```

Vous devriez voir la page d'accueil de Nginx.

## 10. Configuration des namespaces (Bonne pratique)

```bash
# Créer un namespace pour le TP02
kubectl create namespace tp-kubernetes

# Configurer kubectl pour utiliser ce namespace par défaut
kubectl config set-context --current --namespace=tp-kubernetes

# Vérifier le namespace actuel
kubectl config view --minify | grep namespace:
```

## 11. Installation d'outils optionnels mais recommandés

### k9s (Interface TUI pour Kubernetes)

```bash
# Téléchargement
K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep tag_name | cut -d '"' -f 4)
wget https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz

# Installation
tar -xzf k9s_Linux_amd64.tar.gz
sudo mv k9s /usr/local/bin/
rm k9s_Linux_amd64.tar.gz README.md LICENSE

# Lancer k9s
k9s
```

Pour quitter k9s : `:quit` puis Entrée ou `Ctrl+C`

### Auto-complétion kubectl (très utile !)

```bash
# Pour bash
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc

# Recharger
source ~/.bashrc
```

## 12. Vérification finale

```bash
# Vérifier tous les composants
docker --version
kubectl version --client
kind version

# Vérifier le cluster
kubectl cluster-info
kubectl get nodes
kubectl get namespaces

# Vérifier l'Ingress Controller
kubectl get pods -n ingress-nginx

# Vérifier le namespace de travail
kubectl config view --minify | grep namespace:

# Lister tous les pods
kubectl get pods -A
```

## Commandes utiles Kind

```bash
# Lister les clusters
kind get clusters

# Voir les nœuds du cluster
kind get nodes --name tp-cluster

# Obtenir le kubeconfig
kind get kubeconfig --name tp-cluster

# Supprimer le cluster (si nécessaire)
kind delete cluster --name tp-cluster

# Charger une image Docker dans le cluster Kind
kind load docker-image mon-image:tag --name tp-cluster
```

## Dépannage

### Problème : Les ports 80/443 sont déjà utilisés

```bash
# Vérifier quels processus utilisent les ports
sudo lsof -i :80
sudo lsof -i :443

# Arrêter Apache2 ou Nginx s'ils sont installés
sudo systemctl stop apache2
sudo systemctl stop nginx
```

### Problème : Permission denied avec Docker

```bash
# Vérifier que vous êtes dans le groupe docker
groups | grep docker

# Si non, ajouter et redémarrer la session
sudo usermod -aG docker $USER
# Puis se déconnecter/reconnecter
```

### Problème : Kind ne démarre pas à cause du proxy

```bash
# 1. Vérifier les variables de proxy
env | grep -i proxy

# 2. Désactiver TOUTES les variables de proxy
unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy NO_PROXY no_proxy
export http_proxy=""
export https_proxy=""

# 3. Vérifier qu'elles sont bien supprimées
env | grep -i proxy
# Ne devrait RIEN afficher

# 4. Supprimer l'ancien cluster
kind delete cluster --name tp-cluster

# 5. Recréer le cluster
kind create cluster --name tp-cluster --config kind-cluster-config.yaml

# 6. Vérifier dans le conteneur Kind qu'il n'y a pas de proxy
docker exec tp-cluster-control-plane env | grep -i proxy
# Ne devrait RIEN afficher
```

### Problème : Docker ne peut pas télécharger les images (proxy manquant)

```bash
# Vérifier la configuration proxy de Docker
sudo systemctl show --property=Environment docker

# Si le proxy n'est pas configuré, le configurer
# REMPLACER username:password par vos identifiants !
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf > /dev/null <<'EOF'
[Service]
Environment="HTTP_PROXY=http://username:password@192.168.0.2:3128"
Environment="HTTPS_PROXY=http://username:password@192.168.0.2:3128"
Environment="NO_PROXY=localhost,127.0.0.1,.local,.cluster.local,192.168.0.0/16"
EOF

# Recharger et redémarrer Docker
sudo systemctl daemon-reload
sudo systemctl restart docker

# Tester
docker pull nginx:latest
```

### Problème : Les pods ne peuvent pas télécharger les images

```bash
# Vérifier les events des pods
kubectl get events --sort-by='.lastTimestamp' -A

# Si erreur "ImagePullBackOff", vérifier le proxy Docker
sudo systemctl show --property=Environment docker

# Vérifier dans un conteneur Kind
docker exec tp-cluster-control-plane crictl images

# Précharger manuellement une image dans Kind
docker pull nginx:latest
kind load docker-image nginx:latest --name tp-cluster
```

### Problème : Ingress Controller ne démarre pas

```bash
# Vérifier les logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Réinstaller l'Ingress Controller
kubectl delete namespace ingress-nginx
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
```

## Résumé : Gestion du Proxy (À RETENIR)

### Configuration optimale pour l'environnement IUT

**Remplacez `username:password` par vos identifiants réels !**

```bash
# 1. Proxy pour le système et APT (toujours actif)
export HTTP_PROXY="http://username:password@192.168.0.2:3128"
export HTTPS_PROXY="http://username:password@192.168.0.2:3128"

# 2. Proxy pour Docker daemon (configuration systemd)
sudo systemctl show --property=Environment docker
# Devrait afficher : HTTP_PROXY et HTTPS_PROXY avec 192.168.0.2:3128

# 3. Proxy DÉSACTIVÉ pour Kind et kubectl
proxy-off
env | grep -i proxy  # Ne devrait RIEN afficher
```
### Commandes rapides

```bash
# Activer le proxy (pour téléchargements)
proxy-on

# Désactiver le proxy (pour Kind/Kubernetes)
proxy-off

# Vérifier l'état du proxy
proxy-status

# Vérifier le proxy Docker
sudo systemctl show --property=Environment docker
```

## Résumé des prérequis pour TP02

Vous êtes prêt pour le TP02 si :

- ✅ **Proxy système configuré** pour APT et téléchargements
- ✅ **Proxy Docker configuré** dans systemd
- ✅ **Proxy désactivé** pour Kind/Kubernetes (`proxy-off`)
- ✅ Cluster Kind avec 2 control-plane + 1 worker
- ✅ Port forwarding 80:80 et 443:443 configuré
- ✅ Label `ingress-ready=true` sur le nœud avec port forward
- ✅ Ingress Controller NGINX déployé
- ✅ Nginx déployé et accessible via Ingress (fin de TP01)
- ✅ Namespace `tp-kubernetes` créé et configuré par défaut
- ✅ VM avec 4 cœurs (ajoutez 2 cœurs si vous n'en avez que 2)
- ✅ **Alias proxy** configurés (`proxy-on`, `proxy-off`, `proxy-status`)

## Ressources

- Documentation Kind : https://kind.sigs.k8s.io/
- Documentation Ingress NGINX : https://kubernetes.github.io/ingress-nginx/
- Documentation Kubernetes : https://kubernetes.io/docs/

---

**Vous êtes maintenant prêt pour le TP02 !** 

N'oubliez pas de vérifier que tout fonctionne avec `kubectl get all -A` avant de commencer le TP02.
