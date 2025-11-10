# Installation Rapide - TP02 : Déploiement d'applications sur Kubernetes

Guide pratique pour réaliser le TP02 - Déploiement d'applications sur Kubernetes.

## Prérequis

- ✅ TP01 terminé (cluster Kind fonctionnel)
- ✅ 4 CPUs (2 cœurs control-plane + 2 cœurs worker)
- ✅ Cluster Kind avec 2 control-plane + 1 worker
- ✅ Port forwarding 80:80 et 443:443 configuré
- ✅ Ingress Controller NGINX déployé
- ✅ Nginx de test déployé et accessible
- ✅ **Proxy désactivé** pour Kubernetes (`proxy-off`)

Si vous n'avez pas fait le TP01, consultez [INSTALL_TP1_RAPIDE.md](INSTALL_TP1_RAPIDE.md)

## ⚠️ Rappel Important sur le Proxy

**AVANT de commencer le TP02**, assurez-vous que le proxy est désactivé :

```bash
# Vérifier l'état du proxy
proxy-status

# Si un proxy apparaît, le désactiver
proxy-off

# Vérifier à nouveau (ne devrait RIEN afficher)
env | grep -i proxy
```

**Configuration recommandée** :
- ✅ Proxy Docker daemon : **ACTIVÉ** (pour télécharger les images)
- ❌ Variables proxy shell : **DÉSACTIVÉES** (pour kubectl/Kind)

```bash
# Vérifier le proxy Docker (devrait être configuré)
sudo systemctl show --property=Environment docker

# Vérifier les variables d'environnement (ne devrait RIEN afficher)
env | grep -i proxy
```

## Structure du TP02

Le TP02 couvre deux déploiements :
1. **VS Code Server** - Application simple avec stockage persistant
2. **Guestbook PHP/Redis** - Application multi-tiers complète

---

## Partie 1 : Déploiement VS Code Server

### Étape 1 : Créer le namespace et le dossier de travail

```bash
# Créer un namespace dédié
kubectl create namespace tp-kubernetes

# Définir comme namespace par défaut
kubectl config set-context --current --namespace=tp-kubernetes

# Vérifier
kubectl config view --minify | grep namespace:

# Créer le dossier de travail
mkdir -p ~/tp02/vs_code
cd ~/tp02/vs_code
```

### Étape 2 : Créer le manifest Compute (Deployment)

Créez le fichier `compute.yaml` :

```bash
cat > compute.yaml <<'EOF'
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: code-server
  name: code-server
spec:
  selector:
    matchLabels:
      app: code-server
  replicas: 1
  template:
    metadata:
      labels:
        app: code-server
    spec:
      containers:
      - env:
        - name: PASSWORD
          valueFrom:
            secretKeyRef:
              name: coder-password
              key: password
        image: codercom/code-server:latest
        imagePullPolicy: Always
        name: code-server
        ports:
        - name: code-server
          containerPort: 8080
          protocol: TCP
        volumeMounts:
        - mountPath: /home/coder
          name: coder
      initContainers:
      - name: pvc-permission-fix
        image: busybox
        command: ["/bin/chmod","-R","777", "/home/coder"]
        volumeMounts:
        - name: coder
          mountPath: /home/coder
      volumes:
      - name: coder
        persistentVolumeClaim:
          claimName: code-server
EOF
```

**Points clés** :
- `env` : Variables d'environnement (PASSWORD vient d'un Secret)
- `volumeMounts` : Monte le PVC dans `/home/coder`
- `initContainers` : Fixe les permissions avant le démarrage

### Étape 3 : Créer le manifest Storage (PVC)

Créez le fichier `storage.yaml` :

```bash
cat > storage.yaml <<'EOF'
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: code-server
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
EOF
```

**Points clés** :
- Demande 5Gi de stockage
- Mode `ReadWriteOnce` : un seul nœud peut monter le volume en lecture/écriture
- Kind fournit automatiquement un PersistentVolume via StorageClass

### Étape 4 : Créer le manifest Network (Service + Ingress)

Créez le fichier `network.yaml` :

```bash
cat > network.yaml <<'EOF'
---
apiVersion: v1
kind: Service
metadata:
  name: code-server
  labels:
    app: code-server
spec:
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 8080
  selector:
    app: code-server
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: code-server
  labels:
    app: code-server
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  - host: "mon-app.local"
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: code-server
            port:
              number: 8080
EOF
```

**Points clés** :
- Service expose le pod sur le port 8080 en interne
- Ingress route le trafic de `mon-app.local` vers le service

### Étape 5 : Créer le Secret

Créez le fichier `secret.yaml` :

```bash
cat > secret.yaml <<'EOF'
---
apiVersion: v1
kind: Secret
metadata:
  name: coder-password
type: Opaque
stringData:
  password: MonSuperMotDePasse123
EOF
```

**⚠️ ATTENTION** : En production, ne jamais commiter les secrets en clair !
Solutions recommandées :
- **Sealed Secrets** (Bitnami)
- **External Secrets Operator**
- **HashiCorp Vault**
- **kubectl create secret** (crée le secret sans fichier)

```bash
# Alternative : créer le secret via kubectl (recommandé)
kubectl create secret generic coder-password \
  --from-literal=password=MonSuperMotDePasse123 \
  -n tp-kubernetes
```

### Étape 6 : Déployer l'application

```bash
# Déployer dans l'ordre
kubectl apply -f secret.yaml
kubectl apply -f storage.yaml
kubectl apply -f compute.yaml
kubectl apply -f network.yaml

# Vérifier le déploiement
kubectl get all
kubectl get pvc
kubectl get ingress
```

### Étape 7 : Accéder à l'application

```bash
# Ajouter l'entrée DNS locale
echo "127.0.0.1 mon-app.local" | sudo tee -a /etc/hosts

# Attendre que le pod soit prêt
kubectl wait --for=condition=ready pod -l app=code-server --timeout=120s

# Vérifier les logs
kubectl logs -l app=code-server --tail=50

# Tester l'accès
curl -I http://mon-app.local
```

Ouvrez votre navigateur : [http://mon-app.local](http://mon-app.local)

**Mot de passe** : `MonSuperMotDePasse123`

### Étape 8 : Questions du TP

#### Q1 : Comment accéder à l'application mon-app.local ?
```bash
# Via l'entrée dans /etc/hosts qui pointe vers 127.0.0.1
# L'Ingress Controller écoute sur le port 80 et route vers le service
```

#### Q2 : Comment afficher les logs des requêtes entrantes ?
```bash
# Logs du pod de l'application
kubectl logs -l app=code-server -f

# Logs de l'Ingress Controller
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller -f
```

#### Q3 : Que se passe-t-il quand vous supprimez le pod ?
```bash
# Supprimer le pod
kubectl delete pod -l app=code-server

# Observer la recréation automatique
kubectl get pods -w

# Le Deployment détecte que le pod est manquant et en recrée un automatiquement
# C'est le principe du "self-healing" de Kubernetes
```

### Étape 9 : Nettoyage

```bash
# Supprimer toutes les ressources
kubectl delete -f network.yaml
kubectl delete -f compute.yaml
kubectl delete -f storage.yaml
kubectl delete -f secret.yaml

# OU supprimer tout d'un coup
kubectl delete all,ingress,pvc,secret -l app=code-server
```

---

## Partie 2 : Application Guestbook PHP/Redis

### Architecture

```
┌─────────────────┐
│  Frontend PHP   │  (3 replicas)
│   Guestbook     │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
┌───▼──┐  ┌──▼────────┐
│ Redis│  │   Redis   │
│Leader│  │ Followers │ (2 replicas)
│(écriture)│ (lecture) │
└──────┘  └───────────┘
```

### Étape 1 : Créer le dossier de travail

```bash
mkdir -p ~/tp02/guestbook-php
cd ~/tp02/guestbook-php
```

### Étape 2 : Déployer Redis Leader

Créez `redis-leader-deployment.yaml` :

```bash
cat > redis-leader-deployment.yaml <<'EOF'
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-leader
  labels:
    app: redis
    role: leader
    tier: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
        role: leader
        tier: backend
    spec:
      containers:
      - name: leader
        image: "docker.io/redis:6.0.5"
        resources:
          requests:
            cpu: 100m
            memory: 100Mi
        ports:
        - containerPort: 6379
EOF
```

Créez `redis-leader-service.yaml` :

```bash
cat > redis-leader-service.yaml <<'EOF'
---
apiVersion: v1
kind: Service
metadata:
  name: redis-leader
  labels:
    app: redis
    role: leader
    tier: backend
spec:
  ports:
  - port: 6379
    targetPort: 6379
  selector:
    app: redis
    role: leader
    tier: backend
EOF
```

Déployer :

```bash
kubectl apply -f redis-leader-deployment.yaml
kubectl apply -f redis-leader-service.yaml

# Vérifier
kubectl get pods -l app=redis
kubectl logs -f deployment/redis-leader
```

### Étape 3 : Déployer Redis Followers

Créez `redis-follower-deployment.yaml` :

```bash
cat > redis-follower-deployment.yaml <<'EOF'
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-follower
  labels:
    app: redis
    role: follower
    tier: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
        role: follower
        tier: backend
    spec:
      containers:
      - name: follower
        image: gcr.io/google_samples/gb-redis-follower:v2
        resources:
          requests:
            cpu: 100m
            memory: 100Mi
        ports:
        - containerPort: 6379
EOF
```

Créez `redis-follower-service.yaml` :

```bash
cat > redis-follower-service.yaml <<'EOF'
---
apiVersion: v1
kind: Service
metadata:
  name: redis-follower
  labels:
    app: redis
    role: follower
    tier: backend
spec:
  ports:
  - port: 6379
  selector:
    app: redis
    role: follower
    tier: backend
EOF
```

Déployer :

```bash
kubectl apply -f redis-follower-deployment.yaml
kubectl apply -f redis-follower-service.yaml

# Vérifier
kubectl get pods -l role=follower
kubectl get service
```

### Étape 4 : Déployer le Frontend Guestbook

Créez `frontend-deployment.yaml` :

```bash
cat > frontend-deployment.yaml <<'EOF'
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: guestbook
      tier: frontend
  template:
    metadata:
      labels:
        app: guestbook
        tier: frontend
    spec:
      containers:
      - name: php-redis
        image: gcr.io/google_samples/gb-frontend:v5
        env:
        - name: GET_HOSTS_FROM
          value: "dns"
        resources:
          requests:
            cpu: 10m
            memory: 10Mi
        ports:
        - containerPort: 80
EOF
```

Créez `frontend-service.yaml` :

```bash
cat > frontend-service.yaml <<'EOF'
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
  labels:
    app: guestbook
    tier: frontend
spec:
  ports:
  - port: 80
  selector:
    app: guestbook
    tier: frontend
EOF
```

Déployer :

```bash
kubectl apply -f frontend-deployment.yaml
kubectl apply -f frontend-service.yaml

# Vérifier
kubectl get pods -l app=guestbook -l tier=frontend
kubectl get service frontend
```

### Étape 5 : Créer l'Ingress pour Guestbook

Créez `frontend-ingress.yaml` :

```bash
cat > frontend-ingress.yaml <<'EOF'
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: guestbook-ingress
  labels:
    app: guestbook
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  - host: "guestbook.local"
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
EOF
```

Déployer :

```bash
kubectl apply -f frontend-ingress.yaml

# Ajouter l'entrée DNS
echo "127.0.0.1 guestbook.local" | sudo tee -a /etc/hosts

# Vérifier
kubectl get ingress
```

### Étape 6 : Tester l'application Guestbook

```bash
# Attendre que tous les pods soient prêts
kubectl wait --for=condition=ready pod -l app=guestbook --timeout=120s
kubectl wait --for=condition=ready pod -l app=redis --timeout=120s

# Vérifier l'état complet
kubectl get all

# Tester
curl http://guestbook.local
```

Ouvrez votre navigateur : [http://guestbook.local](http://guestbook.local)

**Testez l'application** :
1. Écrivez un message dans le champ de texte
2. Cliquez sur "Submit"
3. Le message devrait apparaître dans la liste

### Étape 7 : Tests de résilience

```bash
# Test 1 : Supprimer un pod Redis follower
kubectl delete pod -l role=follower --force --grace-period=0
kubectl get pods -l app=redis -w

# Test 2 : Supprimer un pod frontend
kubectl delete pod -l tier=frontend --force --grace-period=0
kubectl get pods -l app=guestbook -w

# Test 3 : Scaler le frontend
kubectl scale deployment frontend --replicas=5
kubectl get pods -l app=guestbook

# Test 4 : Revenir à 3 replicas
kubectl scale deployment frontend --replicas=3
```

---

## Déploiement avec un seul fichier (Bonus)

Vous pouvez combiner tous les manifests dans un seul fichier :

```bash
cat > guestbook-complete.yaml <<'EOF'
---
# Redis Leader Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-leader
  labels:
    app: redis
    role: leader
    tier: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
      role: leader
  template:
    metadata:
      labels:
        app: redis
        role: leader
        tier: backend
    spec:
      containers:
      - name: leader
        image: "docker.io/redis:6.0.5"
        resources:
          requests:
            cpu: 100m
            memory: 100Mi
        ports:
        - containerPort: 6379
---
# Redis Leader Service
apiVersion: v1
kind: Service
metadata:
  name: redis-leader
  labels:
    app: redis
    role: leader
    tier: backend
spec:
  ports:
  - port: 6379
    targetPort: 6379
  selector:
    app: redis
    role: leader
    tier: backend
---
# Redis Follower Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-follower
  labels:
    app: redis
    role: follower
    tier: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: redis
      role: follower
  template:
    metadata:
      labels:
        app: redis
        role: follower
        tier: backend
    spec:
      containers:
      - name: follower
        image: gcr.io/google_samples/gb-redis-follower:v2
        resources:
          requests:
            cpu: 100m
            memory: 100Mi
        ports:
        - containerPort: 6379
---
# Redis Follower Service
apiVersion: v1
kind: Service
metadata:
  name: redis-follower
  labels:
    app: redis
    role: follower
    tier: backend
spec:
  ports:
  - port: 6379
  selector:
    app: redis
    role: follower
    tier: backend
---
# Frontend Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: guestbook
      tier: frontend
  template:
    metadata:
      labels:
        app: guestbook
        tier: frontend
    spec:
      containers:
      - name: php-redis
        image: gcr.io/google_samples/gb-frontend:v5
        env:
        - name: GET_HOSTS_FROM
          value: "dns"
        resources:
          requests:
            cpu: 10m
            memory: 10Mi
        ports:
        - containerPort: 80
---
# Frontend Service
apiVersion: v1
kind: Service
metadata:
  name: frontend
  labels:
    app: guestbook
    tier: frontend
spec:
  ports:
  - port: 80
  selector:
    app: guestbook
    tier: frontend
---
# Frontend Ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: guestbook-ingress
  labels:
    app: guestbook
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  - host: "guestbook.local"
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
EOF

# Déployer tout en une fois
kubectl apply -f guestbook-complete.yaml
```

---

## Commandes utiles pour le TP02

### Inspection et debugging

```bash
# Voir tous les objets
kubectl get all

# Voir les objets dans tous les namespaces
kubectl get all -A

# Décrire un pod
kubectl describe pod <pod-name>

# Logs d'un pod
kubectl logs <pod-name>
kubectl logs -f <pod-name>  # Suivre les logs en temps réel
kubectl logs <pod-name> --previous  # Logs du conteneur précédent

# Logs avec sélecteur
kubectl logs -l app=code-server -f

# Exécuter une commande dans un pod
kubectl exec -it <pod-name> -- /bin/sh
kubectl exec -it <pod-name> -- bash

# Port-forward pour accès direct
kubectl port-forward pod/<pod-name> 8080:8080
kubectl port-forward service/code-server 8080:8080

# Voir les events
kubectl get events --sort-by='.lastTimestamp'

# Top ressources
kubectl top nodes
kubectl top pods
```

### Gestion des ressources

```bash
# Scaler un deployment
kubectl scale deployment <name> --replicas=5

# Éditer une ressource
kubectl edit deployment <name>

# Mettre à jour une image
kubectl set image deployment/<name> <container>=<new-image>

# Rollout status
kubectl rollout status deployment/<name>

# Rollback
kubectl rollout undo deployment/<name>

# Historique des rollouts
kubectl rollout history deployment/<name>
```

### Nettoyage

```bash
# Supprimer une ressource
kubectl delete pod <pod-name>
kubectl delete deployment <deployment-name>

# Supprimer via fichier
kubectl delete -f fichier.yaml

# Supprimer toutes les ressources d'un label
kubectl delete all -l app=guestbook

# Supprimer tout dans le namespace
kubectl delete all --all

# Supprimer le namespace (et tout dedans)
kubectl delete namespace tp-kubernetes
```

---

## Réponses aux questions du TP

### Q1 : À quoi sert la section env ?
La section `env` permet de passer des variables d'environnement aux conteneurs. Cela permet de configurer l'application sans modifier l'image Docker.

### Q2 : À quoi sert la section volume et volumeMount ?
- `volumes` : Déclare les volumes disponibles pour le pod
- `volumeMounts` : Monte un volume dans le système de fichiers du conteneur
- Permet la persistance des données et le partage entre conteneurs

### Q3 : Pourquoi créer un PVC ?
- Persistance des données au-delà du cycle de vie des pods
- Abstraction du stockage physique
- Portabilité entre environnements
- Séparation des responsabilités (dev vs ops)

### Q4 : Différence entre api-resources namespaced true/false
- **namespaced=true** : Ressources limitées à un namespace (Pod, Service, Deployment)
- **namespaced=false** : Ressources au niveau du cluster (Node, Namespace, PersistentVolume)

Exemples :
```bash
# Ressources namespacées
kubectl api-resources --namespaced=true

# Ressources cluster-wide
kubectl api-resources --namespaced=false
```

### Q5 : Comment sécuriser les secrets ?
**Ne jamais** commiter les secrets en clair dans Git !

Solutions recommandées :
1. **Sealed Secrets** (Bitnami) : Chiffre les secrets
2. **External Secrets Operator** : Sync avec des coffres externes
3. **HashiCorp Vault** : Gestion centralisée des secrets
4. **Cloud providers** : AWS Secrets Manager, Azure Key Vault, GCP Secret Manager
5. **kubectl create secret** : Créer sans fichier YAML

```bash
# Créer un secret sans fichier
kubectl create secret generic my-secret \
  --from-literal=password=SuperSecret123 \
  --dry-run=client -o yaml | kubectl apply -f -
```

---

## Checklist de validation TP02

### VS Code Server
- [ ] Namespace `tp-kubernetes` créé
- [ ] Secret créé
- [ ] PVC créé et bound
- [ ] Deployment déployé avec 1 pod running
- [ ] Service créé
- [ ] Ingress créé
- [ ] Application accessible via `http://mon-app.local`
- [ ] Connexion possible avec le mot de passe
- [ ] Logs visibles avec `kubectl logs`
- [ ] Pod se recrée automatiquement après suppression

### Guestbook
- [ ] Redis Leader déployé (1 pod)
- [ ] Service Redis Leader créé
- [ ] Redis Followers déployés (2 pods)
- [ ] Service Redis Followers créé
- [ ] Frontend déployé (3 pods)
- [ ] Service Frontend créé
- [ ] Ingress créé
- [ ] Application accessible via `http://guestbook.local`
- [ ] Possibilité d'écrire et lire des messages
- [ ] Résilience testée (suppression de pods)

---

## Dépannage

### Problème : Erreurs liées au proxy

#### Symptômes
- Pods en état `ImagePullBackOff`
- Erreurs lors de `kubectl apply`
- Timeouts lors du déploiement

#### Solution

```bash
# 1. Vérifier les variables de proxy shell (DOIVENT être vides)
env | grep -i proxy
# Si quelque chose s'affiche, c'est le problème !

# 2. Désactiver toutes les variables de proxy
proxy-off

# OU manuellement :
unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy NO_PROXY no_proxy
export http_proxy=""
export https_proxy=""

# 3. Vérifier le proxy Docker (DOIT être configuré)
sudo systemctl show --property=Environment docker
# Devrait afficher HTTP_PROXY et HTTPS_PROXY

# 4. Si le proxy Docker n'est pas configuré, le configurer
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf > /dev/null <<'EOF'
[Service]
Environment="HTTP_PROXY=http://proxy.iut.univ:3128"
Environment="HTTPS_PROXY=http://proxy.iut.univ:3128"
Environment="NO_PROXY=localhost,127.0.0.1,.local,.cluster.local"
EOF

sudo systemctl daemon-reload
sudo systemctl restart docker

# 5. Redéployer l'application
kubectl delete -f .
kubectl apply -f .
```

### Problème : Pod en état Pending

```bash
# Voir pourquoi
kubectl describe pod <pod-name>

# Causes courantes :
# - PVC non bound
# - Ressources insuffisantes
# - Image pull error
```

### Problème : Ingress ne fonctionne pas

```bash
# Vérifier l'Ingress Controller
kubectl get pods -n ingress-nginx

# Vérifier les logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Vérifier la configuration Ingress
kubectl describe ingress <ingress-name>

# Vérifier /etc/hosts
cat /etc/hosts | grep local
```

### Problème : PVC reste en Pending

```bash
# Voir les détails
kubectl describe pvc <pvc-name>

# Vérifier les StorageClass
kubectl get storageclass

# Kind devrait avoir une StorageClass par défaut
```

### Problème : Image pull error

```bash
# Voir les détails
kubectl describe pod <pod-name>

# Causes :
# - Image n'existe pas
# - Problème de proxy
# - Problème de registry
```

---

## Nettoyage complet

```bash
# Supprimer VS Code Server
cd ~/tp02/vs_code
kubectl delete -f .

# Supprimer Guestbook
cd ~/tp02/guestbook-php
kubectl delete -f .

# Supprimer le namespace (supprime tout dedans)
kubectl delete namespace tp-kubernetes

# Recréer le namespace pour un nouveau test
kubectl create namespace tp-kubernetes
kubectl config set-context --current --namespace=tp-kubernetes
```

---

## Résumé : Configuration Proxy pour TP02

### Checklist Proxy avant de commencer

```bash
# ✅ 1. Proxy Docker daemon configuré
sudo systemctl show --property=Environment docker | grep PROXY
# Doit afficher : HTTP_PROXY et HTTPS_PROXY

# ❌ 2. Variables proxy shell DÉSACTIVÉES
env | grep -i proxy
# Ne doit RIEN afficher

# ✅ 3. Test de pull d'image Docker
docker pull nginx:latest
# Doit fonctionner

# ✅ 4. Test kubectl
kubectl get nodes
# Doit afficher les nœuds du cluster
```

### Aide-mémoire commandes proxy

```bash
# Activer le proxy (rarement nécessaire pendant le TP)
proxy-on

# Désactiver le proxy (toujours pour Kubernetes)
proxy-off

# Vérifier l'état
proxy-status
```

### Si rien ne fonctionne

```bash
# Reset complet de la configuration proxy
# 1. Désactiver toutes les variables
unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy NO_PROXY no_proxy

# 2. Vérifier Docker
sudo systemctl restart docker
sudo systemctl show --property=Environment docker

# 3. Recréer le cluster Kind si nécessaire
kind delete cluster --name tp-cluster
kind create cluster --name tp-cluster --config kind-cluster-config.yaml

# 4. Réinstaller l'Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
```

---

## Ressources complémentaires

- [Guide d'installation TP01](INSTALL_TP1_RAPIDE.md) - **Contient la configuration proxy complète**
- [Glossaire Kubernetes](KUBERNETES_GLOSSAIRE.md)
- [Documentation Kubernetes](https://kubernetes.io/docs/)
- [Documentation Kind](https://kind.sigs.k8s.io/)
- [Ingress NGINX](https://kubernetes.github.io/ingress-nginx/)

---

## Compte-rendu du TP02

**N'oubliez pas de faire votre compte-rendu avec :**

### Contenu obligatoire
- ✅ Captures d'écran des applications fonctionnelles
  - VS Code Server accessible via navigateur
  - Guestbook accessible et fonctionnel
- ✅ Réponses aux questions marquées 🙋
- ✅ Explications de vos choix techniques
- ✅ Problèmes rencontrés et solutions appliquées

### Questions à répondre

1. **À quoi sert la section env ?**
2. **À quoi sert la section volume et volumeMount ?**
3. **Pourquoi créer un PVC ?**
4. **Comment accéder à l'application mon-app.local ?**
5. **Comment afficher les logs des requêtes entrantes ?**
6. **Que se passe-t-il quand vous supprimez un pod ?**
7. **Comment sécuriser les secrets ?**
8. **Différence entre api-resources namespaced true/false ?**

### Bonus : Problèmes proxy rencontrés

Si vous avez rencontré des problèmes liés au proxy, documentez :
- Le symptôme observé
- Comment vous avez diagnostiqué le problème
- La solution appliquée
- Comment vérifier que c'est résolu

---

**Félicitations !** 🎉

Vous avez maintenant déployé deux applications complètes sur Kubernetes et maîtrisez les concepts de base du déploiement d'applications conteneurisées.

**Points clés acquis** :
- ✅ Déploiement d'applications stateless et stateful
- ✅ Gestion du stockage persistant
- ✅ Exposition via Services et Ingress
- ✅ Gestion des Secrets
- ✅ Architecture multi-tiers
- ✅ **Configuration proxy pour environnement IUT**
- ✅ Debugging et dépannage
