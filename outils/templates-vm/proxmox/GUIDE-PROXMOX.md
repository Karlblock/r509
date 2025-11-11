# Guide complet - Image Proxmox avec Kubernetes et Proxy

## Vue d'ensemble

Ce guide vous permet de créer une image/template Proxmox préconfigurée avec :
- ✅ Ubuntu 22.04
- ✅ Docker + containerd
- ✅ Minikube
- ✅ kubectl v1.28.0
- ✅ Helm 3
- ✅ k9s (interface TUI)
- ✅ kubectx & kubens
- ✅ **Proxy configuré pour tout (192.168.0.2:3128)**
- ✅ Scripts de démarrage rapide
- ✅ Alias et auto-complétion

---

## Méthode 1 : Création manuelle (RECOMMANDÉE)

### Étape 1 : Créer une VM Ubuntu sur Proxmox

1. **Via l'interface web Proxmox** :
   - Télécharger ISO Ubuntu 22.04 Server
   - Créer une nouvelle VM (ID au choix, ex: 9000)
   - Configuration recommandée :
     - RAM : 4 GB minimum
     - CPU : 2 cores minimum
     - Disque : 32 GB
     - Réseau : vmbr0

2. **Installer Ubuntu normalement**
   - Utilisateur : `ubuntu`
   - Installation minimale
   - Installer OpenSSH server

### Étape 2 : Copier les scripts dans la VM

Depuis votre machine locale :

```bash
# Copier le dossier scripts
scp -r scripts/ ubuntu@<ip-de-la-vm>:/home/ubuntu/

# Se connecter à la VM
ssh ubuntu@<ip-de-la-vm>
```

### Étape 3 : Exécuter le script de construction

Dans la VM :

```bash
cd /home/ubuntu/scripts
sudo bash build-vm-image.sh
```

Ce script va :
1. Configurer le proxy 192.168.0.2:3128 pour tout
2. Installer Docker, Minikube, kubectl, Helm, k9s, etc.
3. Configurer les alias et l'auto-complétion
4. Créer les scripts de démarrage rapide
5. Créer un README avec la documentation

**Durée** : 10-15 minutes

### Étape 4 : Nettoyer et préparer pour le template

```bash
# Nettoyer l'historique
history -c
sudo rm -rf /home/ubuntu/.bash_history
sudo rm -rf /root/.bash_history

# Nettoyer cloud-init (si installé)
sudo cloud-init clean
sudo rm -rf /var/lib/cloud/instances

# Vider le machine-id
sudo truncate -s 0 /etc/machine-id

# Arrêter la VM
sudo shutdown -h now
```

### Étape 5 : Convertir en template

Dans l'interface Proxmox ou via CLI :

```bash
# Sur le serveur Proxmox
qm template 9000
```

### Étape 6 : Cloner le template

```bash
# Via CLI
qm clone 9000 100 --name k8s-node-01 --full

# Ou via l'interface web : Clic droit → Clone
```

---

## Méthode 2 : Script automatique Proxmox

Si vous êtes directement sur le serveur Proxmox :

```bash
# Copier le script
scp create-proxmox-template.sh root@proxmox-server:/root/

# Se connecter au serveur Proxmox
ssh root@proxmox-server

# Exécuter le script
bash create-proxmox-template.sh 9000

# Le script téléchargera l'image cloud Ubuntu et créera le template
```

---

## Utilisation du template

### Créer une nouvelle VM depuis le template

1. **Via l'interface web** :
   - Clic droit sur le template → Clone
   - Mode : Full Clone
   - Donner un nom et un nouvel ID
   - Démarrer la VM

2. **Via CLI** :
```bash
qm clone 9000 101 --name k8s-worker-01 --full
qm set 101 --ipconfig0 ip=dhcp
qm start 101
```

### Premier démarrage

1. **Se connecter à la VM** :
```bash
ssh ubuntu@<ip-de-la-vm>
```

2. **Démarrer Minikube** :
```bash
start-k8s
# ou
minikube start --driver=docker
```

3. **Vérifier** :
```bash
kubectl get nodes
k get pods -A
minikube status
```

---

## Configuration du proxy

Le proxy `192.168.0.2:3128` est configuré pour :

### Systèmes affectés

- ✅ APT (apt-get, apt)
- ✅ Docker (daemon et client)
- ✅ containerd
- ✅ wget
- ✅ curl
- ✅ Git
- ✅ Snap
- ✅ Variables d'environnement système

### Fichiers de configuration

| Composant | Fichier de configuration |
|-----------|--------------------------|
| APT | `/etc/apt/apt.conf.d/95proxy` |
| Environnement | `/etc/profile.d/proxy.sh` |
| Docker | `/etc/systemd/system/docker.service.d/http-proxy.conf` |
| containerd | `/etc/systemd/system/containerd.service.d/http-proxy.conf` |
| wget | `/etc/wgetrc` et `~/.wgetrc` |
| curl | `~/.curlrc` |
| Git | `git config --system` |

### No proxy

Les réseaux suivants **ne passent PAS** par le proxy :
- localhost (127.0.0.1, ::1)
- 10.0.0.0/8
- 172.16.0.0/12
- 192.168.0.0/16

### Modifier le proxy

```bash
# Éditer la configuration
sudo nano /etc/profile.d/proxy.sh

# Modifier PROXY_HOST et PROXY_PORT
export http_proxy="http://NOUVEAU_HOST:NOUVEAU_PORT"

# Appliquer
source /etc/profile.d/proxy.sh
sudo systemctl daemon-reload
sudo systemctl restart docker containerd
```

### Désactiver le proxy

```bash
# Temporairement (session actuelle)
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY

# Définitivement
sudo /usr/local/bin/disable-proxy
sudo reboot
```

---

## Scripts disponibles

### start-k8s

Démarre Minikube avec les bons paramètres :
```bash
start-k8s
```

Équivalent à :
```bash
minikube start --driver=docker --memory=3000mb --cpus=2
```

### stop-k8s

Arrête Minikube proprement :
```bash
stop-k8s
```

### setup-proxy.sh

Reconfigure le proxy (si besoin de changer) :
```bash
sudo /usr/local/bin/setup-proxy.sh
```

### disable-proxy

Désactive complètement le proxy :
```bash
sudo /usr/local/bin/disable-proxy
```

---

## Alias configurés

| Alias | Commande complète |
|-------|-------------------|
| `k` | `kubectl` |
| `mk` | `minikube` |
| `h` | `helm` |

Exemples :
```bash
k get pods
mk status
h list
```

---

## Outils installés

### Docker

```bash
docker --version
docker ps
docker images
```

### Minikube

```bash
minikube version
minikube start
minikube stop
minikube delete
minikube dashboard
minikube addons list
```

### kubectl

```bash
kubectl version --client
kubectl get nodes
kubectl get pods -A
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --type=NodePort --port=80
```

### Helm

```bash
helm version
helm repo add bitnami https://charts.bitnami.com/bitnami
helm search repo nginx
helm install my-nginx bitnami/nginx
```

### k9s

Interface TUI pour Kubernetes :
```bash
k9s
```

Raccourcis dans k9s :
- `:pod` → voir les pods
- `:deploy` → voir les déploiements
- `:svc` → voir les services
- `?` → aide
- `Ctrl+c` → quitter

### kubectx & kubens

```bash
# Changer de contexte
kubectx
kubectx minikube

# Changer de namespace
kubens
kubens kube-system
```

---

## Exemples de déploiements

### Hello World

```bash
kubectl create deployment hello --image=k8s.gcr.io/echoserver:1.4
kubectl expose deployment hello --type=NodePort --port=8080
minikube service hello --url
curl $(minikube service hello --url)
```

### Nginx

```bash
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --type=LoadBalancer --port=80
minikube service nginx
```

### WordPress avec Helm

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install my-wordpress bitnami/wordpress
kubectl get pods -w
kubectl get svc
minikube service my-wordpress
```

---

## Dépannage

### Minikube ne démarre pas

```bash
# Voir les logs
minikube logs

# Réinitialiser
minikube delete
minikube start --driver=docker --v=7
```

### Problème de proxy

```bash
# Vérifier la configuration
echo $http_proxy
curl -I http://google.com

# Tester sans proxy
unset http_proxy https_proxy
curl -I http://google.com

# Reconfigurer
sudo bash /home/ubuntu/scripts/setup-proxy.sh
```

### Docker ne tire pas les images

```bash
# Vérifier la config proxy de Docker
sudo cat /etc/systemd/system/docker.service.d/http-proxy.conf

# Redémarrer Docker
sudo systemctl daemon-reload
sudo systemctl restart docker

# Tester
docker pull hello-world
```

### Pas assez de ressources

```bash
# Vérifier
free -h
df -h

# Ajuster Minikube
minikube delete
minikube start --memory=2000mb --cpus=1
```

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│          VM Proxmox (Ubuntu 22.04)              │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │  Docker                                   │ │
│  │                                           │ │
│  │  ┌─────────────────────────────────────┐ │ │
│  │  │  Conteneur Minikube (kicbase)       │ │ │
│  │  │                                     │ │ │
│  │  │  ┌──────────────────────────────┐  │ │ │
│  │  │  │  Kubernetes                  │  │ │ │
│  │  │  │  - API Server                │  │ │ │
│  │  │  │  - Scheduler                 │  │ │ │
│  │  │  │  - Controller Manager        │  │ │ │
│  │  │  │  - etcd                      │  │ │ │
│  │  │  │  - kubelet                   │  │ │ │
│  │  │  │                              │  │ │ │
│  │  │  │  Pods / Deployments          │  │ │ │
│  │  │  └──────────────────────────────┘  │ │ │
│  │  └─────────────────────────────────────┘ │ │
│  └───────────────────────────────────────────┘ │
│                                                 │
│  Outils : kubectl, helm, k9s, kubectx          │
│  Proxy  : 192.168.0.2:3128 (tout le trafic)    │
└─────────────────────────────────────────────────┘
```

---

## Checklist de vérification

Après le clonage d'une VM depuis le template :

- [ ] VM démarre correctement
- [ ] Connexion SSH fonctionne
- [ ] `docker ps` fonctionne
- [ ] `minikube version` affiche la version
- [ ] `kubectl version --client` fonctionne
- [ ] `start-k8s` démarre Minikube sans erreur
- [ ] `k get nodes` affiche le node minikube
- [ ] `curl -I http://google.com` passe par le proxy
- [ ] Déploiement de test fonctionne

---

## Ressources

- **Documentation** : `/home/ubuntu/README.md`
- **Scripts** : `/home/ubuntu/scripts/`
- **Logs Minikube** : `minikube logs`
- **Logs Docker** : `sudo journalctl -u docker`

---

## Support

Pour obtenir de l'aide :
1. Consultez `/home/ubuntu/README.md` dans la VM
2. Vérifiez les logs : `minikube logs`
3. Vérifiez Docker : `docker info`
4. Vérifiez le proxy : `echo $http_proxy`

---

**Version** : 1.0
**Date** : 2025-10-28
**Compatibilité** : Proxmox VE 7.x+, Ubuntu 22.04
