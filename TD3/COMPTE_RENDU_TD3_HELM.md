# Compte-Rendu TD3 - Helm : Gestionnaire de Package pour Kubernetes

**Date :** 2025-11-11
**Étudiant :** [Votre Nom]
**Objectif :** Découvrir et maîtriser Helm pour packager et déployer des applications Kubernetes

---

## Table des matières

1. [Présentation de Helm](#1-présentation-de-helm)
2. [Exercice 1 : À la découverte de Helm](#2-exercice-1--à-la-découverte-de-helm)
3. [Exercice 2 : Améliorer la modularité](#3-exercice-2--améliorer-la-modularité-dun-chart)
4. [Exercice 3 : Variabilisation](#4-exercice-3--variabilisation-dun-chart)
5. [Exercice 4 : Éviter la redondance](#5-exercice-4--éviter-la-redondance-avec-helpers)
6. [Bilan et Conclusion](#6-bilan-et-conclusion)

---

## 1. Présentation de Helm

### 1.1 Qu'est-ce que Helm ?

**Helm** est un gestionnaire de packages pour Kubernetes, comparable à :
- **apt/yum** pour Linux
- **npm** pour Node.js
- **pip** pour Python

### 1.2 Concepts clés

| Concept | Description |
|---------|-------------|
| **Chart** | Package contenant tous les fichiers nécessaires pour déployer une application Kubernetes |
| **Release** | Instance d'un chart déployé dans un cluster (possède un nom unique) |
| **Repository** | Registre pour stocker et partager des charts |
| **Templates** | Fichiers de manifestes Kubernetes avec variables dynamiques |
| **Values** | Fichier contenant les valeurs des variables utilisées dans les templates |

### 1.3 Structure d'un Chart

```
mon-chart/
├── charts/          # Charts dépendants
├── templates/       # Modèles de manifestes Kubernetes
├── Chart.yaml       # Métadonnées du chart (nom, version, description)
└── values.yaml      # Valeurs par défaut des variables
```

### 1.4 Avantages de Helm

-  **Reproductibilité** : Déploiement identique sur différents environnements
-  **Gestion de versions** : Suivi de l'évolution des déploiements
-  **Paramétrage** : Configuration flexible via variables
-  **Modularité** : Réutilisation de charts via dépendances
-  **IaC** : Infrastructure as Code
-  **CI/CD** : Intégration dans les pipelines d'automatisation

---

## 2. Exercice 1 : À la découverte de Helm

### 2.1 Installation de Helm

**Méthode 1 : Script officiel**
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

**Méthode 2 : Installation manuelle (sans sudo)**
```bash
cd /tmp
wget https://get.helm.sh/helm-v3.19.0-linux-amd64.tar.gz
tar -zxvf helm-v3.19.0-linux-amd64.tar.gz
mkdir -p ~/.local/bin
mv linux-amd64/helm ~/.local/bin/
export PATH=$PATH:~/.local/bin
```

**Vérification de l'installation :**
```bash
helm version
# version.BuildInfo{Version:"v3.19.0", GitCommit:"...", GoVersion:"go1.24.7"}
```

### 2.2 Création du Chart vs-code-chart

#### 2.2.1 Structure du projet

```bash
mkdir -p ~/TD3/vs-code-chart/templates
cd ~/TD3/vs-code-chart
```

#### 2.2.2 Fichier Chart.yaml

**Fichier :** [Chart.yaml](vs-code-chart/Chart.yaml)

```yaml
apiVersion: v2
name: vs-code-chart
description: A Helm chart for my application
version: 0.1
```

**Explications :**
- `apiVersion: v2` : Version de l'API Helm (v2 pour Helm 3)
- `name` : Nom du chart (doit correspondre au nom du répertoire)
- `description` : Description du chart
- `version` : Version du chart (sémantique : MAJOR.MINOR.PATCH)

#### 2.2.3 Récupération des manifestes du TP2

Pour cet exercice, nous réutilisons les manifestes Kubernetes créés lors du TP2 :
- Deployment
- Service
- Ingress
- PersistentVolumeClaim
- Secrets/ConfigMaps

**Commandes pour copier les fichiers :**
```bash
# Copier les manifestes du TP2 dans le dossier templates/
cp ~/TP2/deployment.yaml ~/TD3/vs-code-chart/templates/
cp ~/TP2/service.yaml ~/TD3/vs-code-chart/templates/
cp ~/TP2/ingress.yaml ~/TD3/vs-code-chart/templates/
cp ~/TP2/pvc.yaml ~/TD3/vs-code-chart/templates/
```

#### 2.2.4 Exemple de manifestes

**templates/deployment.yaml**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: code-server
  labels:
    app: code-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: code-server
  template:
    metadata:
      labels:
        app: code-server
    spec:
      containers:
      - name: code-server
        image: codercom/code-server:latest
        ports:
        - containerPort: 8080
        volumeMounts:
        - name: data
          mountPath: /home/coder
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: code-server-pvc
```

**templates/service.yaml**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: code-server
  labels:
    app: code-server
spec:
  type: ClusterIP
  ports:
  - port: 8080
    targetPort: 8080
    protocol: TCP
  selector:
    app: code-server
```

**templates/ingress.yaml**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: code-server
  labels:
    app: code-server
spec:
  ingressClassName: nginx
  rules:
  - host: code-server.local
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

**templates/pvc.yaml**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: code-server-pvc
  labels:
    app: code-server
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

### 2.3 Package du Chart

**Commande :**
```bash
cd ~/TD3
helm package vs-code-chart
```

**Résultat attendu :**
```
Successfully packaged chart and saved it to: /home/user/TD3/vs-code-chart-0.1.tgz
```

**Explications :**
- Cette commande crée une archive `.tgz` du chart
- L'archive contient tous les fichiers du chart compressés
- Le nom du fichier suit le format : `<nom-chart>-<version>.tgz`
- Cette archive peut être partagée, stockée dans un registre, ou déployée

### 2.4 Déploiement du Chart

#### 2.4.1 Création du namespace

```bash
kubectl create namespace td3
```

#### 2.4.2 Déploiement avec helm upgrade

**Commande :**
```bash
helm upgrade --install vs-code-release vs-code-chart --namespace td3 --create-namespace
```

**Options expliquées :**
- `upgrade --install` : Installe ou met à jour la release (alias: `helm install` pour première installation)
- `vs-code-release` : Nom de la release dans le cluster
- `vs-code-chart` : Chemin vers le chart (dossier ou archive .tgz)
- `--namespace td3` : Namespace de déploiement
- `--create-namespace` : Crée le namespace s'il n'existe pas

**Résultat attendu :**
```
Release "vs-code-release" does not exist. Installing it now.
NAME: vs-code-release
LAST DEPLOYED: 2025-11-11 20:30:00
NAMESPACE: td3
STATUS: deployed
REVISION: 1
```

#### 2.4.3 Vérification du déploiement

**Lister les releases :**
```bash
helm list --namespace td3
```

**Sortie :**
```
NAME              NAMESPACE  REVISION  UPDATED                                STATUS     CHART              APP VERSION
vs-code-release   td3        1         2025-11-11 20:30:00 +0100 CET         deployed   vs-code-chart-0.1
```

**Voir le statut détaillé :**
```bash
helm status vs-code-release --namespace td3
```

**Vérifier les ressources Kubernetes :**
```bash
kubectl get all,pvc,ingress -n td3
```

**Sortie attendue :**
```
NAME                              READY   STATUS    RESTARTS   AGE
pod/code-server-xxxxxxxxx-xxxxx   1/1     Running   0          2m

NAME                  TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/code-server   ClusterIP   10.96.xxx.xxx   <none>        8080/TCP   2m

NAME                          READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/code-server   1/1     1            1           2m

NAME                          CLASS   HOSTS                 ADDRESS     PORTS   AGE
ingress/code-server           nginx   code-server.local     localhost   80      2m

NAME                                      STATUS   VOLUME                                     CAPACITY   ACCESS MODES   AGE
persistentvolumeclaim/code-server-pvc     Bound    pvc-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx   1Gi        RWO            2m
```

### 2.5 Commandes Helm utiles

```bash
# Voir l'historique des révisions
helm history vs-code-release -n td3

# Obtenir les valeurs utilisées pour une release
helm get values vs-code-release -n td3

# Obtenir les manifestes déployés
helm get manifest vs-code-release -n td3

# Désinstaller une release
helm uninstall vs-code-release -n td3

# Rollback vers une révision précédente
helm rollback vs-code-release 1 -n td3
```

---

## 3. Exercice 2 : Améliorer la modularité d'un chart

### 3.1 Objectif

Séparer les ressources de stockage (PVC) dans un **chart dépendant** pour améliorer la réutilisabilité et la séparation des responsabilités.

### 3.2 Pourquoi utiliser des dépendances ?

**Avantages :**
- ✅ Réutilisabilité : Le chart de stockage peut servir à d'autres applications
- ✅ Maintenance : Modification du stockage sans toucher au chart principal
- ✅ Versioning : Versions indépendantes des charts
- ✅ Modularité : Séparation claire des responsabilités

### 3.3 Création du chart dépendant

#### 3.3.1 Structure

```bash
mkdir -p ~/TD3/storage-chart/templates
cd ~/TD3/storage-chart
```

#### 3.3.2 Chart.yaml du chart de stockage

**Fichier :** [storage-chart/Chart.yaml](storage-chart/Chart.yaml)

```yaml
apiVersion: v2
name: storage-chart
description: Chart for storage resources
version: 0.1
```

#### 3.3.3 Déplacer le PVC

**Fichier :** [storage-chart/templates/pvc.yaml](storage-chart/templates/pvc.yaml)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: code-server-pvc
  labels:
    app: code-server
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

### 3.4 Packager le chart de stockage

```bash
cd ~/TD3
helm package storage-chart
```

**Résultat :**
```
Successfully packaged chart and saved it to: /home/user/TD3/storage-chart-0.1.tgz
```

### 3.5 Mise à jour du chart principal

#### 3.5.1 Nouveau Chart.yaml avec dépendance

**Fichier :** [vs-code-chart/Chart.yaml](vs-code-chart/Chart.yaml)

```yaml
apiVersion: v2
name: vs-code-chart
description: A Helm chart for my application
version: 0.2
dependencies:
  - name: storage-chart
    version: 0.1
    repository: "file://../storage-chart-0.1.tgz"
```

**Explications :**
- `version: 0.2` : Incrément de version du chart principal (bonne pratique)
- `dependencies` : Liste des charts dont dépend ce chart
  - `name` : Nom du chart dépendant
  - `version` : Version requise
  - `repository` : Emplacement du chart (peut être `file://`, `http://`, ou un repo Helm)

#### 3.5.2 Supprimer le PVC du chart principal

```bash
rm ~/TD3/vs-code-chart/templates/pvc.yaml
```

#### 3.5.3 Télécharger les dépendances

```bash
cd ~/TD3/vs-code-chart
helm dependency update
```

**Résultat :**
```
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈Happy Helming!⎈
Saving 1 charts
Downloading storage-chart from repo file://../storage-chart-0.1.tgz
Deleting outdated charts
```

**Cette commande :**
- Télécharge les charts dépendants
- Les place dans le dossier `charts/`
- Crée un fichier `Chart.lock` pour verrouiller les versions

### 3.6 Package et déploiement de la nouvelle version

```bash
cd ~/TD3
helm package vs-code-chart
```

**Déploiement :**
```bash
helm upgrade vs-code-release vs-code-chart --namespace td3
```

**Résultat :**
```
Release "vs-code-release" has been upgraded. Happy Helming!
NAME: vs-code-release
LAST DEPLOYED: 2025-11-11 20:45:00
NAMESPACE: td3
STATUS: deployed
REVISION: 2
```

### 3.7 Vérification

**Q : Constatez-vous un changement sur votre cluster ?**

**Commandes de vérification :**
```bash
helm status vs-code-release -n td3
helm list -n td3
kubectl get pvc -n td3
```

**Réponse :**

**OUI, mais subtil :**
- La révision est passée de 1 à 2
- Le PVC existe toujours car :
  - Helm ne supprime pas les PVC existants par défaut (protection des données)
  - Le PVC provient maintenant du chart dépendant
- Les autres ressources (Deployment, Service, Ingress) sont inchangées

**Vérification de la dépendance :**
```bash
helm get manifest vs-code-release -n td3 | grep -A 5 "kind: PersistentVolumeClaim"
```

On peut voir que le PVC est maintenant géré par le sous-chart `storage-chart`.

---

## 4. Exercice 3 : Variabilisation d'un Chart

### 4.1 Objectif

Rendre le chart **paramétrable** pour permettre des déploiements flexibles selon les environnements (dev, staging, prod).

### 4.2 Identification des valeurs à variabiliser

**Valeurs candidates :**

| Valeur | Pourquoi variabiliser ? |
|--------|-------------------------|
| **Image** | Différentes versions selon l'environnement |
| **Replicas** | Plus de réplicas en production |
| **Ressources (CPU/RAM)** | Ajustement selon l'environnement |
| **Hostname Ingress** | URLs différentes par environnement |
| **Taille du stockage** | Capacité variable |
| **Labels** | Identification et organisation |

### 4.3 Création du fichier values.yaml

**Fichier :** [vs-code-chart/values.yaml](vs-code-chart/values.yaml)

```yaml
# Configuration de l'application
app:
  name: code-server
  replicas: 1

# Configuration de l'image
image:
  repository: codercom/code-server
  tag: latest
  pullPolicy: IfNotPresent

# Configuration des ressources
resources:
  limits:
    cpu: "1000m"
    memory: "1Gi"
  requests:
    cpu: "500m"
    memory: "512Mi"

# Configuration du service
service:
  type: ClusterIP
  port: 8080
  targetPort: 8080

# Configuration de l'ingress
ingress:
  enabled: true
  className: nginx
  host: code-server.local
  path: /
  pathType: Prefix

# Configuration du stockage (pour le chart dépendant)
storage:
  size: 1Gi
  accessMode: ReadWriteOnce
```

### 4.4 Mise à jour des templates avec les variables

#### 4.4.1 Syntaxe des variables Helm

**Format :**
```yaml
{{ .Values.cle.de.ma.variable }}
```

**Exemple :**
```yaml
replicas: {{ .Values.app.replicas }}
```

#### 4.4.2 Template du Deployment

**Fichier :** [vs-code-chart/templates/deployment.yaml](vs-code-chart/templates/deployment.yaml)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.app.name }}
  labels:
    app: {{ .Values.app.name }}
spec:
  replicas: {{ .Values.app.replicas }}
  selector:
    matchLabels:
      app: {{ .Values.app.name }}
  template:
    metadata:
      labels:
        app: {{ .Values.app.name }}
    spec:
      containers:
      - name: {{ .Values.app.name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - containerPort: {{ .Values.service.targetPort }}
        resources:
          limits:
            cpu: {{ .Values.resources.limits.cpu }}
            memory: {{ .Values.resources.limits.memory }}
          requests:
            cpu: {{ .Values.resources.requests.cpu }}
            memory: {{ .Values.resources.requests.memory }}
        volumeMounts:
        - name: data
          mountPath: /home/coder
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: {{ .Values.app.name }}-pvc
```

#### 4.4.3 Template du Service

**Fichier :** [vs-code-chart/templates/service.yaml](vs-code-chart/templates/service.yaml)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.app.name }}
  labels:
    app: {{ .Values.app.name }}
spec:
  type: {{ .Values.service.type }}
  ports:
  - port: {{ .Values.service.port }}
    targetPort: {{ .Values.service.targetPort }}
    protocol: TCP
  selector:
    app: {{ .Values.app.name }}
```

#### 4.4.4 Template de l'Ingress avec condition

**Fichier :** [vs-code-chart/templates/ingress.yaml](vs-code-chart/templates/ingress.yaml)

```yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Values.app.name }}
  labels:
    app: {{ .Values.app.name }}
spec:
  ingressClassName: {{ .Values.ingress.className }}
  rules:
  - host: {{ .Values.ingress.host }}
    http:
      paths:
      - path: {{ .Values.ingress.path }}
        pathType: {{ .Values.ingress.pathType }}
        backend:
          service:
            name: {{ .Values.app.name }}
            port:
              number: {{ .Values.service.port }}
{{- end }}
```

**Note :** `{{- if .Values.ingress.enabled }}` permet de rendre l'Ingress optionnel.

#### 4.4.5 Mise à jour du chart de stockage

**Fichier :** [storage-chart/values.yaml](storage-chart/values.yaml)

```yaml
storage:
  size: 1Gi
  accessMode: ReadWriteOnce
  appName: code-server
```

**Fichier :** [storage-chart/templates/pvc.yaml](storage-chart/templates/pvc.yaml)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ .Values.storage.appName }}-pvc
  labels:
    app: {{ .Values.storage.appName }}
spec:
  accessModes:
  - {{ .Values.storage.accessMode }}
  resources:
    requests:
      storage: {{ .Values.storage.size }}
```

### 4.5 Mise à jour de Chart.yaml

```yaml
apiVersion: v2
name: vs-code-chart
description: A Helm chart for my application
version: 0.3
dependencies:
  - name: storage-chart
    version: 0.1
    repository: "file://../storage-chart-0.1.tgz"
```

### 4.6 Test du templating

**Commande pour prévisualiser les manifestes sans déployer :**
```bash
helm template vs-code-release vs-code-chart --namespace td3
```

**Cette commande affiche les manifestes générés avec les valeurs du fichier `values.yaml`.**

### 4.7 Déploiement avec surcharge de valeurs

#### 4.7.1 Méthode 1 : Fichier values personnalisé

**Fichier :** [values-prod.yaml](values-prod.yaml)

```yaml
app:
  replicas: 3

resources:
  limits:
    cpu: "2000m"
    memory: "2Gi"
  requests:
    cpu: "1000m"
    memory: "1Gi"

ingress:
  host: code-server-prod.example.com

storage:
  size: 10Gi
```

**Déploiement :**
```bash
helm upgrade vs-code-release vs-code-chart \
  --namespace td3 \
  -f values-prod.yaml
```

#### 4.7.2 Méthode 2 : Option --set en ligne de commande

```bash
helm upgrade vs-code-release vs-code-chart \
  --namespace td3 \
  --set app.replicas=2 \
  --set ingress.host=code-server-staging.local \
  --set storage.size=5Gi
```

**Priorité des valeurs :**
1. `--set` (plus haute priorité)
2. `-f custom-values.yaml`
3. `values.yaml` du chart (défaut)

### 4.8 Vérification du déploiement

```bash
helm get values vs-code-release -n td3
kubectl get deployment code-server -n td3 -o yaml | grep replicas
kubectl get pvc -n td3
kubectl get ingress -n td3
```

---

## 5. Exercice 4 : Éviter la redondance avec helpers

### 5.1 Problématique

Les labels `app: code-server` sont répétés partout. En environnement partagé, il faut des labels plus discriminants :
- Organisation : `orga: IUT-C3`
- Ressource : `res: R5-09`
- Nom de l'app : `app: code-server`

**Sans helpers**, il faudrait ajouter ces 3 labels dans **chaque fichier** → **redondance !**

### 5.2 Solution : Fichier _helpers.tpl

Le fichier `_helpers.tpl` permet de définir des **fonctions réutilisables** (templates nommés).

### 5.3 Création du chart common-chart

#### 5.3.1 Structure

```bash
mkdir -p ~/TD3/common-chart/templates
cd ~/TD3/common-chart
```

#### 5.3.2 Chart.yaml

**Fichier :** [common-chart/Chart.yaml](common-chart/Chart.yaml)

```yaml
apiVersion: v2
name: common-chart
description: Common templates and helpers for all charts
version: 0.1
```

#### 5.3.3 Fichier _helpers.tpl

**Fichier :** [common-chart/templates/_helpers.tpl](common-chart/templates/_helpers.tpl)

```yaml
{{- define "common-chart.labels" -}}
orga: "IUT-C3"
res: "R5-09"
app: {{ .Values.app.name | default "app" }}
release: {{ .Release.Name }}
{{- end }}

{{- define "common-chart.selectorLabels" -}}
app: {{ .Values.app.name | default "app" }}
release: {{ .Release.Name }}
{{- end }}
```

**Explications :**
- `{{- define "nom-fonction" -}}` : Définit une fonction réutilisable
- `.Values.app.name` : Accède aux valeurs du chart
- `.Release.Name` : Nom de la release Helm
- `| default "app"` : Valeur par défaut si `.Values.app.name` n'existe pas
- `{{- end }}` : Fin de la définition

### 5.4 Packager common-chart

```bash
cd ~/TD3
helm package common-chart
```

**Résultat :**
```
Successfully packaged chart and saved it to: /home/user/TD3/common-chart-0.1.tgz
```

### 5.5 Ajouter common-chart comme dépendance

**Fichier :** [vs-code-chart/Chart.yaml](vs-code-chart/Chart.yaml)

```yaml
apiVersion: v2
name: vs-code-chart
description: A Helm chart for my application
version: 0.4
dependencies:
  - name: storage-chart
    version: 0.1
    repository: "file://../storage-chart-0.1.tgz"
  - name: common-chart
    version: 0.1
    repository: "file://../common-chart-0.1.tgz"
```

**Télécharger les dépendances :**
```bash
cd ~/TD3/vs-code-chart
helm dependency update
```

### 5.6 Utilisation des helpers dans les templates

#### 5.6.1 Template du Deployment

**Fichier :** [vs-code-chart/templates/deployment.yaml](vs-code-chart/templates/deployment.yaml)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.app.name }}
  labels:
    {{- template "common-chart.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.app.replicas }}
  selector:
    matchLabels:
      {{- template "common-chart.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- template "common-chart.labels" . | nindent 8 }}
    spec:
      containers:
      - name: {{ .Values.app.name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - containerPort: {{ .Values.service.targetPort }}
        resources:
          limits:
            cpu: {{ .Values.resources.limits.cpu }}
            memory: {{ .Values.resources.limits.memory }}
          requests:
            cpu: {{ .Values.resources.requests.cpu }}
            memory: {{ .Values.resources.requests.memory }}
        volumeMounts:
        - name: data
          mountPath: /home/coder
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: {{ .Values.app.name }}-pvc
```

**Explications :**
- `{{- template "common-chart.labels" . }}` : Appelle la fonction définie dans `_helpers.tpl`
  - Le `.` à la fin passe le contexte actuel à la fonction
- `| nindent 4` : Indentation de 4 espaces pour respecter la syntaxe YAML

#### 5.6.2 Template du Service

**Fichier :** [vs-code-chart/templates/service.yaml](vs-code-chart/templates/service.yaml)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.app.name }}
  labels:
    {{- template "common-chart.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
  - port: {{ .Values.service.port }}
    targetPort: {{ .Values.service.targetPort }}
    protocol: TCP
  selector:
    {{- template "common-chart.selectorLabels" . | nindent 4 }}
```

#### 5.6.3 Template de l'Ingress

**Fichier :** [vs-code-chart/templates/ingress.yaml](vs-code-chart/templates/ingress.yaml)

```yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Values.app.name }}
  labels:
    {{- template "common-chart.labels" . | nindent 4 }}
spec:
  ingressClassName: {{ .Values.ingress.className }}
  rules:
  - host: {{ .Values.ingress.host }}
    http:
      paths:
      - path: {{ .Values.ingress.path }}
        pathType: {{ .Values.ingress.pathType }}
        backend:
          service:
            name: {{ .Values.app.name }}
            port:
              number: {{ .Values.service.port }}
{{- end }}
```

### 5.7 Test et déploiement

**Prévisualisation :**
```bash
helm template vs-code-release vs-code-chart --namespace td3
```

**Vérifier que les labels apparaissent :**
```yaml
metadata:
  labels:
    orga: "IUT-C3"
    res: "R5-09"
    app: code-server
    release: vs-code-release
```

**Déploiement :**
```bash
cd ~/TD3
helm package vs-code-chart
helm upgrade vs-code-release vs-code-chart --namespace td3
```

**Vérification des labels :**
```bash
kubectl get deployment code-server -n td3 -o yaml | grep -A 5 labels
kubectl get pods -n td3 --show-labels
```

**Résultat attendu :**
```
NAME                           LABELS
code-server-xxxxxxxxx-xxxxx    app=code-server,orga=IUT-C3,release=vs-code-release,res=R5-09
```

---

## 6. Bilan et Conclusion

### 6.1 Concepts clés maîtrisés

✅ **Chart** : Package contenant tous les manifestes Kubernetes
✅ **Release** : Instance déployée d'un chart
✅ **Templates** : Manifestes avec variables dynamiques
✅ **Values** : Configuration paramétrable
✅ **Dépendances** : Modularité via charts réutilisables
✅ **Helpers** : Fonctions pour éviter la redondance

### 6.2 Commandes Helm essentielles

```bash
# Installation
helm install <release> <chart>

# Mise à jour (ou installation si n'existe pas)
helm upgrade --install <release> <chart>

# Liste des releases
helm list -n <namespace>

# Statut d'une release
helm status <release> -n <namespace>

# Historique
helm history <release> -n <namespace>

# Rollback
helm rollback <release> <revision> -n <namespace>

# Désinstallation
helm uninstall <release> -n <namespace>

# Prévisualisation
helm template <release> <chart>

# Package
helm package <chart>

# Téléchargement des dépendances
helm dependency update
```

### 6.3 Avantages de Helm

| Avantage | Description |
|----------|-------------|
| **Reproductibilité** | Déploiement identique sur dev/staging/prod |
| **Versioning** | Gestion de l'évolution des déploiements |
| **Rollback** | Retour à une version précédente en 1 commande |
| **Paramétrage** | Adaptation via variables sans modifier les templates |
| **Modularité** | Réutilisation de charts via dépendances |
| **IaC** | Infrastructure as Code → traçabilité, revue de code |
| **CI/CD** | Intégration dans les pipelines d'automatisation |
| **Communauté** | Artifact Hub : 10 000+ charts prêts à l'emploi |

### 6.4 Bonnes pratiques

✅ **Versioning sémantique** : MAJOR.MINOR.PATCH
✅ **Valeurs par défaut** : Toujours dans `values.yaml`
✅ **Documentation** : Commenter les valeurs importantes
✅ **Helpers** : Mutualiser les labels et sélecteurs
✅ **Conditions** : Rendre les ressources optionnelles (`if`)
✅ **Dépendances** : Séparer les responsabilités
✅ **Tests** : `helm template` avant déploiement
✅ **Lint** : `helm lint <chart>` pour valider la syntaxe

### 6.5 Cas d'usage avancés

#### 6.5.1 Hooks Helm

Les hooks permettent d'exécuter des actions à des moments précis du cycle de vie :

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Values.app.name }}-migration
  annotations:
    "helm.sh/hook": post-install,post-upgrade
    "helm.sh/hook-weight": "-5"
    "helm.sh/hook-delete-policy": hook-succeeded
spec:
  template:
    spec:
      containers:
      - name: migration
        image: migrate/migrate:latest
        command: ["migrate", "-path", "/migrations", "-database", "postgres://...", "up"]
      restartPolicy: Never
```

**Hooks disponibles :**
- `pre-install`, `post-install`
- `pre-upgrade`, `post-upgrade`
- `pre-delete`, `post-delete`
- `pre-rollback`, `post-rollback`

#### 6.5.2 Chart Repository

**Héberger ses charts :**

```bash
# Créer un repo local
mkdir helm-repo
mv *.tgz helm-repo/
helm repo index helm-repo/

# Ajouter le repo
helm repo add my-repo http://localhost:8080
helm repo update

# Installer depuis le repo
helm install my-release my-repo/vs-code-chart
```

**Repos publics :**
- Artifact Hub : https://artifacthub.io/
- Bitnami : https://charts.bitnami.com/bitnami
- Helm Stable (déprécié) : https://charts.helm.sh/stable

#### 6.5.3 Fonctions avancées du templating

```yaml
# Conditions
{{- if eq .Values.env "production" }}
replicas: 3
{{- else }}
replicas: 1
{{- end }}

# Boucles
{{- range .Values.databases }}
- name: {{ .name }}
  host: {{ .host }}
{{- end }}

# Fonctions de manipulation de chaînes
{{ .Values.app.name | upper }}           # CODE-SERVER
{{ .Values.app.name | quote }}           # "code-server"
{{ .Values.app.name | trunc 5 }}         # code-
{{ .Values.app.name | default "app" }}   # Valeur par défaut

# Fonctions de manipulation de listes
{{ .Values.tags | join "," }}            # tag1,tag2,tag3
```

### 6.6 Alternatives et compléments à Helm

| Outil | Description |
|-------|-------------|
| **Kustomize** | Gestion de configuration native Kubernetes (sans templating) |
| **ArgoCD** | GitOps pour déploiement continu (compatible Helm) |
| **Flux** | GitOps alternatif (compatible Helm) |
| **Helmfile** | Orchestration de multiples releases Helm |
| **Terraform** | IaC multi-cloud (provider Helm disponible) |

### 6.7 Synthèse de l'évolution du chart

| Version | Changements | Concepts introduits |
|---------|-------------|---------------------|
| **0.1** | Premier chart avec manifestes TP2 | Charts, Templates, Package |
| **0.2** | Ajout du chart de stockage | Dépendances, Modularité |
| **0.3** | Ajout de values.yaml | Variabilisation, Paramétrage |
| **0.4** | Ajout de common-chart avec helpers | Helpers, Réutilisabilité |

### 6.8 Points clés à retenir

🎯 **Helm = npm/apt pour Kubernetes**
📦 **Chart = Package réutilisable**
🚀 **Release = Instance déployée**
🔧 **Values = Configuration flexible**
🧩 **Dépendances = Modularité**
♻️ **Helpers = DRY (Don't Repeat Yourself)**
📊 **Versioning = Traçabilité**
🔄 **Rollback = Sécurité**

---

## Annexes

### A. Structure finale du projet

```
TD3/
├── common-chart/
│   ├── Chart.yaml
│   └── templates/
│       └── _helpers.tpl
│
├── storage-chart/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       └── pvc.yaml
│
├── vs-code-chart/
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── charts/                    # Généré par helm dependency update
│   │   ├── common-chart-0.1.tgz
│   │   └── storage-chart-0.1.tgz
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       └── ingress.yaml
│
├── common-chart-0.1.tgz          # Archives packagées
├── storage-chart-0.1.tgz
└── vs-code-chart-0.4.tgz
```

### B. Ressources utiles

**Documentation officielle :**
- https://helm.sh/docs/
- https://helm.sh/docs/chart_template_guide/
- https://helm.sh/docs/chart_best_practices/

**Charts publics :**
- https://artifacthub.io/
- https://github.com/helm/charts (archive)

**Tutoriels :**
- https://helm.sh/docs/intro/quickstart/
- https://helm.sh/docs/howto/charts_tips_and_tricks/

**Fonctions de templating :**
- https://helm.sh/docs/chart_template_guide/function_list/
- https://masterminds.github.io/sprig/ (librairie Sprig)

### C. Troubleshooting

**Problème : Erreur de syntaxe YAML**
```bash
# Valider la syntaxe
helm lint vs-code-chart

# Afficher les manifestes générés
helm template test vs-code-chart
```

**Problème : Dépendances non trouvées**
```bash
# Mettre à jour les dépendances
helm dependency update vs-code-chart

# Vérifier le fichier Chart.lock
cat vs-code-chart/Chart.lock
```

**Problème : Release bloquée**
```bash
# Voir le statut
helm status <release> -n <namespace>

# Rollback
helm rollback <release> <revision> -n <namespace>

# Force delete
helm uninstall <release> -n <namespace> --no-hooks
```

**Problème : Différences entre environnements**
```bash
# Comparer les valeurs
helm get values <release> -n <namespace>
helm get values <release> -n <namespace> --all
```

---

**Fin du compte-rendu TD3**

**Date de réalisation :** 2025-11-11
**Outils utilisés :** Helm v3.19.0, Kubernetes v1.27.3, Kind
