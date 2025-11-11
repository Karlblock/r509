# Glossaire Kubernetes - Définitions des objets et concepts

Ce document présente les définitions de tous les éléments clés de Kubernetes, organisés par catégorie.

---

## 1. Architecture et Composants du Cluster

### **Cluster**
Ensemble de machines (nodes) qui exécutent des applications conteneurisées orchestrées par Kubernetes. Un cluster contient au minimum un control plane et un ou plusieurs worker nodes.

### **Node**
Machine physique ou virtuelle qui fait partie du cluster Kubernetes. Il existe deux types :
- **Control Plane Node** (anciennement Master) : gère le cluster
- **Worker Node** : exécute les applications

### **Control Plane**
Ensemble de composants qui contrôlent le cluster Kubernetes. Comprend :
- **kube-apiserver** : Point d'entrée de toutes les commandes (API REST)
- **etcd** : Base de données clé-valeur stockant l'état du cluster
- **kube-scheduler** : Décide sur quel node placer les pods
- **kube-controller-manager** : Exécute les contrôleurs (réplication, endpoints, etc.)
- **cloud-controller-manager** : Intègre avec le cloud provider

### **Kubelet**
Agent qui s'exécute sur chaque worker node. Il s'assure que les conteneurs décrits dans les pods fonctionnent correctement.

### **Kube-proxy**
Service réseau qui s'exécute sur chaque node. Il maintient les règles réseau permettant la communication entre les pods et avec l'extérieur.

### **Container Runtime**
Logiciel responsable de l'exécution des conteneurs (Docker, containerd, CRI-O).

---

## 2. Workloads (Charges de travail)

### **Pod**
**Définition** : Plus petite unité déployable dans Kubernetes. Un pod contient un ou plusieurs conteneurs qui partagent le même réseau et stockage.

**Caractéristiques** :
- IP unique partagée entre tous les conteneurs du pod
- Volume partagé entre les conteneurs
- Éphémère (peut être détruit et recréé)
- Un pod = une instance d'application

**Exemple d'utilisation** :
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
spec:
  containers:
  - name: nginx
    image: nginx:1.21
    ports:
    - containerPort: 80
```

**Analogie** : Un pod est comme un appartement où vivent un ou plusieurs colocataires (conteneurs) qui partagent les mêmes ressources (réseau, volumes).

---

### **ReplicaSet**
**Définition** : Garantit qu'un nombre spécifié de répliques d'un pod s'exécutent à tout moment.

**Caractéristiques** :
- Maintient le nombre désiré de pods
- Crée de nouveaux pods si certains sont supprimés
- Utilise des sélecteurs de labels pour identifier les pods
- Rarement utilisé directement (préférer Deployment)

**Exemple** :
```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: frontend-rs
spec:
  replicas: 3
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: nginx
        image: nginx
```

---

### **Deployment**
**Définition** : Gère le déploiement et la mise à jour déclarative des ReplicaSets et des Pods.

**Caractéristiques** :
- Mises à jour progressives (rolling updates)
- Rollback vers versions précédentes
- Scaling horizontal (augmenter/diminuer le nombre de répliques)
- Self-healing (redémarre les pods défaillants)

**Exemple** :
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: webapp
        image: myapp:v1.0
        ports:
        - containerPort: 8080
```

**Cas d'usage** : Applications stateless (frontend web, API REST, microservices)

---

### **StatefulSet**
**Définition** : Comme un Deployment, mais pour les applications avec état (stateful) qui nécessitent une identité stable.

**Caractéristiques** :
- Identité réseau stable et persistante
- Stockage persistant lié à chaque pod
- Ordre de déploiement et suppression garanti
- Nom de pod prévisible : `nom-0`, `nom-1`, `nom-2`

**Exemple** :
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: mysql
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

**Cas d'usage** : Bases de données (MySQL, PostgreSQL, MongoDB), systèmes distribués (Kafka, ZooKeeper, Cassandra)

---

### **DaemonSet**
**Définition** : Assure qu'une copie d'un pod s'exécute sur tous (ou certains) nodes du cluster.

**Caractéristiques** :
- Un pod par node automatiquement
- Suit l'ajout/suppression de nodes
- Utile pour les tâches système

**Exemple** :
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-exporter
spec:
  selector:
    matchLabels:
      app: monitoring
  template:
    metadata:
      labels:
        app: monitoring
    spec:
      containers:
      - name: node-exporter
        image: prom/node-exporter
```

**Cas d'usage** :
- Collecteurs de logs (Fluentd, Logstash)
- Monitoring (Prometheus Node Exporter)
- Stockage distribué (Ceph, GlusterFS)
- Réseau (CNI plugins)

---

### **Job**
**Définition** : Crée un ou plusieurs pods et s'assure qu'un nombre spécifié se termine avec succès.

**Caractéristiques** :
- Exécution unique (run-to-completion)
- Retry automatique en cas d'échec
- Parallélisation possible
- Suppression automatique après succès (optionnel)

**Exemple** :
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: data-migration
spec:
  completions: 1
  template:
    spec:
      containers:
      - name: migrator
        image: migration-script:v1
        command: ["python", "migrate.py"]
      restartPolicy: Never
```

**Cas d'usage** : Migrations de base de données, traitements batch, calculs scientifiques

---

### **CronJob**
**Définition** : Crée des Jobs selon un planning (comme cron Unix).

**Caractéristiques** :
- Planification avec syntaxe cron
- Historique des exécutions
- Gestion des Jobs concurrents

**Exemple** :
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-database
spec:
  schedule: "0 2 * * *"  # Tous les jours à 2h du matin
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: backup-tool:v1
            command: ["./backup.sh"]
          restartPolicy: OnFailure
```

**Cas d'usage** : Sauvegardes automatiques, nettoyage de logs, rapports périodiques, synchronisation de données

---

## 3. Réseau et Exposition

### **Service**
**Définition** : Abstraction qui expose un ensemble de pods comme un service réseau avec une IP et un DNS stables.

**Types de Services** :

#### **ClusterIP** (par défaut)
- Accessible uniquement à l'intérieur du cluster
- IP virtuelle interne
- DNS : `service-name.namespace.svc.cluster.local`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  type: ClusterIP
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 8080
```

**Cas d'usage** : Communication inter-services (frontend → backend)

#### **NodePort**
- Expose le service sur chaque node à un port statique (30000-32767)
- Accessible depuis l'extérieur via `<NodeIP>:<NodePort>`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp-service
spec:
  type: NodePort
  selector:
    app: webapp
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080
```

**Cas d'usage** : Développement, accès rapide pour tests

#### **LoadBalancer**
- Crée un load balancer externe (nécessite un cloud provider)
- IP publique automatique

```yaml
apiVersion: v1
kind: Service
metadata:
  name: public-api
spec:
  type: LoadBalancer
  selector:
    app: api
  ports:
  - port: 443
    targetPort: 8443
```

**Cas d'usage** : Production sur cloud (AWS, GCP, Azure)

#### **ExternalName**
- Mappe un service à un nom DNS externe
- Pas de proxy, juste un alias DNS

```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-db
spec:
  type: ExternalName
  externalName: db.example.com
```

---

### **Ingress**
**Définition** : Gère l'accès externe HTTP/HTTPS aux services. Fournit le routage basé sur l'URL, l'équilibrage de charge et la terminaison SSL.

**Caractéristiques** :
- Routing par hostname et path
- Terminaison TLS/SSL
- Virtual hosting
- Un seul point d'entrée pour plusieurs services

**Exemple** :
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webapp-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - www.example.com
    secretName: example-tls
  rules:
  - host: www.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend
            port:
              number: 8080
```

**PathType** :
- **Prefix** : Correspond à tout chemin commençant par le préfixe
- **Exact** : Correspondance exacte du chemin
- **ImplementationSpecific** : Dépend de l'Ingress Controller

**Cas d'usage** :
- Exposition d'applications web en production
- Routing multi-applications
- Gestion centralisée des certificats SSL

---

### **Ingress Controller**
**Définition** : Composant qui implémente les règles Ingress (NGINX, Traefik, HAProxy, Istio).

**Rôle** :
- Écoute les objets Ingress
- Configure le reverse proxy
- Gère le load balancing
- Termine les connexions SSL/TLS

**Installation (exemple NGINX)** :
```bash
minikube addons enable ingress
# OU
helm install nginx-ingress ingress-nginx/ingress-nginx
```

---

### **NetworkPolicy**
**Définition** : Règles de firewall au niveau des pods pour contrôler le trafic réseau entrant et sortant.

**Exemple** :
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
```

**Cas d'usage** : Micro-segmentation, sécurité réseau, isolation multi-tenant

---

## 4. Stockage

### **Volume**
**Définition** : Répertoire accessible aux conteneurs d'un pod. Survit aux redémarrages de conteneurs mais pas à la suppression du pod.

**Types principaux** :
- **emptyDir** : Volume temporaire vide (partagé entre conteneurs du pod)
- **hostPath** : Monte un répertoire du node (dangereux en production)
- **configMap** : Monte une ConfigMap comme volume
- **secret** : Monte un Secret comme volume
- **persistentVolumeClaim** : Référence un PVC

**Exemple emptyDir** :
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cache-pod
spec:
  containers:
  - name: app
    image: myapp
    volumeMounts:
    - name: cache
      mountPath: /cache
  volumes:
  - name: cache
    emptyDir: {}
```

---

### **PersistentVolume (PV)**
**Définition** : Ressource de stockage dans le cluster, provisionnée par un administrateur ou dynamiquement.

**Caractéristiques** :
- Indépendant du cycle de vie des pods
- Capacité définie
- Modes d'accès (ReadWriteOnce, ReadOnlyMany, ReadWriteMany)
- Policy de réclamation (Retain, Delete, Recycle)

**Exemple** :
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-data
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
  hostPath:
    path: /mnt/data
```

---

### **PersistentVolumeClaim (PVC)**
**Définition** : Demande de stockage par un utilisateur. Kubernetes lie automatiquement un PVC à un PV compatible.

**Caractéristiques** :
- Spécifie la taille et le mode d'accès souhaités
- Binding automatique avec un PV disponible
- Utilisé dans les pods comme volume

**Exemple** :
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: standard
```

**Utilisation dans un pod** :
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
  - name: app
    image: myapp
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: data-pvc
```

---

### **StorageClass**
**Définition** : Définit les "classes" de stockage disponibles (SSD, HDD, NFS, etc.) avec provisionnement dynamique.

**Caractéristiques** :
- Provisionnement automatique des PV
- Paramètres spécifiques au provider
- Permet aux utilisateurs de choisir le type de stockage

**Exemple** :
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp3
  iops: "3000"
  fsType: ext4
reclaimPolicy: Delete
allowVolumeExpansion: true
```

**Modes d'accès** :
- **ReadWriteOnce (RWO)** : Lecture-écriture par un seul node
- **ReadOnlyMany (ROX)** : Lecture seule par plusieurs nodes
- **ReadWriteMany (RWX)** : Lecture-écriture par plusieurs nodes

**Analogie** :
- **StorageClass** = Type de logement (studio, appartement, maison)
- **PersistentVolume** = Logement physique disponible
- **PersistentVolumeClaim** = Demande de location avec critères

---

## 5. Configuration et Secrets

### **ConfigMap**
**Définition** : Objet pour stocker des données de configuration non confidentielles sous forme clé-valeur.

**Caractéristiques** :
- Sépare la configuration du code
- Peut être monté comme volume ou variable d'environnement
- Modifiable sans rebuild de l'image

**Exemple** :
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  database_host: mysql.default.svc.cluster.local
  database_port: "3306"
  log_level: "info"
  config.json: |
    {
      "feature_x": true,
      "timeout": 30
    }
```

**Utilisation dans un pod** :
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
  - name: app
    image: myapp
    env:
    - name: DB_HOST
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: database_host
    volumeMounts:
    - name: config
      mountPath: /etc/config
  volumes:
  - name: config
    configMap:
      name: app-config
```

**Cas d'usage** :
- Configuration d'applications (URLs, ports, timeouts)
- Fichiers de configuration (nginx.conf, application.properties)
- Feature flags

---

### **Secret**
**Définition** : Similaire à ConfigMap mais pour stocker des données sensibles (mots de passe, tokens, clés).

**Caractéristiques** :
- Encodé en base64 (PAS chiffré par défaut !)
- Accès restreint par RBAC
- Peut être chiffré au repos (encryption at rest)
- Ne pas commiter dans Git !

**Exemple** :
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
data:
  username: YWRtaW4=        # admin en base64
  password: cGFzc3dvcmQxMjM= # password123 en base64
```

**Création via kubectl** :
```bash
# Méthode recommandée (évite de stocker en clair)
kubectl create secret generic db-secret \
  --from-literal=username=admin \
  --from-literal=password=password123

# Depuis un fichier
kubectl create secret generic tls-secret \
  --from-file=tls.crt=cert.pem \
  --from-file=tls.key=key.pem
```

**Utilisation** :
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
  - name: app
    image: myapp
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: password
```

**Types de Secrets** :
- **Opaque** : Données arbitraires (par défaut)
- **kubernetes.io/tls** : Certificats TLS
- **kubernetes.io/dockerconfigjson** : Credentials pour registry Docker
- **kubernetes.io/service-account-token** : Token de service account

**ATTENTION** : base64 ≠ chiffrement ! Solutions pour secrets sécurisés :
- **Sealed Secrets** (Bitnami)
- **External Secrets Operator**
- **HashiCorp Vault**
- **AWS Secrets Manager** / **Azure Key Vault** / **GCP Secret Manager**

---

## 6. Identité et Permissions

### **ServiceAccount**
**Définition** : Identité pour les pods qui leur permet d'interagir avec l'API Kubernetes.

**Caractéristiques** :
- Chaque namespace a un ServiceAccount "default"
- Token JWT monté automatiquement dans les pods
- Utilisé avec RBAC pour les permissions

**Exemple** :
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  namespace: production
```

**Utilisation** :
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  serviceAccountName: app-sa
  containers:
  - name: app
    image: myapp
```

---

### **Role**
**Définition** : Ensemble de permissions dans un namespace spécifique (RBAC).

**Exemple** :
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```

---

### **ClusterRole**
**Définition** : Comme Role mais pour tout le cluster (pas limité à un namespace).

**Exemple** :
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: secret-reader
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
```

---

### **RoleBinding**
**Définition** : Lie un Role à des utilisateurs, groupes ou ServiceAccounts dans un namespace.

**Exemple** :
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: production
subjects:
- kind: ServiceAccount
  name: app-sa
  namespace: production
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

---

### **ClusterRoleBinding**
**Définition** : Lie un ClusterRole au niveau du cluster entier.

---

## 7. Organisation et Isolation

### **Namespace**
**Définition** : Séparation virtuelle des ressources dans un cluster. Permet l'isolation et l'organisation.

**Caractéristiques** :
- Isolation logique (pas physique)
- Quotas de ressources par namespace
- Politiques réseau par namespace
- RBAC par namespace

**Namespaces par défaut** :
- **default** : Namespace par défaut (à éviter en production)
- **kube-system** : Composants système Kubernetes
- **kube-public** : Ressources publiques
- **kube-node-lease** : Heartbeat des nodes

**Exemple** :
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    env: prod
```

**Commandes** :
```bash
# Créer un namespace
kubectl create namespace dev

# Lister les namespaces
kubectl get namespaces

# Travailler dans un namespace
kubectl config set-context --current --namespace=dev

# Lister les ressources dans un namespace
kubectl get pods -n production

# Lister dans tous les namespaces
kubectl get pods -A
```

**Cas d'usage** :
- **Environnements** : dev, test, staging, prod
- **Équipes** : team-frontend, team-backend, team-data
- **Applications** : app1, app2, monitoring
- **Clients** : client-a, client-b (multi-tenant)

---

### **ResourceQuota**
**Définition** : Limite les ressources consommables dans un namespace.

**Exemple** :
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: dev
spec:
  hard:
    requests.cpu: "10"
    requests.memory: 20Gi
    limits.cpu: "20"
    limits.memory: 40Gi
    pods: "50"
    services: "10"
    persistentvolumeclaims: "20"
```

---

### **LimitRange**
**Définition** : Définit les contraintes min/max de ressources pour les pods/conteneurs dans un namespace.

**Exemple** :
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: resource-limits
  namespace: dev
spec:
  limits:
  - max:
      cpu: "2"
      memory: 4Gi
    min:
      cpu: "100m"
      memory: 128Mi
    default:
      cpu: "500m"
      memory: 512Mi
    defaultRequest:
      cpu: "200m"
      memory: 256Mi
    type: Container
```

---

## 8. Observabilité et Debugging

### **Labels**
**Définition** : Paires clé-valeur attachées aux objets pour l'identification et la sélection.

**Caractéristiques** :
- Utilisés par les sélecteurs (Services, Deployments)
- Queryable avec `kubectl get -l`
- Conventions : app, version, environment, tier

**Exemple** :
```yaml
metadata:
  labels:
    app: frontend
    version: v1.2.0
    environment: production
    tier: web
```

**Sélecteurs** :
```bash
# Égalité
kubectl get pods -l app=frontend

# Ensemble
kubectl get pods -l 'environment in (production,staging)'

# Plusieurs conditions
kubectl get pods -l app=frontend,version=v1.2.0
```

---

### **Annotations**
**Définition** : Métadonnées attachées aux objets, non utilisées pour la sélection.

**Caractéristiques** :
- Informations arbitraires
- Utilisées par les outils et controllers
- Pas de limite de taille (contrairement aux labels)

**Exemple** :
```yaml
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    description: "Application frontend pour le site e-commerce"
    contact: "team-frontend@example.com"
    created-by: "jenkins-pipeline"
```

---

### **Probes (Sondes)**

#### **Liveness Probe**
**Définition** : Vérifie si le conteneur est en vie. Si échoue, Kubernetes redémarre le conteneur.

**Exemple** :
```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3
```

#### **Readiness Probe**
**Définition** : Vérifie si le conteneur est prêt à recevoir du trafic. Si échoue, retire le pod du Service.

**Exemple** :
```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5
```

#### **Startup Probe**
**Définition** : Vérifie si l'application a démarré (pour applications lentes au démarrage).

**Exemple** :
```yaml
startupProbe:
  httpGet:
    path: /startup
    port: 8080
  initialDelaySeconds: 0
  periodSeconds: 10
  failureThreshold: 30  # 5 minutes max
```

**Types de probes** :
- **httpGet** : Requête HTTP GET
- **tcpSocket** : Connexion TCP
- **exec** : Commande dans le conteneur

---

## 9. Gestion des ressources

### **Requests et Limits**
**Définition** : Spécifient les ressources CPU/mémoire demandées et maximales pour un conteneur.

**Exemple** :
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"      # 0.25 CPU
  limits:
    memory: "512Mi"
    cpu: "500m"      # 0.5 CPU
```

**Différence** :
- **Requests** : Garantie minimale (utilisée pour le scheduling)
- **Limits** : Maximum absolu (throttling/kill si dépassé)

**Unités** :
- **CPU** :
  - `1` = 1 CPU core
  - `1000m` = 1 CPU (millicores)
  - `500m` = 0.5 CPU
- **Mémoire** :
  - `Ki`, `Mi`, `Gi` (puissances de 1024)
  - `K`, `M`, `G` (puissances de 1000)

---

### **HorizontalPodAutoscaler (HPA)**
**Définition** : Scale automatiquement le nombre de pods basé sur l'utilisation CPU/mémoire ou métriques custom.

**Exemple** :
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: webapp-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: webapp
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

---

### **VerticalPodAutoscaler (VPA)**
**Définition** : Ajuste automatiquement les requests/limits CPU/mémoire des conteneurs.

---

## 10. Outils et Commandes

### **kubectl**
CLI principal pour interagir avec Kubernetes.

**Commandes essentielles** :
```bash
# Créer/Appliquer
kubectl apply -f manifest.yaml
kubectl create deployment nginx --image=nginx

# Lire
kubectl get pods
kubectl get pods -o wide
kubectl get pods -n production
kubectl get all -A
kubectl describe pod my-pod
kubectl logs my-pod
kubectl logs -f my-pod --tail=100

# Modifier
kubectl edit deployment webapp
kubectl scale deployment webapp --replicas=5
kubectl set image deployment/webapp app=myapp:v2

# Supprimer
kubectl delete pod my-pod
kubectl delete -f manifest.yaml
kubectl delete deployment webapp

# Debug
kubectl exec -it my-pod -- /bin/bash
kubectl port-forward pod/my-pod 8080:80
kubectl top nodes
kubectl top pods

# Configuration
kubectl config view
kubectl config get-contexts
kubectl config use-context minikube
kubectl config set-context --current --namespace=dev
```

---

## Résumé des analogies

| Concept Kubernetes | Analogie |
|-------------------|----------|
| **Cluster** | Datacenter complet |
| **Node** | Serveur physique |
| **Pod** | Appartement (conteneurs = colocataires) |
| **Deployment** | Gestionnaire de flotte de véhicules |
| **ReplicaSet** | Règle "toujours avoir X taxis disponibles" |
| **Service** | Numéro de téléphone fixe (IP stable) |
| **Ingress** | Réceptionniste qui oriente les visiteurs |
| **ConfigMap** | Tableau d'affichage avec configuration |
| **Secret** | Coffre-fort pour données sensibles |
| **Namespace** | Département dans une entreprise |
| **PersistentVolume** | Disque dur externe |
| **PersistentVolumeClaim** | Demande de location de stockage |
| **StorageClass** | Type de stockage (SSD, HDD) |

---

## Workflows typiques

### Déployer une application web

```bash
# 1. Créer un namespace
kubectl create namespace webapp

# 2. Créer le Deployment
kubectl apply -f deployment.yaml

# 3. Exposer avec un Service
kubectl expose deployment webapp --type=ClusterIP --port=80

# 4. Créer un Ingress pour l'accès externe
kubectl apply -f ingress.yaml

# 5. Vérifier
kubectl get all -n webapp
kubectl get ingress -n webapp
```

### Mettre à jour une application

```bash
# Rolling update
kubectl set image deployment/webapp app=myapp:v2

# Vérifier le rollout
kubectl rollout status deployment/webapp

# Rollback si problème
kubectl rollout undo deployment/webapp
```

### Débugger un pod qui ne démarre pas

```bash
# 1. Voir l'état
kubectl get pods

# 2. Description détaillée
kubectl describe pod my-pod

# 3. Voir les logs
kubectl logs my-pod

# 4. Logs du conteneur précédent (si restart)
kubectl logs my-pod --previous

# 5. Entrer dans le pod (si running)
kubectl exec -it my-pod -- /bin/bash

# 6. Vérifier les events
kubectl get events --sort-by='.lastTimestamp'
```

---

## Ressources complémentaires

- **Documentation officielle** : https://kubernetes.io/docs/
- **Kubectl Cheat Sheet** : https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- **API Reference** : https://kubernetes.io/docs/reference/kubernetes-api/
- **Playground interactif** : https://labs.play-with-k8s.com/
- **Katacoda scenarios** : https://www.katacoda.com/courses/kubernetes

---

**Dernière mise à jour** : 2025-10-22
**Auteur** : Charles SIEPEN - IUT Ifs - R5.09
