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

3. **Semaine 5-6** : Helm (charts, values, templates)
   - 📁 `cours/TDs/TD3/`

4. **Semaine 7-8** : Projet GoTK8S
   - 📁 `GOK8S/scenarios/`

### Objectifs pédagogiques

- ✅ Maîtriser Docker et la conteneurisation
- ✅ Comprendre Kubernetes et l'orchestration
- ✅ Utiliser Helm pour gérer des déploiements
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

### v2.0 (Novembre 2024)
- ✅ Réorganisation complète du dépôt
- ✅ Ajout du projet GoTK8S
- ✅ Templates VM OVA et Proxmox
- ✅ Documentation restructurée

### v1.0 (Octobre 2024)
- Initial release
- Cours et TPs de base

---

**Version** : 2.0
**Dernière mise à jour** : Novembre 2024
**Maintenu par** : Enseignants R5.09 - IUT Grand Ouest Normandie
# r509
