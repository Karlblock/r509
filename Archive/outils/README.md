# Outils - Scripts d'installation et utilitaires

Ce dossier contient des scripts utilitaires pour installer et configurer les outils nécessaires pour le cours R5.09.

---

## Scripts disponibles

### 1. install-minikube-native.sh

**Installation native de Minikube** sur votre système (Debian/Ubuntu).

#### Utilisation

```bash
./install-minikube-native.sh
```

#### Ce qui est installé

- **Docker CE** (si pas déjà installé)
- **Minikube** (latest version)
- **kubectl** v1.28.0
- **Helm** 3 (latest)
- **k9s** (Terminal UI pour Kubernetes)
- **kubectx & kubens** (changement de contexte/namespace)

#### Après installation

```bash
# Démarrer Minikube
minikube start

# Vérifier
kubectl get nodes
minikube status

# Utiliser
kubectl create deployment nginx --image=nginx
kubectl get pods
```

#### Avantages de l'installation native

✅ **Performances** - Meilleures performances qu'avec Docker ou VM
✅ **RAM** - Utilise moins de RAM (2-3 GB vs 4-6 GB)
✅ **Simplicité** - Commandes directes, pas de couche intermédiaire
✅ **Accès complet** - Accès direct aux fonctionnalités Minikube

#### Inconvénients

❌ **Modifie le système** - Installe des paquets sur votre machine
❌ **Moins isolé** - Partage les ressources avec d'autres applications
❌ **Cleanup** - Plus difficile à supprimer complètement

---

### 2. install-docker-compose-v2.sh

**Mise à jour vers Docker Compose v2** (nécessaire pour certains scripts).

#### Utilisation

```bash
./install-docker-compose-v2.sh
```

#### Pourquoi ?

Docker Compose v1 (ancienne version en Python) a des problèmes de compatibilité avec les versions récentes de Docker. La v2 (réécrite en Go) est plus rapide et compatible.

**Problème courant avec v1** :
```
docker.errors.DockerException: Error while fetching server API version:
Not supported URL scheme http+docker
```

#### Vérification

```bash
# Vérifier la version
docker-compose version

# Doit afficher :
# Docker Compose version v2.x.x
```

---

## Comparaison des méthodes d'installation

| Critère | Native | Docker | VM Template |
|---------|--------|--------|-------------|
| **Facilité d'installation** | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ |
| **Performance** | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ |
| **Isolation** | ⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **RAM requise** | 3 GB | 6 GB | 4 GB |
| **Portabilité** | ❌ | ✅ | ✅ |
| **Production** | ⚠️ | ❌ | ✅ |

---

## Guides d'installation par cas d'usage

### Cas 1 : Vous testez sur votre machine personnelle

**Recommandation** : Installation native

```bash
cd outils
./install-minikube-native.sh
minikube start
```

**Pourquoi ?**
- Plus simple et direct
- Meilleures performances
- Moins gourmand en ressources

---

### Cas 2 : Vous manquez de RAM (<4 GB libre)

**Recommandation** : Installation native avec ressources réduites

```bash
cd outils
./install-minikube-native.sh
minikube start --memory=2000mb --cpus=1
```

**Pourquoi ?**
- Docker-in-Docker nécessite trop de RAM
- Les VMs nécessitent aussi beaucoup de ressources
- L'installation native est la plus légère

---

### Cas 3 : Vous voulez un environnement isolé et reproductible

**Recommandation** : Solution Docker (si vous avez assez de RAM)

```bash
cd docker-minikube
./minikube-helper-v2.sh build
./minikube-helper-v2.sh start
```

**Pourquoi ?**
- Isolation complète
- Facile à supprimer
- Configuration identique pour tous

📖 **Guide** : [../docker-minikube/README.md](../docker-minikube/README.md)

---

### Cas 4 : Vous distribuez aux étudiants

**Recommandation** : Templates VM (OVA ou Proxmox)

```bash
cd templates-vm
# Suivre les guides pour créer les templates
```

**Pourquoi ?**
- Élimine les problèmes d'installation
- Environnement identique pour tous
- Prêt à l'emploi

📖 **Guides** :
- [../templates-vm/ova-virtualbox/GUIDE-VIRTUALBOX-OVA.md](../templates-vm/ova-virtualbox/GUIDE-VIRTUALBOX-OVA.md)
- [../templates-vm/proxmox/GUIDE-PROXMOX.md](../templates-vm/proxmox/GUIDE-PROXMOX.md)

---

## Dépannage

### Problème : Script install-minikube-native.sh échoue

#### Erreur : Permission denied

```bash
# Solution : Ajouter les permissions d'exécution
chmod +x install-minikube-native.sh
./install-minikube-native.sh
```

#### Erreur : Command not found après installation

```bash
# Solution : Recharger le shell ou ouvrir un nouveau terminal
exec $SHELL
# ou
source ~/.bashrc
```

#### Erreur : Docker daemon not running

```bash
# Solution : Démarrer Docker
sudo systemctl start docker
sudo systemctl enable docker

# Vérifier
docker ps
```

---

### Problème : Minikube ne démarre pas après installation

#### Vérifier les prérequis

```bash
# Virtualisation activée ?
egrep -c '(vmx|svm)' /proc/cpuinfo
# Doit être > 0

# Docker fonctionne ?
docker ps

# Ressources disponibles ?
free -h
```

#### Logs Minikube

```bash
minikube logs
minikube logs --follow
```

#### Supprimer et recréer

```bash
minikube delete
minikube start
```

---

### Problème : docker-compose v2 ne fonctionne pas

#### Vérifier l'installation

```bash
docker-compose version

# Si erreur : command not found
# Réinstaller :
./install-docker-compose-v2.sh
```

#### Alternative : Utiliser le plugin Docker

```bash
# Docker Compose v2 peut aussi être un plugin
docker compose version
# (sans tiret)

# Créer un alias si nécessaire
echo 'alias docker-compose="docker compose"' >> ~/.bashrc
source ~/.bashrc
```

---

## Commandes utiles après installation

### Minikube

```bash
# Démarrer
minikube start

# Arrêter
minikube stop

# Supprimer
minikube delete

# Statut
minikube status

# Dashboard
minikube dashboard

# Services
minikube service list
minikube service <service-name>

# SSH dans le node
minikube ssh

# Logs
minikube logs

# Addons
minikube addons list
minikube addons enable ingress
minikube addons enable metrics-server
```

---

### kubectl

```bash
# Info cluster
kubectl cluster-info
kubectl get nodes

# Namespaces
kubectl get namespaces
kubectl create namespace dev

# Pods
kubectl get pods
kubectl get pods -A
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl exec -it <pod-name> -- sh

# Deployments
kubectl get deployments
kubectl create deployment nginx --image=nginx
kubectl scale deployment nginx --replicas=3
kubectl delete deployment nginx

# Services
kubectl get services
kubectl expose deployment nginx --type=NodePort --port=80
kubectl delete service nginx
```

---

### k9s (Terminal UI)

```bash
# Lancer k9s
k9s

# Raccourcis utiles dans k9s :
# 0 : Voir tous les namespaces
# : : Ouvrir la commande
# / : Filtrer
# d : Describe
# l : Logs
# Ctrl+d : Delete
# ? : Aide
```

---

### Helm

```bash
# Ajouter un repo
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Rechercher
helm search repo nginx

# Installer
helm install my-nginx bitnami/nginx

# Lister
helm list

# Mettre à jour
helm upgrade my-nginx bitnami/nginx

# Désinstaller
helm uninstall my-nginx
```

---

## Configuration recommandée

### Alias bash utiles

Ajoutez à votre `~/.bashrc` ou `~/.zshrc` :

```bash
# Kubernetes
alias k='kubectl'
alias kg='kubectl get'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias ka='kubectl apply -f'
alias kdel='kubectl delete'

# Minikube
alias mk='minikube'
alias mks='minikube start'
alias mkst='minikube stop'
alias mkd='minikube delete'
alias mkda='minikube dashboard'

# Helm
alias h='helm'
alias hls='helm list'
alias hin='helm install'
alias hun='helm uninstall'

# Docker
alias d='docker'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias drm='docker rm'
alias drmi='docker rmi'
alias dprune='docker system prune -a'
```

Puis rechargez :
```bash
source ~/.bashrc
```

---

### Completion bash/zsh

#### kubectl

```bash
# Bash
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc

# Zsh
echo 'source <(kubectl completion zsh)' >> ~/.zshrc
echo 'complete -F __start_kubectl k' >> ~/.zshrc
```

#### Minikube

```bash
# Bash
echo 'source <(minikube completion bash)' >> ~/.bashrc

# Zsh
echo 'source <(minikube completion zsh)' >> ~/.zshrc
```

#### Helm

```bash
# Bash
echo 'source <(helm completion bash)' >> ~/.bashrc

# Zsh
echo 'source <(helm completion zsh)' >> ~/.zshrc
```

---

## Désinstallation

### Supprimer Minikube

```bash
# Supprimer le cluster
minikube delete --all --purge

# Supprimer le binaire
sudo rm /usr/local/bin/minikube

# Supprimer les fichiers de configuration
rm -rf ~/.minikube
```

### Supprimer kubectl

```bash
sudo rm /usr/local/bin/kubectl
rm -rf ~/.kube
```

### Supprimer Helm

```bash
sudo rm /usr/local/bin/helm
rm -rf ~/.config/helm
```

### Supprimer k9s

```bash
sudo rm /usr/local/bin/k9s
rm -rf ~/.config/k9s
```

### Supprimer Docker (attention !)

```bash
# Arrêter Docker
sudo systemctl stop docker

# Désinstaller
sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Supprimer les données
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
```

---

## Support

### Documentation

| Sujet | Document |
|-------|----------|
| **Installation native** | Ce README |
| **Solution Docker** | [../docker-minikube/README.md](../docker-minikube/README.md) |
| **Templates VM** | [../templates-vm/README.md](../templates-vm/README.md) |
| **README principal** | [../README.md](../README.md) |

### Ressources externes

- [Documentation Minikube](https://minikube.sigs.k8s.io/docs/)
- [Documentation kubectl](https://kubernetes.io/docs/reference/kubectl/)
- [Documentation Helm](https://helm.sh/docs/)
- [k9s GitHub](https://github.com/derailed/k9s)

---

## Contribution

Pour améliorer ces scripts :

1. **Tester** sur différentes distributions
2. **Vérifier** la compatibilité avec les nouvelles versions
3. **Documenter** les changements
4. **Mettre à jour** ce README

---

## Licence

Matériel pédagogique pour IUT Grand Ouest Normandie.

**Contact** : Maxime Lambert - maxime.lambert@unicaen.fr

---

**Version** : 2.0
**Dernière mise à jour** : Novembre 2024
**Maintenu par** : Enseignants R5.09 - IUT Grand Ouest Normandie
