#!/bin/bash

# Script master pour construire une image VM Proxmox complète avec Kubernetes et proxy

set -e

echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║   Construction d'une image VM Proxmox avec Kubernetes + Proxy    ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""

# Vérifier que nous sommes root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Ce script doit être exécuté en tant que root"
    echo "   Utilisez : sudo $0"
    exit 1
fi

# Détection de l'utilisateur cible
TARGET_USER="${SUDO_USER:-ubuntu}"
echo "Utilisateur cible : $TARGET_USER"
echo ""

# Étape 1 : Configuration du proxy
echo "═══════════════════════════════════════════════════════════════════"
echo " ÉTAPE 1 : Configuration du proxy"
echo "═══════════════════════════════════════════════════════════════════"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/setup-proxy.sh" ]; then
    bash "$SCRIPT_DIR/setup-proxy.sh"
else
    echo "⚠️  Script setup-proxy.sh non trouvé, passage à l'étape suivante..."
fi

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo " ÉTAPE 2 : Installation des outils Kubernetes"
echo "═══════════════════════════════════════════════════════════════════"
if [ -f "$SCRIPT_DIR/install-kubernetes-tools.sh" ]; then
    bash "$SCRIPT_DIR/install-kubernetes-tools.sh"
else
    echo "❌ Script install-kubernetes-tools.sh non trouvé!"
    exit 1
fi

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo " ÉTAPE 3 : Configuration finale et nettoyage"
echo "═══════════════════════════════════════════════════════════════════"

# Créer un README dans /home/$TARGET_USER
echo "Création du README..."
cat > /home/$TARGET_USER/README.md << 'EOFREADME'
# VM Kubernetes - Guide de démarrage

## Configuration

Cette VM est préconfigurée avec :
- ✅ Docker
- ✅ Minikube
- ✅ kubectl
- ✅ Helm
- ✅ k9s (TUI pour Kubernetes)
- ✅ kubectx & kubens
- ✅ Proxy système (192.168.0.2:3128)

## Démarrage rapide

### 1. Démarrer Minikube

```bash
start-k8s
# ou
minikube start --driver=docker
```

### 2. Vérifier le cluster

```bash
kubectl get nodes
# ou avec l'alias
k get nodes
```

### 3. Déployer une application test

```bash
kubectl create deployment hello-node --image=k8s.gcr.io/echoserver:1.4
kubectl expose deployment hello-node --type=LoadBalancer --port=8080
minikube service hello-node
```

### 4. Utiliser le dashboard

```bash
minikube dashboard
```

### 5. Explorer avec k9s

```bash
k9s
```

## Commandes utiles

### Minikube

```bash
start-k8s          # Démarrer Minikube
stop-k8s           # Arrêter Minikube
minikube status    # Voir le statut
minikube ip        # Obtenir l'IP du cluster
minikube ssh       # SSH dans le node Minikube
minikube addons list  # Lister les addons
```

### kubectl (alias: k)

```bash
k get pods                    # Lister les pods
k get deployments            # Lister les déploiements
k get services               # Lister les services
k describe pod <pod-name>    # Détails d'un pod
k logs <pod-name>            # Logs d'un pod
k exec -it <pod> -- bash     # Shell dans un pod
```

### Helm (alias: h)

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm search repo nginx
helm install my-nginx bitnami/nginx
helm list
helm uninstall my-nginx
```

### kubectx & kubens

```bash
kubectx                # Lister les contextes
kubectx <context>      # Changer de contexte
kubens                 # Lister les namespaces
kubens <namespace>     # Changer de namespace
```

## Configuration du proxy

Le proxy 192.168.0.2:3128 est configuré pour :
- APT
- Docker
- wget/curl
- Git
- Variables d'environnement système

### Désactiver le proxy temporairement

```bash
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
```

### Désactiver le proxy définitivement

```bash
sudo /usr/local/bin/disable-proxy
```

### Modifier le proxy

Éditez `/etc/profile.d/proxy.sh` et redémarrez votre session.

## Exemples de déploiements

### Nginx

```bash
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --type=NodePort --port=80
minikube service nginx --url
```

### WordPress + MySQL

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install my-wordpress bitnami/wordpress
```

## Dépannage

### Minikube ne démarre pas

```bash
minikube delete
minikube start --driver=docker --v=7
```

### Problème de proxy

```bash
# Vérifier la configuration
echo $http_proxy
curl -I http://google.com

# Reconfigurer
sudo /usr/local/bin/setup-proxy.sh
```

### Docker ne fonctionne pas

```bash
sudo systemctl status docker
sudo systemctl restart docker
```

### Vérifier les ressources

```bash
free -h           # Mémoire
df -h             # Disque
docker info       # Info Docker
```

## Ressources

- [Documentation Minikube](https://minikube.sigs.k8s.io/docs/)
- [Documentation Kubernetes](https://kubernetes.io/docs/)
- [Documentation Helm](https://helm.sh/docs/)
- [k9s Documentation](https://k9scli.io/)

## Support

Pour obtenir de l'aide :
1. Vérifiez les logs : `minikube logs`
2. Consultez le statut : `minikube status`
3. Vérifiez Docker : `docker info`
EOFREADME
chown $TARGET_USER:$TARGET_USER /home/$TARGET_USER/README.md
echo "   ✓ README créé"

# Ajuster les permissions
echo "Ajustement des permissions..."
chown -R $TARGET_USER:$TARGET_USER /home/$TARGET_USER
echo "   ✓ Permissions ajustées"

# Activer les services au démarrage
echo "Activation des services..."
systemctl enable docker
systemctl enable containerd
echo "   ✓ Services activés"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║              ✅ IMAGE VM PRÊTE !                                  ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""
echo "Configuration complète :"
echo "  ✓ Proxy système configuré (192.168.0.2:3128)"
echo "  ✓ Docker installé et configuré"
echo "  ✓ Minikube installé"
echo "  ✓ kubectl installé"
echo "  ✓ Helm installé"
echo "  ✓ k9s installé"
echo "  ✓ kubectx & kubens installés"
echo "  ✓ Alias et auto-complétion configurés"
echo "  ✓ Scripts start-k8s et stop-k8s créés"
echo "  ✓ README créé (/home/$TARGET_USER/README.md)"
echo ""
echo "Prochaines étapes :"
echo "  1. Convertir cette VM en template Proxmox"
echo "  2. Cloner le template pour créer de nouvelles VMs"
echo "  3. Dans chaque VM, exécuter : start-k8s"
echo ""
echo "Pour désactiver le proxy : sudo /usr/local/bin/disable-proxy"
echo ""
