# Compte-Rendu TP2 - Déploiement Kubernetes

**Date :** 2025-11-11
**Objectif :** Maîtriser le déploiement d'applications sur Kubernetes avec les concepts de Compute, Storage et Network

---

## Table des matières

1. [Prérequis et Configuration du Cluster](#1-prérequis-et-configuration-du-cluster)
2. [Focus sur les commandes kubectl](#2-focus-sur-les-commandes-kubectl)
3. [Informations sur le cluster](#3-informations-sur-le-cluster)
4. [Les Objets Kubernetes](#4-les-objets-kubernetes)
5. [Déploiement de l'application VS Code](#5-déploiement-de-lapplication-vs-code)
6. [Déploiement de l'application Guestbook](#6-déploiement-de-lapplication-guestbook)
7. [Bilan et Conclusion](#7-bilan-et-conclusion)

---

## 1. Prérequis et Configuration du Cluster

### 1.1 Configuration du Cluster Kind

Le TP nécessite un cluster Kind avec **2 control-plane + 1 worker**, avec forward des ports 80 et 443.

**Fichier de configuration** : `cluster.yaml`

```yaml
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
```

**Création du cluster :**

```bash
kind create cluster --name cluster-tp2 --config cluster.yaml
```

**Vérification :**

```bash
kubectl get nodes
```

**Résultat obtenu :**

```
NAME                        STATUS   ROLES           AGE     VERSION
cluster-tp2-control-plane   Ready    control-plane   3m47s   v1.27.3
cluster-tp2-control-plane2  Ready    control-plane   3m30s   v1.27.3
cluster-tp2-worker          Ready    <none>          2m34s   v1.27.3
```

### 1.2 Installation de l'Ingress Controller

Pour permettre l'accès aux applications via HTTP, nous devons installer **nginx-ingress** :

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
```

**Attendre que le pod ingress soit prêt :**

```bash
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

### 1.3 ⚠️ Problème Rencontré : Ingress Controller sur le Mauvais Nœud

**Symptôme :** Impossible d'accéder aux applications via `http://localhost`

**Diagnostic :**

```bash
# Vérifier où tourne l'ingress controller
kubectl get pods -n ingress-nginx -o wide
```

**Résultat initial :**
```
NAME                                        READY   STATUS    NODE
ingress-nginx-controller-6bc8c55c76-twb54   1/1     Running   cluster-tp2-control-plane2
```

**Problème identifié :**
- L'ingress controller tourne sur `cluster-tp2-control-plane2`
- Mais le port forwarding 80:80 est configuré uniquement sur `cluster-tp2-control-plane`
- Le label `ingress-ready=true` est sur `cluster-tp2-control-plane`

**Solution :** Forcer l'ingress controller à tourner sur le bon nœud avec un `nodeSelector`

```bash
# Patcher le deployment pour ajouter un nodeSelector
kubectl patch deployment -n ingress-nginx ingress-nginx-controller \
  -p '{"spec":{"template":{"spec":{"nodeSelector":{"ingress-ready":"true"}}}}}'
```

**Vérification après correction :**

```bash
kubectl get pods -n ingress-nginx -o wide
```

**Résultat :**
```
NAME                                       READY   STATUS    NODE
ingress-nginx-controller-bbd9ffff9-m454z   1/1     Running   cluster-tp2-control-plane
```

✅ L'ingress controller tourne maintenant sur le bon nœud !

**Test de connectivité :**

```bash
# Test VS Code
curl -H "Host: mon-app.local" http://localhost
# Résultat : Found. Redirecting to ./login

# Test Guestbook
curl -H "Host: guestbook.local" http://localhost
# Résultat : <html ng-app="redis">...
```

**Leçon apprise :** Dans un cluster multi-control-plane avec Kind :
- Le port forwarding n'est actif que sur le nœud avec `extraPortMappings`
- L'ingress controller **doit** tourner sur ce nœud spécifique
- Utiliser `nodeSelector` ou `nodeName` pour garantir le placement correct

### 1.4 💡 Meilleure Approche : Kustomize

Au lieu de patcher manuellement après chaque installation, on peut utiliser **Kustomize** pour appliquer le `nodeSelector` automatiquement.

**Créer** : `ingress-kustomize/kustomization.yaml`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

patches:
  - patch: |-
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: ingress-nginx-controller
        namespace: ingress-nginx
      spec:
        template:
          spec:
            nodeSelector:
              ingress-ready: "true"
```

**Installer avec Kustomize :**

```bash
kubectl apply -k ingress-kustomize/
```

✅ Le nodeSelector est automatiquement appliqué dès l'installation !

**Script d'automatisation complet** : [setup-cluster.sh](setup-cluster.sh)

```bash
#!/bin/bash
# Crée le cluster + installe ingress avec nodeSelector en une seule commande
./setup-cluster.sh
```

---

## 2. Focus sur les commandes kubectl

### 2.1 Les verbes kubectl les plus courants

| Verbe | Description |
|-------|-------------|
| `get` | Affiche une ressource |
| `describe` | Affiche des détails spécifiques sur une ou plusieurs ressources |
| `create` | Crée une ressource (ou à partir d'un fichier avec -f) |
| `apply` | Applique un manifeste |
| `delete` | Supprime une ressource (ou un fichier avec -f) |
| `logs` | Affiche les logs d'un pod |
| `exec` | Exécute une commande dans un conteneur |

### 2.2 Exemples de commandes utiles

```bash
# Lister tous les objets dans tous les namespaces
kubectl get all --all-namespaces

# Obtenir des informations détaillées sur un pod
kubectl describe pod <nom-du-pod>

# Voir les logs d'un deployment
kubectl logs -f deployment/<nom-deployment>

# Exécuter une commande dans un pod
kubectl exec -it <nom-pod> -- /bin/bash
```

---

## 3. Informations sur le cluster

### 📝 Question 1 : Afficher la liste des namespaces du cluster

**Commande :**

```bash
kubectl get namespaces
```

**Résultat :**

```
NAME                 STATUS   AGE
default              Active   3m47s
ingress-nginx        Active   2m24s
kube-node-lease      Active   3m47s
kube-public          Active   3m47s
kube-system          Active   3m47s
local-path-storage   Active   3m35s
```

**Réponse :** Le cluster contient **6 namespaces**.

---

### 📝 Question 2 : Afficher la liste des objets dans le namespace kube-system

**Commande :**

```bash
kubectl get all -n kube-system
```

**Objets affichés :**

- **Pods** : coredns, etcd, kube-apiserver, kube-controller-manager, kube-proxy, kube-scheduler, kindnet
- **Services** : kube-dns
- **DaemonSets** : kindnet, kube-proxy
- **Deployments** : coredns
- **ReplicaSets** : coredns

Ces objets constituent les composants essentiels du plan de contrôle Kubernetes.

---

### 📝 Question 3 : Quelle adresse IP le service kubernetes a-t-il ?

**Commande :**

```bash
kubectl get svc kubernetes
```

**Résultat :**

```
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   5m
```

**Réponse :** Le service kubernetes a l'adresse IP **10.96.0.1** (ClusterIP).

---

## 4. Les Objets Kubernetes

### 4.1 Afficher le service kubernetes en YAML

**Commande :**

```bash
kubectl get svc kubernetes -o yaml
```

**Extrait du résultat :**

```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    component: apiserver
    provider: kubernetes
  name: kubernetes
  namespace: default
spec:
  clusterIP: 10.96.0.1
  ports:
  - name: https
    port: 443
    protocol: TCP
    targetPort: 6443
  type: ClusterIP
```

### 📝 Questions sur l'objet kubernetes :

**Q1. Quelle est la version de l'API de l'objet kubernetes ?**
**Réponse :** `v1`

**Q2. Quel est le type d'objet ?**
**Réponse :** `Service`

**Q3. Quelles sont les labels de cet objet ?**
**Réponse :**
- `component: apiserver`
- `provider: kubernetes`

---

### 4.2 API Resources : namespaced vs non-namespaced

**Commande pour lister les ressources :**

```bash
kubectl api-resources --verbs=list
```

### 📝 Question : Différence entre api-resources namespaced true/false

**Réponse :**

**Namespaced=true** : Ces ressources sont **limitées à un namespace** spécifique. Elles permettent d'isoler les ressources par projet/environnement.

**Exemples :**
- `Pod` - Les pods sont déployés dans un namespace
- `Service` - Les services sont isolés par namespace
- `Deployment` - Les déploiements appartiennent à un namespace
- `ConfigMap`, `Secret` - Configuration isolée par namespace

**Namespaced=false** : Ces ressources sont **au niveau du cluster** et accessibles globalement.

**Exemples :**
- `Node` - Les nœuds sont une ressource cluster-wide
- `Namespace` - Les namespaces eux-mêmes sont cluster-wide
- `PersistentVolume` - Les volumes persistants sont partagés au niveau cluster
- `ClusterRole` - Les rôles RBAC au niveau cluster

**Avantage du namespacing :** Permet l'isolation multi-tenant, la gestion des quotas par équipe, et l'organisation logique des applications.

---

## 5. Déploiement de l'application VS Code

L'application **VS Code Server** illustre les 3 composants principaux d'une application cloud dans Kubernetes :

1. **Compute** (Deployment)
2. **Storage** (PersistentVolumeClaim)
3. **Network** (Service + Ingress)

### 5.1 Compute Manifest - `compute.yaml`

Ce manifeste déploie un **Deployment** qui gère un pod VS Code Server.

```yaml
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
```

### 📝 Questions sur le Deployment :

**Q1. À quoi sert la section `env` ?**

**Réponse :** La section `env` permet de définir des **variables d'environnement** pour le conteneur. Dans cet exemple :
- La variable `PASSWORD` est injectée dans le conteneur
- Elle provient d'un **Secret Kubernetes** (`coder-password`)
- Cela permet de ne pas stocker le mot de passe en clair dans le manifeste
- Le conteneur VS Code utilise cette variable pour protéger l'accès

**Q2. À quoi sert la section `volume` et `volumeMount` ?**

**Réponse :**

**`volumes`** : Déclare les volumes disponibles pour le pod
- Dans notre cas, un volume `coder` qui référence un `PersistentVolumeClaim`
- Le PVC fournit un stockage persistant qui survit au redémarrage du pod

**`volumeMounts`** : Monte un volume dans le système de fichiers du conteneur
- Le volume `coder` est monté dans `/home/coder`
- Cela permet de persister les fichiers et configurations de l'utilisateur
- Sans cela, toutes les modifications seraient perdues au redémarrage du pod

**`initContainers`** : Conteneur qui s'exécute avant le conteneur principal
- Ici, il corrige les permissions du volume (chmod 777)
- Nécessaire car le PVC peut avoir des permissions restrictives par défaut

---

### 5.2 Storage Manifest - `storage.yaml`

```yaml
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
```

### 📝 Question : Pourquoi créer un PVC ?

**Réponse :**

Un **PersistentVolumeClaim (PVC)** est créé pour plusieurs raisons :

1. **Persistance des données** : Les conteneurs sont éphémères. Sans PVC, toutes les données seraient perdues au redémarrage du pod.

2. **Abstraction du stockage** : Le PVC abstrait le stockage sous-jacent :
   - L'application demande simplement "5Gi de stockage"
   - Kubernetes se charge de provisionner le volume via la **StorageClass**
   - Le type de stockage (NFS, iSCSI, cloud provider) est transparent pour l'application

3. **Portabilité** : Le même manifeste fonctionne sur différents clusters :
   - Sur AWS → EBS volume
   - Sur GCP → Persistent Disk
   - Sur Kind → local-path provisioner

4. **Gestion du cycle de vie** : Le volume persiste même si le pod est supprimé (selon la `reclaimPolicy`)

5. **Isolation** : Chaque application a son propre espace de stockage isolé

**Modes d'accès disponibles :**
- `ReadWriteOnce` (RWO) : Montable en lecture-écriture par un seul nœud
- `ReadOnlyMany` (ROX) : Montable en lecture seule par plusieurs nœuds
- `ReadWriteMany` (RWX) : Montable en lecture-écriture par plusieurs nœuds

---

### 5.3 Network Manifest - `network.yaml`

Ce manifeste contient **2 objets** : un Service et un Ingress.

```yaml
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
```

**Rôle du Service :**
- Expose le port 8080 du pod
- Fournit une IP stable (ClusterIP)
- Load-balance entre les pods avec le label `app: code-server`

**Rôle de l'Ingress :**
- Point d'entrée HTTP/HTTPS depuis l'extérieur du cluster
- Route le trafic vers le service `code-server`
- Permet l'accès via un nom de domaine (`mon-app.local`)

---

### 5.4 Secret Kubernetes - `secret.yaml`

Pour sécuriser le mot de passe, nous utilisons un **Secret** :

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: coder-password
type: Opaque
stringData:
  password: MonSuperMotDePasse123
```

### 📝 Question : Comment faire en sorte que ce secret ne soit pas en clair dans nos manifests ?

**Réponse :**

Le stockage en base64 (par défaut dans Kubernetes) **n'est PAS du chiffrement** ! Voici les solutions recommandées :

**1. Sealed Secrets (Bitnami)**
```bash
# Installer sealed-secrets controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.18.0/controller.yaml

# Chiffrer un secret
kubeseal --format=yaml < secret.yaml > sealed-secret.yaml
```
- Le secret chiffré peut être committé dans Git
- Seul le cluster peut le déchiffrer

**2. External Secrets Operator**
- Intégration avec des gestionnaires de secrets externes :
  - AWS Secrets Manager
  - Azure Key Vault
  - HashiCorp Vault
  - Google Secret Manager
- Les secrets ne sont jamais stockés dans Git

**3. SOPS (Secrets OPerationS)**
```bash
# Chiffrer un fichier avec SOPS
sops --encrypt --age <public-key> secret.yaml > secret.enc.yaml
```
- Chiffrement avec GPG ou age
- Compatible avec Git et CI/CD

**4. HashiCorp Vault**
- Solution entreprise complète
- Rotation automatique des secrets
- Audit trail complet

**5. Kubernetes RBAC + Git privé**
- Stocker les secrets dans un repo Git **privé** séparé
- Restreindre l'accès via RBAC
- Ne jamais committer les secrets dans le repo applicatif

**Meilleure pratique :** External Secrets Operator + cloud provider secret manager

---

### 5.5 Déploiement de VS Code

```bash
# Déployer tous les manifests
kubectl apply -f vs_code/

# Vérifier le déploiement
kubectl get pods
kubectl get pvc
kubectl get svc
kubectl get ingress
```

**Résultat :**

```
NAME                           READY   STATUS    RESTARTS   AGE
code-server-7ddb4bdd54-4wzrs   1/1     Running   0          2m

NAME          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
code-server   Bound    pvc-xxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx      5Gi        RWO            standard       2m

NAME          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
code-server   ClusterIP   10.96.179.65    <none>        8080/TCP   2m

NAME          CLASS    HOSTS           ADDRESS     PORTS   AGE
code-server   <none>   mon-app.local   localhost   80      2m
```

### 📝 Questions de test :

**Q1. Comment accédez-vous à l'application mon-app.local ?**

**Réponse :**

1. **Ajouter une entrée dans /etc/hosts :**

```bash
echo "127.0.0.1 mon-app.local" | sudo tee -a /etc/hosts
```

2. **Accéder via le navigateur :**

```
http://mon-app.local
```

3. **Test avec curl :**

```bash
curl -H "Host: mon-app.local" http://localhost
```

**Explication :**
- Kind forward le port 80 du conteneur control-plane vers localhost:80
- L'Ingress controller nginx route le trafic selon l'en-tête Host
- Le navigateur résout `mon-app.local` vers 127.0.0.1 grâce à /etc/hosts

---

**Q2. Comment affichez-vous les logs des requêtes entrantes sur votre application ?**

**Réponse :**

**Logs du pod VS Code :**
```bash
kubectl logs -f deployment/code-server
```

**Logs de l'Ingress Controller (requêtes HTTP) :**
```bash
kubectl logs -f -n ingress-nginx deployment/ingress-nginx-controller
```

**Logs en temps réel avec grep :**
```bash
kubectl logs -f -n ingress-nginx deployment/ingress-nginx-controller | grep "mon-app.local"
```

**Afficher les dernières 100 lignes :**
```bash
kubectl logs --tail=100 deployment/code-server
```

---

**Q3. Quand vous supprimez le pod que se passe-t-il ?**

**Réponse :**

**Test :**
```bash
# Supprimer le pod
kubectl delete pod code-server-7ddb4bdd54-4wzrs

# Observer la recréation automatique
kubectl get pods -w
```

**Résultat observé :**

```
NAME                           READY   STATUS        RESTARTS   AGE
code-server-7ddb4bdd54-4wzrs   1/1     Terminating   0          5m
code-server-7ddb4bdd54-xk9nm   0/1     Pending       0          0s
code-server-7ddb4bdd54-xk9nm   0/1     ContainerCreating   0     1s
code-server-7ddb4bdd54-xk9nm   1/1     Running             0     15s
```

**Explication :**

1. **Le Deployment maintient l'état désiré** : `replicas: 1`
2. Quand le pod est supprimé, le **ReplicaSet** (contrôlé par le Deployment) détecte que l'état actuel (0 pod) ≠ état désiré (1 pod)
3. Il crée **automatiquement un nouveau pod** avec un nouveau nom
4. Le nouveau pod :
   - Remonte le même **PVC** (les données sont préservées)
   - Récupère le même **Secret**
   - Est accessible via le même **Service** (grâce aux labels)

**Auto-réparation (self-healing)** : C'est un principe fondamental de Kubernetes !

---

## 6. Déploiement de l'application Guestbook

L'application **Guestbook** est une application PHP avec Redis qui illustre une architecture multi-tiers.

### 6.1 Architecture de Guestbook

```
┌─────────────────┐
│   Frontend      │  3 replicas (PHP)
│   (PHP)         │  Port: 80
└────────┬────────┘
         │
    ┌────┴─────┐
    │          │
┌───▼──┐   ┌──▼─────┐
│Redis │   │ Redis  │
│Leader│   │Follower│ 2 replicas
│(RW)  │   │  (RO)  │
└──────┘   └────────┘
```

**Composants :**
- **Frontend** : 3 réplicas PHP qui affichent/enregistrent des messages
- **Redis Leader** : 1 instance pour les écritures
- **Redis Followers** : 2 instances pour les lectures (réplication)

---

### 6.2 Déploiement Redis Leader

**Fichier** : `redis-leader-deployment.yaml`

```yaml
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
```

**Service Redis Leader** : `redis-leader-service.yaml`

```yaml
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
```

**Déploiement :**

```bash
kubectl apply -f guestbook/redis-leader-deployment.yaml
kubectl apply -f guestbook/redis-leader-service.yaml

# Vérification
kubectl get pods -l app=redis,role=leader
kubectl logs -f deployment/redis-leader
```

---

### 6.3 Déploiement Redis Followers

**Fichier** : `redis-follower-deployment.yaml`

```yaml
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
```

**Service Redis Followers** : `redis-follower-service.yaml`

```yaml
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
```

**Déploiement :**

```bash
kubectl apply -f guestbook/redis-follower-deployment.yaml
kubectl apply -f guestbook/redis-follower-service.yaml

# Vérification
kubectl get pods -l app=redis,role=follower
```

**Résultat attendu :**

```
NAME                              READY   STATUS    RESTARTS   AGE
redis-follower-6f6cd6cbdb-kn6b8   1/1     Running   0          1m
redis-follower-6f6cd6cbdb-rx9kd   1/1     Running   0          1m
```

---

### 6.4 Déploiement du Frontend PHP

**Fichier** : `frontend-deployment.yaml`

```yaml
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
```

**Explication de l'environnement :**
- `GET_HOSTS_FROM: "dns"` : L'application utilise le DNS Kubernetes pour trouver les services `redis-leader` et `redis-follower`
- Le frontend écrit dans `redis-leader.default.svc.cluster.local`
- Le frontend lit depuis `redis-follower.default.svc.cluster.local`

**Service Frontend** : `frontend-service.yaml`

```yaml
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
```

**Ingress Frontend** : `frontend-ingress.yaml`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: frontend
  labels:
    app: guestbook
    tier: frontend
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
```

**Déploiement :**

```bash
kubectl apply -f guestbook/frontend-deployment.yaml
kubectl apply -f guestbook/frontend-service.yaml
kubectl apply -f guestbook/frontend-ingress.yaml

# Vérification
kubectl get pods -l app=guestbook
kubectl get svc frontend
kubectl get ingress frontend
```

---

### 6.5 Test de l'application Guestbook

**1. Ajouter l'entrée DNS locale :**

```bash
echo "127.0.0.1 guestbook.local" | sudo tee -a /etc/hosts
```

**2. Accéder à l'application :**

```
http://guestbook.local
```

**3. Tester l'application :**

- Ajouter un message dans le champ de texte
- Cliquer sur "Submit"
- Le message doit apparaître dans la liste

**4. Vérifier le fonctionnement de Redis :**

```bash
# Vérifier les logs du leader
kubectl logs -f deployment/redis-leader

# Vérifier les logs des followers
kubectl logs -f deployment/redis-follower

# Se connecter à Redis pour vérifier les données
kubectl exec -it deployment/redis-leader -- redis-cli
> KEYS *
> GET messages
```

**5. Tester la haute disponibilité :**

```bash
# Supprimer un pod frontend
kubectl delete pod -l app=guestbook,tier=frontend --field-selector status.phase=Running

# Observer la recréation automatique
kubectl get pods -l app=guestbook -w

# L'application reste accessible pendant la recréation !
curl http://guestbook.local
```

---

## 7. Bilan et Conclusion

### 7.1 Concepts Kubernetes Maîtrisés

**✅ Objets de base :**
- **Deployment** : Gestion déclarative des Pods
- **Service** : Exposition stable des Pods (load-balancing)
- **Ingress** : Routage HTTP/HTTPS externe
- **PersistentVolumeClaim** : Stockage persistant
- **Secret** : Gestion sécurisée des credentials

**✅ Patterns architecturaux :**
- **Compute, Storage, Network** : Les 3 piliers du cloud
- **Architecture multi-tiers** : Frontend + Backend (Redis)
- **Haute disponibilité** : Réplication avec leader/follower
- **Auto-réparation** : Self-healing via Deployment controller

**✅ Commandes kubectl :**
```bash
# Gestion des ressources
kubectl get/describe/apply/delete

# Debug
kubectl logs -f deployment/<name>
kubectl exec -it <pod> -- /bin/bash

# Supervision
kubectl get pods -w
kubectl get events
```

---

### 7.2 Architecture Déployée

```
┌──────────────────────────────────────────┐
│          Ingress Controller              │
│       (nginx - Port 80/443)              │
└────────────┬─────────────┬───────────────┘
             │             │
   ┌─────────▼───┐   ┌────▼──────────┐
   │mon-app.local│   │guestbook.local│
   └─────────┬───┘   └────┬──────────┘
             │            │
     ┌───────▼───────┐   ┌▼────────────┐
     │Service:       │   │Service:     │
     │code-server    │   │frontend     │
     │Port: 8080     │   │Port: 80     │
     └───────┬───────┘   └┬────────────┘
             │            │
     ┌───────▼───────┐   ┌▼────────────┐
     │Deployment:    │   │Deployment:  │
     │code-server    │   │frontend     │
     │Replicas: 1    │   │Replicas: 3  │
     └───────┬───────┘   └┬────────────┘
             │            │
     ┌───────▼───────┐   ┌▼────────────┐
     │PVC:           │   │Redis Leader │
     │code-server    │   │+ Followers  │
     │5Gi            │   │             │
     └───────────────┘   └─────────────┘
```

---

### 7.3 Commandes de Gestion du Cluster

**Lister toutes les ressources déployées :**

```bash
kubectl get all
```

**Vérifier l'état complet :**

```bash
# Pods
kubectl get pods -o wide

# Services
kubectl get svc

# Ingress
kubectl get ingress

# PVC et PV
kubectl get pvc
kubectl get pv

# Events récents
kubectl get events --sort-by=.metadata.creationTimestamp
```

**Nettoyer les ressources :**

```bash
# Supprimer l'application VS Code
kubectl delete -f vs_code/

# Supprimer Guestbook
kubectl delete -f guestbook/

# Supprimer le cluster
kind delete cluster --name cluster-tp2
```

---

### 7.4 Points Clés à Retenir

**1. Déclaratif vs Impératif**
- Kubernetes favorise l'approche déclarative (manifests YAML)
- L'état désiré est maintenu automatiquement par les controllers

**2. Labels et Selectors**
- Les Services trouvent les Pods via les labels
- Les Deployments gèrent les Pods via matchLabels
- Stratégie de labelling cohérente = critique

**3. Namespaces**
- Isolation logique des ressources
- Quotas et RBAC par namespace
- Ne jamais déployer en production dans `default`

**4. Stockage**
- PVC = abstraction portable
- StorageClass = provisionneur dynamique
- Les données survivent aux pods

**5. Networking**
- Service = IP stable + load-balancing
- Ingress = reverse proxy HTTP/HTTPS
- DNS interne : `<service>.<namespace>.svc.cluster.local`

**6. Sécurité**
- Secrets pour les credentials
- RBAC pour les accès
- Network Policies pour l'isolation réseau
- Pod Security Standards

**7. Haute Disponibilité du Control-Plane**
- **2 control-planes** dans ce TP pour apprendre les concepts HA
- Chaque control-plane exécute : kube-apiserver, etcd, controller-manager, scheduler
- **kube-apiserver** : Mode Actif-Actif (les 2 répondent simultanément)
- **etcd** : Cluster distribué avec consensus Raft (quorum nécessaire)
- **controller-manager & scheduler** : Mode Actif-Passif (élection de leader)
- **Production** : Recommandé 3 ou 5 control-planes (nombre impair) pour un quorum optimal
- **Avantage** : Tolérance aux pannes, zero downtime, disaster recovery

**Composants etcd vérifiés :**
```bash
kubectl exec -n kube-system etcd-cluster-tp2-control-plane -- etcdctl member list
# Résultat : 2 membres (cluster-tp2-control-plane et cluster-tp2-control-plane2)
```

**Leader election vérifiée :**
```bash
kubectl get lease -n kube-system kube-controller-manager
# holderIdentity: cluster-tp2-control-plane
```

**Pourquoi pas optimal avec 2 ?**
- Quorum etcd nécessite 2/2 membres actifs
- Si 1 tombe → cluster inaccessible (quorum non atteint)
- Meilleur choix production : **3 control-planes** (tolère 1 panne)

---

### 7.5 Améliorations Possibles

**Pour aller plus loin :**

1. **Observabilité**
   - Déployer Prometheus + Grafana
   - Configurer des dashboards de monitoring
   - Alerting avec AlertManager

2. **Haute Disponibilité**
   - Pod Disruption Budgets
   - Anti-affinity rules (spread pods across nodes)
   - Health checks (liveness/readiness probes)

3. **Sécurité Avancée**
   - Network Policies pour isoler les tiers
   - Pod Security Admission
   - Secrets encryption at rest
   - External Secrets Operator

4. **CI/CD**
   - GitOps avec ArgoCD ou Flux
   - Automated deployments
   - Blue/Green ou Canary deployments

5. **Scalabilité**
   - Horizontal Pod Autoscaler (HPA)
   - Vertical Pod Autoscaler (VPA)
   - Cluster Autoscaler

---

### 7.6 Ressources Utiles

**Documentation officielle :**
- https://kubernetes.io/docs/
- https://kind.sigs.k8s.io/

**Cheat sheets :**
- kubectl : https://kubernetes.io/docs/reference/kubectl/cheatsheet/

**Tutoriels :**
- https://kubernetes.io/docs/tutorials/
- https://www.katacoda.com/courses/kubernetes

---

## Annexe : Récapitulatif des Commandes

```bash
# Cluster Kind
kind create cluster --name cluster-tp2 --config cluster.yaml
kind get clusters
kind delete cluster --name cluster-tp2

# Ingress-nginx
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s

# Déploiements
kubectl apply -f vs_code/
kubectl apply -f guestbook/

# Vérifications
kubectl get nodes
kubectl get namespaces
kubectl get all
kubectl get pods -o wide
kubectl get svc
kubectl get ingress
kubectl get pvc

# Debug
kubectl describe pod <pod-name>
kubectl logs -f deployment/<deployment-name>
kubectl exec -it <pod-name> -- /bin/bash
kubectl get events --sort-by=.metadata.creationTimestamp

# Tests
curl -H "Host: mon-app.local" http://localhost
curl -H "Host: guestbook.local" http://localhost

# Nettoyage
kubectl delete -f vs_code/
kubectl delete -f guestbook/
kind delete cluster --name cluster-tp2
```

---

**Fin du Compte-Rendu TP2**

**Date de réalisation :** 2025-11-11
**Cluster utilisé :** Kind v0.20.0 avec Kubernetes v1.27.3
**Applications déployées :** VS Code Server + Guestbook PHP/Redis
