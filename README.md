# R5.09 - Virtualisation Avancée
## IUT Grand Ouest Normandie - BUT Informatique Semestre 5

---

##  Vue d'ensemble

Ce dépôt contient l'ensemble des ressources pour le module **R5.09 - Virtualisation Avancée** :
- Templates VM préconfigurés (OVA et Proxmox)
- Projet GoTK8S (Game of Thrones Kubernetes)
- Solutions Docker/Minikube
- Matériel de cours (CM, TD, TP)
- Exemples et exercices

---

##  Projets Principaux

### 1. GoTK8S - Game of Thrones Kubernetes Scenarios

**Projet pédagogique complet** pour apprendre Kubernetes via des scénarios Game of Thrones.

📁 Dossier : [`GOK8S/`](GOK8S/)
📖 Guide : [`GOK8S/README.md`](GOK8S/README.md)

**Contenu** :
- Scénarios progressifs d'apprentissage
- 8 royaumes Kubernetes avec leurs propres services
- Challenges et exercices
- Guide enseignant et guide étudiant complets

**Pour commencer** :
```bash
cd GOK8S
# Lire le README pour les instructions complètes
```

---

### 2. Templates VM Préconfigurés

**Templates prêts à l'emploi** pour éviter les problèmes d'installation et se concentrer sur l'apprentissage.

📁 Dossier : [`templates-vm/`](templates-vm/)

#### Option A : OVA VirtualBox (Distribution facile) ⭐

Fichier OVA portable importable dans VirtualBox, VMware, ou Proxmox.

📖 Guide : [`templates-vm/ova-virtualbox/GUIDE-VIRTUALBOX-OVA.md`](templates-vm/ova-virtualbox/GUIDE-VIRTUALBOX-OVA.md)

**Contenu** :
- Ubuntu 22.04 + Kubernetes (Minikube, kubectl, Helm)
- Proxy 192.168.0.2:3128 préconfiguré
- Scripts de démarrage rapide
- Taille : 2-4 GB

**Utilisation** :
1. Télécharger le fichier `.ova`
2. Importer dans VirtualBox
3. Démarrer et se connecter (ubuntu/ubuntu)
4. Exécuter `start-k8s`

#### Option B : Template Proxmox (Production)

Template Proxmox pour infrastructure professionnelle.

📖 Guide : [`templates-vm/proxmox/GUIDE-PROXMOX.md`](templates-vm/proxmox/GUIDE-PROXMOX.md)

**Avantages** :
- Clone rapide de VMs
- Intégration native Proxmox
- Production-ready

---

### 3. Solution Docker/Minikube

**Environnement Docker** pour tests rapides en local.

📁 Dossier : [`docker-minikube/`](docker-minikube/)
📖 Guides :
- [`docker-minikube/docs/QUICKSTART.md`](docker-minikube/docs/QUICKSTART.md)
- [`docker-minikube/docs/TROUBLESHOOTING.md`](docker-minikube/docs/TROUBLESHOOTING.md)

**Utilisation** :
```bash
cd docker-minikube
./minikube-helper-v2.sh build
./minikube-helper-v2.sh start
./minikube-helper-v2.sh shell
```

⚠️ **Attention** : Nécessite 4-6 GB de RAM libre

---

## 📖 Matériel de Cours

### Structure

```
cours/
├── CM/     # Cours Magistraux (PDF)
├── TDs/    # Travaux Dirigés
├── TPs/    # Travaux Pratiques
└── CC/     # Contrôles Continus
```

### Par sujet

| Sujet | CM | TD | TP |
|-------|----|----|-----|
| Docker | ✅ | ✅ | ✅ |
| Kubernetes | ✅ | ✅ | ✅ |
| Helm | ✅ | ✅ | ✅ |
| Registries | ✅ | ✅ | ✅ |

---

## 📚 Travaux Pratiques Réalisés

### TP2 - Déploiement d'Applications Kubernetes

**Objectif** : Déployer deux applications complètes sur un cluster Kubernetes multi-control-plane avec Kind.

📁 Dossier : [`TP2/`](TP2/)
📖 Compte-rendu : [`TP2/COMPTE_RENDU_TP2.md`](TP2/COMPTE_RENDU_TP2.md)
📄 Guide rapide : [`TP2/README.md`](TP2/README.md)

**Architecture** :
- Cluster Kind : 2 control-planes + 1 worker (High Availability)
- Ingress-nginx avec nodeSelector automatisé (Kustomize)
- Déploiement VS Code Server (avec PVC et Sealed Secrets)
- Déploiement Guestbook PHP/Redis (architecture Leader/Followers)

**Technologies** :
- **Kind** (Kubernetes in Docker) - Multi-node cluster
- **Ingress-nginx** - Reverse proxy et routage HTTP/HTTPS
- **Kustomize** - Patching automatisé de manifests
- **Sealed Secrets** - Chiffrement GitOps-friendly des secrets
- **Redis** - Architecture Leader/Followers pour haute disponibilité

**Démarrage rapide** :
```bash
cd TP2
./setup-cluster.sh         # Création automatisée du cluster
kubectl apply -f vs_code/  # Déployer VS Code Server
kubectl apply -f guestbook/ # Déployer Guestbook
```

**Accès aux applications** :
- VS Code Server : http://localhost/code
- Guestbook : http://localhost/guestbook

**Points clés** :
- ✅ Troubleshooting ingress controller placement (nodeSelector fix)
- ✅ Gestion sécurisée des secrets avec Sealed Secrets
- ✅ Script d'installation automatisé avec Kustomize
- ✅ Stockage persistant avec PersistentVolumeClaim
- ✅ Architecture multi-tier (frontend, backend, base de données)

---

### TP3 - Autoscaling et Métriques Kubernetes

**Objectif** : Implémenter l'autoscaling horizontal (HPA) sur une application Node.js avec simulation de charge.

📁 Dossier : [`TP3/`](TP3/)
📖 Compte-rendu : [`TP3/COMPTE_RENDU_TP3.md`](TP3/COMPTE_RENDU_TP3.md)

**Architecture** :
- Application Node.js Express avec endpoint `/cpu` (charge CPU intensive)
- Metrics Server pour collecte des métriques cluster
- HorizontalPodAutoscaler (HPA) avec seuils configurables
- Générateur de charge busybox pour simulation

**Technologies** :
- **Metrics Server** - Collecte métriques CPU/RAM des pods
- **HPA** - Autoscaling basé sur métriques (CPU/mémoire)
- **Node.js/Express** - Application de test avec charge CPU
- **kubectl top** - Monitoring en temps réel des ressources

**Démarrage rapide** :
```bash
cd TP3
# Installer Metrics Server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Déployer l'application
kubectl apply -f express-deployment.yaml
kubectl apply -f express-service.yaml
kubectl apply -f express-hpa.yaml

# Générer de la charge
kubectl run -i --tty load-generator --rm --image=busybox:1.28 --restart=Never -- \
  /bin/sh -c "while sleep 0.01; do wget -q -O- http://express:8080/cpu; done"

# Observer l'autoscaling
kubectl get hpa -w
```

**Métriques et seuils** :
- **Seuil CPU** : 50% (autoscaling si dépassement)
- **Replicas min/max** : 1 à 10
- **Temps de montée** : ~2-3 minutes
- **Temps de descente** : ~5 minutes (stabilisation)

**Points clés** :
- ✅ Configuration HPA avec seuils CPU et mémoire
- ✅ Analyse du comportement de scaling (montée/descente)
- ✅ Monitoring avec `kubectl top` et `kubectl get hpa`
- ✅ Simulation de charge réaliste
- ✅ Compréhension des limites et requests Kubernetes

---

### TD3 - Helm Charts et Templating

**Objectif** : Créer et déployer une application web complète (Guestbook) avec Helm, comprendre le templating et la gestion de releases.

📁 Dossier : [`TD3/`](TD3/)
📖 Compte-rendu : [`TD3/COMPTE_RENDU_TD3.md`](TD3/COMPTE_RENDU_TD3.md)

**Architecture Helm** :
- Chart Guestbook avec Redis (leader + followers) et frontend PHP
- Templates Kubernetes paramétrables (Deployment, Service, ConfigMap)
- Values.yaml pour configuration centralisée
- Releases Helm avec versioning et rollback

**Technologies** :
- **Helm 3** - Package manager Kubernetes
- **Go templating** - Templating dynamique dans manifests
- **Chart versioning** - Gestion de versions d'applications
- **Values override** - Configuration par environnement

**Démarrage rapide** :
```bash
cd TD3

# Créer un nouveau chart
helm create mon-app

# Installer Guestbook
helm install guestbook ./guestbook-chart

# Upgrader avec nouvelles valeurs
helm upgrade guestbook ./guestbook-chart --set replicaCount=5

# Rollback si problème
helm rollback guestbook 1

# Lister les releases
helm list
```

**Structure d'un Chart** :
```
guestbook-chart/
├── Chart.yaml           # Métadonnées du chart
├── values.yaml          # Valeurs par défaut
├── templates/           # Templates Kubernetes
│   ├── deployment.yaml  # {{ .Values.replicaCount }}
│   ├── service.yaml     # {{ .Values.service.type }}
│   ├── configmap.yaml   # {{ .Values.redis.host }}
│   └── _helpers.tpl     # Fonctions réutilisables
└── charts/              # Dépendances (sous-charts)
```

**Fonctionnalités Helm** :
- ✅ Templating avec variables `{{ .Values.* }}`
- ✅ Fonctions Go : `{{ include "app.name" . }}`
- ✅ Conditionnels : `{{ if .Values.ingress.enabled }}`
- ✅ Boucles : `{{ range .Values.env }}`
- ✅ Gestion de releases et historique
- ✅ Hooks pour lifecycle events
- ✅ Dependencies entre charts

**Commandes essentielles** :
```bash
helm install <release> <chart>           # Installer
helm upgrade <release> <chart>           # Mettre à jour
helm rollback <release> <revision>       # Revenir en arrière
helm uninstall <release>                 # Désinstaller
helm list                                # Lister releases
helm history <release>                   # Historique
helm template <chart>                    # Preview YAML généré
helm lint <chart>                        # Valider syntaxe
```

**Points clés** :
- ✅ Création de charts Helm from scratch
- ✅ Templating avancé avec values et helpers
- ✅ Gestion du cycle de vie des applications
- ✅ Rollback et versioning de releases
- ✅ Configuration multi-environnement (dev, staging, prod)
- ✅ Best practices Helm (naming, labels, annotations)

---

## 🛠️ Exemples et Exercices

### Kubernetes

📁 [`exemples/kubernetes/`](exemples/kubernetes/)

- `hello-minikube.yaml` - Déploiement simple
- `nginx-deployment.yaml` - Nginx avec LoadBalancer
- `advanced-examples.yaml` - ConfigMap, Secrets, PVC, Ingress, CronJob, StatefulSet

### Docker

📁 [`exemples/docker/`](exemples/docker/)

- Exercices Dockerfile
- Rappels Docker
- Multi-stage builds

### Applications complètes

- **Nginx SSL** : [`exemples/nginx-ssl/`](exemples/nginx-ssl/)
- **Flask App** : [`exemples/flask-app/`](exemples/flask-app/)

---

## 🔧 Outils Utilitaires

📁 Dossier : [`outils/`](outils/)

### Scripts disponibles

| Script | Description |
|--------|-------------|
| `install-minikube-native.sh` | Installer Minikube sur votre système |
| `install-docker-compose-v2.sh` | Mettre à jour Docker Compose v2 |

**Utilisation** :
```bash
cd outils
./install-minikube-native.sh
```

---

## 🚀 Démarrage Rapide

### Pour les étudiants

#### Option 1 : Utiliser le template OVA (RECOMMANDÉ) ⭐

1. Télécharger le fichier `.ova` depuis [lien à fournir]
2. Importer dans VirtualBox
3. Démarrer la VM
4. Se connecter : `ubuntu` / `ubuntu`
5. Démarrer Kubernetes : `start-k8s`
6. Commencer les exercices : `cd ~/exemples/kubernetes/`

#### Option 2 : Installer Minikube localement

```bash
cd outils
./install-minikube-native.sh
minikube start
kubectl get nodes
```

#### Option 3 : Utiliser GoTK8S

```bash
cd GOK8S
# Suivre le guide étudiant
cat GUIDE_ETUDIANT.md
```

---

### Pour les enseignants

#### Créer les templates VM

**OVA VirtualBox** :
```bash
cd templates-vm/ova-virtualbox
# Suivre GUIDE-VIRTUALBOX-OVA.md
```

**Template Proxmox** :
```bash
cd templates-vm/proxmox
# Suivre GUIDE-PROXMOX.md
```

#### Déployer GoTK8S

```bash
cd GOK8S
# Suivre GUIDE_ENSEIGNANT.md
```

---

## 📋 Organisation du Dépôt

```
r509/
├── README.md                    ← Vous êtes ici
│
├── TP2/                         # TP2 - Déploiement Kubernetes
│   ├── COMPTE_RENDU_TP2.md     # Compte-rendu complet
│   ├── README.md                # Guide rapide
│   ├── cluster.yaml             # Configuration Kind cluster
│   ├── setup-cluster.sh         # Script installation automatisé
│   ├── ingress-kustomize/       # Kustomize pour ingress-nginx
│   ├── vs_code/                 # Manifests VS Code Server
│   │   ├── compute.yaml
│   │   ├── storage.yaml
│   │   ├── network.yaml
│   │   ├── secret.yaml
│   │   └── sealed-secret.yaml
│   └── guestbook/               # Manifests Guestbook PHP/Redis
│       ├── redis-leader-*.yaml
│       ├── redis-follower-*.yaml
│       └── frontend-*.yaml
│
├── TP3/                         # TP3 - Autoscaling Kubernetes
│   ├── COMPTE_RENDU_TP3.md     # Compte-rendu complet
│   ├── express-deployment.yaml  # Application Node.js
│   ├── express-service.yaml
│   └── express-hpa.yaml         # HorizontalPodAutoscaler
│
├── TD3/                         # TD3 - Helm Charts
│   ├── COMPTE_RENDU_TD3.md     # Compte-rendu complet
│   └── guestbook-chart/         # Chart Helm Guestbook
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│
├── GOK8S/                       # Projet GoTK8S complet
│   ├── README.md
│   ├── GUIDE_ENSEIGNANT.md
│   ├── GUIDE_ETUDIANT.md
│   ├── kingdoms/                # 8 royaumes K8s
│   ├── scenarios/               # Scénarios pédagogiques
│   └── manifests/               # Manifestes K8s
│
├── templates-vm/                # Templates VM
│   ├── ova-virtualbox/
│   ├── proxmox/
│   └── scripts/
│
├── docker-minikube/             # Solution Docker
│   ├── Dockerfile.minikube
│   ├── docker-compose.minikube.yml
│   └── docs/
│
├── cours/                       # Matériel pédagogique
│   ├── CM/
│   ├── TDs/
│   ├── TPs/
│   └── CC/
│
├── exemples/                    # Exemples et exercices
│   ├── kubernetes/
│   ├── docker/
│   ├── nginx-ssl/
│   └── flask-app/
│
└── outils/                      # Scripts utilitaires
    ├── install-minikube-native.sh
    └── install-docker-compose-v2.sh
```

---

## 💡 Cas d'Usage

### Étudiant - Premier cours

```bash
# Option simple : utiliser l'OVA
# 1. Télécharger et importer l'OVA
# 2. Démarrer la VM
# 3. Commencer

start-k8s
kubectl get nodes
cd ~/exemples/kubernetes/
kubectl apply -f hello-minikube.yaml
```

### Étudiant - Travail à la maison

```bash
# Installer Minikube en local
cd outils
./install-minikube-native.sh
minikube start

# Cloner un exercice
git clone <url-du-depot>
cd r509/exemples/kubernetes/
kubectl apply -f nginx-deployment.yaml
```

### Enseignant - Préparation TP

```bash
# Créer les templates VM pour les étudiants
cd templates-vm/ova-virtualbox
# Suivre le guide pour créer l'OVA

# Ou déployer GoTK8S
cd GOK8S
./kingdoms/deploy-gotk8s.sh
```

---

## 🆘 Support

### Documentation

| Sujet | Document |
|-------|----------|
| **GoTK8S** | [`GOK8S/README.md`](GOK8S/README.md) |
| **OVA VirtualBox** | [`templates-vm/ova-virtualbox/GUIDE-VIRTUALBOX-OVA.md`](templates-vm/ova-virtualbox/GUIDE-VIRTUALBOX-OVA.md) |
| **Proxmox** | [`templates-vm/proxmox/GUIDE-PROXMOX.md`](templates-vm/proxmox/GUIDE-PROXMOX.md) |
| **Docker/Minikube** | [`docker-minikube/docs/QUICKSTART.md`](docker-minikube/docs/QUICKSTART.md) |
| **Dépannage** | [`docker-minikube/docs/TROUBLESHOOTING.md`](docker-minikube/docs/TROUBLESHOOTING.md) |

### Problèmes courants

**Minikube ne démarre pas** :
```bash
minikube delete
minikube start --driver=docker
```

**Pas assez de RAM** :
```bash
# Utiliser l'OVA au lieu de Docker
# Ou réduire les ressources Minikube
minikube start --memory=2000mb --cpus=1
```

**Problèmes de proxy** :
```bash
# Dans les VMs, le proxy est déjà configuré
echo $http_proxy
# Devrait afficher : http://192.168.0.2:3128
```

---

## 🎓 Pédagogie

### Progression recommandée

1. **Semaine 1-2** : Docker (bases, Dockerfile, registries)
   - 📁 `cours/CM/` + `exemples/docker/`

2. **Semaine 3-4** : Kubernetes (pods, deployments, services)
   - 📁 `cours/TDs/TD1/` + `exemples/kubernetes/`

3. **Semaine 5-6** : Déploiement d'applications (Ingress, PVC, Secrets)
   - 📁 [`TP2/`](TP2/) - VS Code Server + Guestbook avec Kind

4. **Semaine 7-8** : Autoscaling et métriques
   - 📁 [`TP3/`](TP3/) - HPA avec Metrics Server

5. **Semaine 9-10** : Helm (charts, values, templates)
   - 📁 [`TD3/`](TD3/) - Création de charts Helm

6. **Semaine 11-12** : Projet GoTK8S
   - 📁 `GOK8S/scenarios/`

### Objectifs pédagogiques

- ✅ Maîtriser Docker et la conteneurisation
- ✅ Comprendre Kubernetes et l'orchestration
- ✅ Déployer des applications multi-tier (frontend, backend, BDD)
- ✅ Configurer l'autoscaling horizontal (HPA)
- ✅ Utiliser Helm pour gérer des déploiements
- ✅ Gérer les secrets de manière sécurisée (Sealed Secrets)
- ✅ Mettre en pratique avec des scénarios réels
- ✅ Appliquer Infrastructure as Code (IaC)

---

## 🤝 Contribution

### Enseignants

Pour ajouter du contenu :
1. Créer une branche pour vos modifications
2. Ajouter votre matériel dans le dossier approprié
3. Mettre à jour ce README si nécessaire
4. Soumettre une pull request

### Structure des nouveaux TDs/TPs

```
cours/TDs/TDX/
├── README.md          # Énoncé du TD
├── sujet.pdf          # PDF si disponible
├── correction/        # Correction (optionnel)
└── ressources/        # Fichiers nécessaires
```

---

## 📜 Licence

Ce matériel pédagogique est destiné à l'IUT Grand Ouest Normandie.

**Contact** : Maxime Lambert - maxime.lambert@unicaen.fr

---

## 🔄 Changelog

### v2.1 (Janvier 2025)
- ✅ **TP2 complet** : Déploiement Kubernetes avec Kind (VS Code + Guestbook)
  - Cluster multi-control-plane (HA)
  - Ingress-nginx avec Kustomize
  - Sealed Secrets pour GitOps
  - Script d'installation automatisé
- ✅ **TP3 complet** : Autoscaling Kubernetes avec HPA
  - Application Node.js avec charge CPU
  - Metrics Server
  - HorizontalPodAutoscaler
  - Simulation de charge et analyse
- ✅ **TD3 complet** : Helm Charts et templating
  - Création de charts Helm
  - Templating avancé avec Go templates
  - Gestion de releases et rollback
- ✅ Documentation complète (comptes-rendus de 1000+ lignes)

### v2.0 (Novembre 2024)
- ✅ Réorganisation complète du dépôt
- ✅ Ajout du projet GoTK8S
- ✅ Templates VM OVA et Proxmox
- ✅ Documentation restructurée

### v1.0 (Octobre 2024)
- Initial release
- Cours et TPs de base

---

**Version** : 2.1
**Dernière mise à jour** : Janvier 2025
**Maintenu par** : Enseignants R5.09 - IUT Grand Ouest Normandie
# r509
