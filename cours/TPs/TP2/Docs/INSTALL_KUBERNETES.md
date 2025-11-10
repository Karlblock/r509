# Installation des outils Kubernetes sur Ubuntu

installation des outils nécessaires pour déployer et gérer un cluster Kubernetes sur une VM Ubuntu.

## Prérequis

- Ubuntu 20.04 LTS ou supérieur
- Minimum 4 Go de RAM
- 2 CPUs minimum
- Accès sudo/root
- Connexion Internet

## 1. Mise à jour du système

```bash
sudo apt update

```

## 2. Installation de Docker

Docker est le runtime de conteneurs utilisé par Kubernetes.

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

# Vérification
sudo docker --version

# Ajouter votre utilisateur au groupe docker (IMPORTANT pour Minikube)
sudo usermod -aG docker $USER

newgrp docker

# Vérifier que vous êtes dans le groupe docker
groups | grep docker
```

**IMPORTANT :** Après l'ajout au groupe docker, vous DEVEZ soit :
- Vous déconnecter complètement et vous reconnecter à votre session Ubuntu, OU
- Redémarrer votre VM

Sans cela, Minikube ne pourra pas démarrer !

## 3. Installation de kubectl

`kubectl` est l'outil en ligne de commande pour interagir avec Kubernetes.

```bash
# Téléchargement de la dernière version
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Installation
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Vérification
kubectl version --client
```

## 4. Installation de Minikube

Minikube permet de lancer un cluster Kubernetes local pour le développement et l'apprentissage.

```bash
# Téléchargement de Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# Installation
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Vérification
minikube version
```

## 5. Démarrage du cluster Minikube

**AVANT de démarrer Minikube :** Assurez-vous d'être dans le groupe docker !

```bash
# Vérifier que vous êtes dans le groupe docker
groups | grep docker

# Si 'docker' n'apparaît pas, vous devez :
# 1. Ajouter votre utilisateur au groupe
sudo usermod -aG docker $USER

# 2. Puis SE DÉCONNECTER et SE RECONNECTER (ou redémarrer la VM)
# La commande 'newgrp docker' ne suffit PAS toujours pour Minikube !
```

### Démarrage sans proxy 

hors VM PROMOX

```bash
# Supprimer temporairement les variables de proxy pour Minikube
unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy NO_PROXY no_proxy

# Démarrer Minikube sans proxy
minikube start --driver=docker

# Si vous avez déjà un cluster avec proxy, le supprimer d'abord :
# minikube delete
# unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy NO_PROXY no_proxy
# minikube start --driver=docker
```

### Démarrage standard (sans proxy)

```bash
# Démarrer Minikube avec Docker comme driver
minikube start --driver=docker

# Vérifier le statut
minikube status

# Vérifier les nodes
kubectl get nodes
```

## 6. Installation de k9s (optionnel mais recommandé)

k9s est une interface terminal interactive pour gérer Kubernetes.

```bash
# Téléchargement de la dernière version
K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep tag_name | cut -d '"' -f 4)
wget https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz

# Extraction et installation
tar -xzf k9s_Linux_amd64.tar.gz
sudo mv k9s /usr/local/bin/
rm k9s_Linux_amd64.tar.gz README.md LICENSE

# Vérification
k9s version
```

**Note :** k9s ne fonctionnera correctement qu'une fois Minikube démarré (étape 5). Si vous le lancez avant, vous verrez "n/a" partout. Pour quitter k9s, appuyez sur `:quit` puis Entrée, ou simplement `Ctrl+C`.

## 7. Installation de Helm (optionnel)

Helm est un gestionnaire de packages pour Kubernetes.

```bash
# Installation via script
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Vérification
helm version
```

## 8. Configuration de l'auto-complétion (recommandé)

### Pour bash

```bash
# kubectl
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc

# minikube
echo 'source <(minikube completion bash)' >> ~/.bashrc

# Recharger
source ~/.bashrc
```


## 9. Configuration des namespaces (BONNE PRATIQUE)

**IMPORTANT :** Ne jamais travailler dans le namespace `default` en production ! Créez toujours des namespaces dédiés.

```bash
# Créer un namespace pour le TP
kubectl create namespace tp-kubernetes

# Vérifier les namespaces
kubectl get namespaces

# Configurer kubectl pour utiliser ce namespace par défaut
kubectl config set-context --current --namespace=tp-kubernetes

# Vérifier le namespace actuel
kubectl config view --minify | grep namespace:

# Lister les pods dans le namespace actuel
kubectl get pods

# Pour revenir au namespace default (déconseillé)
# kubectl config set-context --current --namespace=default
```

### Organisation recommandée des namespaces

```bash
# Pour différents environnements
kubectl create namespace dev
kubectl create namespace test
kubectl create namespace prod

# Pour différentes applications
kubectl create namespace frontend
kubectl create namespace backend
kubectl create namespace database

# Pour le TP (recommandation)
kubectl create namespace tp-kubernetes
kubectl config set-context --current --namespace=tp-kubernetes
```

## 10. Vérification de l'installation

```bash
# Vérifier que tous les composants sont installés
docker --version
kubectl version --client
minikube version
helm version  # si installé
k9s version   # si installé

# Vérifier que le cluster fonctionne
kubectl cluster-info
kubectl get nodes

# Vérifier le namespace actuel
kubectl config view --minify | grep namespace:

# Lister tous les pods (dans tous les namespaces)
kubectl get pods -A

# Lister les pods dans votre namespace
kubectl get pods
```

## 11. Commandes utiles Minikube

```bash
# Démarrer le cluster
minikube start

# Arrêter le cluster
minikube stop

# Supprimer le cluster
minikube delete

# Accéder au dashboard Kubernetes
minikube dashboard

# SSH dans le node Minikube
minikube ssh

# Voir les addons disponibles
minikube addons list

# Activer un addon (exemple: ingress)
minikube addons enable ingress

# Voir les logs
minikube logs
```

## 12. Installation d'un Ingress Controller (NGINX)

Pour le TP, vous aurez besoin d'un Ingress Controller :

```bash
# Avec Minikube (méthode la plus simple)
minikube addons enable ingress

# Vérifier que l'Ingress Controller est déployé
kubectl get pods -n ingress-nginx

# OU installation manuelle via Helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx
```

## 13. Configuration des ressources Minikube (si nécessaire)

Si vous avez besoin de plus de ressources :

```bash
# Supprimer le cluster existant
minikube delete

# Recréer avec plus de ressources
minikube start --cpus=4 --memory=8192 --disk-size=40g --driver=docker
```

## Dépannage

### Problème : Minikube détecte un proxy indésirable

**Erreur courante :**
```
Options de réseau trouvées : HTTP_PROXY=...
Vous semblez utiliser un proxy...
```

**Solution : Supprimer le cluster et redémarrer sans proxy**
```bash
# 1. Supprimer le cluster existant
minikube delete

# 2. Supprimer les variables de proxy
unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy NO_PROXY no_proxy

# 3. Vérifier qu'elles sont bien supprimées
env | grep -i proxy

# 4. Redémarrer Minikube proprement
minikube start --driver=docker

# 5. Vérifier qu'il n'y a plus de proxy
minikube ssh "env | grep -i proxy"
```

**Pour rendre permanent (ajouter dans ~/.bashrc ou ~/.zshrc) :**
```bash
# Désactiver le proxy pour la session locale (si vous n'en avez pas besoin)
unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy NO_PROXY no_proxy
```

### Problème : Minikube ne démarre pas

```bash
# Vérifier les logs
minikube logs

# Essayer de supprimer et recréer
minikube delete
minikube start --driver=docker --force
```

### Problème : Permission denied avec Docker

**Erreur courante :**
```
Got permission denied while trying to connect to the Docker daemon socket
```

**Solution :**
```bash
# 1. Vérifier que vous êtes dans le groupe docker
groups

# 2. Si 'docker' n'apparaît pas dans la liste :
sudo usermod -aG docker $USER

# 3. OBLIGATOIRE : Se déconnecter et se reconnecter
exit
# Puis reconnectez-vous via SSH ou la console

# 4. Vérifier à nouveau
groups | grep docker

# 5. Tester Docker sans sudo
docker ps

# 6. Si ça fonctionne, lancer Minikube
minikube start --driver=docker
```

**Note :** La commande `newgrp docker` peut ne pas suffire pour Minikube. Une vraie déconnexion/reconnexion est nécessaire !

### Problème : kubectl ne trouve pas le cluster

```bash
# Vérifier le contexte
kubectl config current-context

# Lister les contextes
kubectl config get-contexts

# Basculer vers minikube
kubectl config use-context minikube
```

## Ressources complémentaires

- Documentation officielle Kubernetes : https://kubernetes.io/docs/
- Documentation Minikube : https://minikube.sigs.k8s.io/docs/
- Kubectl Cheat Sheet : https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- k9s Documentation : https://k9scli.io/

## Félicitations !

Votre environnement Kubernetes est maintenant prêt pour le TP02. Vous pouvez commencer à déployer des applications !

**Commandes de test rapide :**

```bash
# 1. Créer un namespace dédié (BONNE PRATIQUE)
kubectl create namespace tp-kubernetes
kubectl config set-context --current --namespace=tp-kubernetes

# 2. Vérifier le namespace actuel
kubectl config view --minify | grep namespace:

# 3. Créer un pod nginx de test
kubectl run nginx-test --image=nginx --port=80

# 4. Vérifier
kubectl get pods

# 5. Exposer le pod
kubectl expose pod nginx-test --type=NodePort --port=80

# 6. Accéder au service
minikube service nginx-test -n tp-kubernetes

# 7. Nettoyer
kubectl delete pod nginx-test
kubectl delete service nginx-test

# 8. Pour voir les ressources dans tous les namespaces
kubectl get pods -A
```

## Résumé des bonnes pratiques

1. **Toujours utiliser des namespaces dédiés** - Ne jamais travailler dans `default`
2. **Désactiver le proxy** si non nécessaire pour Minikube
3. **Être dans le groupe docker** avant de lancer Minikube
4. **Vérifier le namespace actuel** avec `kubectl config view --minify | grep namespace:`
5. **Utiliser `-A` pour voir toutes les ressources** : `kubectl get pods -A`
6. **Activer l'Ingress** pour exposer les applications : `minikube addons enable ingress`
