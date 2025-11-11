# Templates VM - Kubernetes & Minikube

Ce dossier contient tout le nécessaire pour créer des **templates VM préconfigurés** avec Kubernetes et Minikube, prêts pour la distribution aux étudiants.

---

## Vue d'ensemble

Deux solutions principales sont disponibles :

### Option A : OVA VirtualBox (RECOMMANDÉE pour distribution) ⭐

Fichier OVA portable importable dans VirtualBox, VMware, ou Proxmox.

**Avantages** :
- ✅ Un seul fichier portable (2-4 GB)
- ✅ Compatible avec tous les hyperviseurs
- ✅ Distribution facile (USB, cloud)
- ✅ Importation en 1 clic
- ✅ Idéal pour les étudiants qui travaillent à la maison

📖 **Guide complet** : [ova-virtualbox/GUIDE-VIRTUALBOX-OVA.md](ova-virtualbox/GUIDE-VIRTUALBOX-OVA.md)

### Option B : Template Proxmox (RECOMMANDÉE pour production)

Template Proxmox pour infrastructure professionnelle avec clonage rapide.

**Avantages** :
- ✅ Clone rapide de multiples VMs
- ✅ Intégration native Proxmox
- ✅ Gestion centralisée
- ✅ Production-ready
- ✅ Idéal pour les salles TP avec infrastructure Proxmox

📖 **Guide complet** : [proxmox/GUIDE-PROXMOX.md](proxmox/GUIDE-PROXMOX.md)

---

## Contenu préconfiguré

Toutes les VMs incluent :

### Système de base
- **OS** : Ubuntu 22.04 LTS Server
- **Ressources** : 4 GB RAM, 2 CPUs, 32 GB disque (ajustable)
- **Utilisateur** : ubuntu / ubuntu (sudo sans mot de passe)

### Outils Kubernetes
- **Minikube** : Latest version
- **kubectl** : v1.28.0
- **Helm** : v3 (latest)
- **k9s** : Terminal UI pour Kubernetes
- **kubectx & kubens** : Changement rapide de contexte/namespace
- **crictl** : CLI pour CRI (Container Runtime Interface)

### Configuration réseau
- **Proxy** : 192.168.0.2:3128 préconfiguré pour :
  - APT (apt-get, apt)
  - Docker (daemon + client)
  - containerd
  - wget, curl, git
  - Snap
  - Variables d'environnement système

### Scripts de démarrage rapide
- `/usr/local/bin/start-k8s` - Démarre Minikube avec configuration optimale
- `/usr/local/bin/stop-k8s` - Arrête proprement Minikube
- Alias pratiques : `k` (kubectl), `mk` (minikube), `h` (helm)

### Exemples intégrés
- Manifestes Kubernetes de base
- Exemples Helm
- Documentation d'utilisation

---

## Structure du dossier

```
templates-vm/
├── README.md                           ← Vous êtes ici
│
├── ova-virtualbox/                     # Solution OVA VirtualBox
│   ├── GUIDE-VIRTUALBOX-OVA.md        ⭐ Guide complet
│   └── README-OVA-DISTRIBUTION.txt     À distribuer avec l'OVA
│
├── proxmox/                            # Solution Proxmox
│   ├── GUIDE-PROXMOX.md               ⭐ Guide complet
│   ├── create-proxmox-template.sh      Script CLI Proxmox
│   └── proxmox-k8s.pkr.hcl            Template Packer
│
└── scripts/                            # Scripts d'installation
    ├── build-vm-image.sh              ⭐ Script master
    ├── setup-proxy.sh                  Configuration proxy
    ├── install-kubernetes-tools.sh     Installation K8s
    └── prepare-ova-export.sh          Préparation export OVA
```

---

## Démarrage rapide

### Pour créer un OVA VirtualBox

```bash
# 1. Créer une VM Ubuntu 22.04 dans VirtualBox
#    - Nom : kubernetes-template
#    - RAM : 4 GB
#    - CPUs : 2
#    - Disque : 32 GB (dynamique)
#    - Réseau : NAT + Host-Only

# 2. Installer Ubuntu 22.04 Server

# 3. Copier les scripts dans la VM
scp -r scripts/ ubuntu@<ip-vm>:/home/ubuntu/

# 4. Exécuter le script master
ssh ubuntu@<ip-vm>
cd ~/scripts
sudo bash build-vm-image.sh

# 5. Préparer pour export
sudo bash prepare-ova-export.sh
# (La VM s'éteint automatiquement)

# 6. Exporter en OVA (depuis votre machine hôte)
VBoxManage export kubernetes-template \
  --output kubernetes-template.ova --ovf20

# 7. Vérifier l'intégrité
sha256sum kubernetes-template.ova > kubernetes-template.ova.sha256
```

**Résultat** : Fichier `kubernetes-template.ova` (2-4 GB) prêt pour distribution

📖 **Guide détaillé** : [ova-virtualbox/GUIDE-VIRTUALBOX-OVA.md](ova-virtualbox/GUIDE-VIRTUALBOX-OVA.md)

---

### Pour créer un template Proxmox

```bash
# 1. Créer une VM Ubuntu 22.04 dans Proxmox

# 2. Copier les scripts dans la VM
scp -r scripts/ ubuntu@<ip-vm>:/home/ubuntu/

# 3. Exécuter le script master
ssh ubuntu@<ip-vm>
cd ~/scripts
sudo bash build-vm-image.sh

# 4. Arrêter la VM
sudo shutdown -h now

# 5. Convertir en template (depuis Proxmox)
qm template <vm-id>

# 6. Cloner pour créer des VMs
qm clone <template-id> <new-vm-id> --name student-vm-01
```

**Résultat** : Template Proxmox réutilisable avec clonage instantané

📖 **Guide détaillé** : [proxmox/GUIDE-PROXMOX.md](proxmox/GUIDE-PROXMOX.md)

---

## Scripts disponibles

### Script master : build-vm-image.sh

```bash
sudo bash scripts/build-vm-image.sh
```

**Ce script fait TOUT** :
1. Configure le proxy (192.168.0.2:3128)
2. Installe Docker + containerd
3. Installe Minikube, kubectl, Helm
4. Installe k9s, kubectx, kubens, crictl
5. Configure les alias et completions
6. Crée les scripts de démarrage
7. Génère la documentation

**Durée** : 10-15 minutes

### Script setup-proxy.sh

```bash
sudo bash scripts/setup-proxy.sh
```

Configure le proxy pour tous les outils :
- APT (`/etc/apt/apt.conf.d/95proxy`)
- Environnement système (`/etc/profile.d/proxy.sh`)
- Docker daemon (`/etc/systemd/system/docker.service.d/http-proxy.conf`)
- Docker client (`~/.docker/config.json`)
- Git, wget, curl

### Script install-kubernetes-tools.sh

```bash
sudo bash scripts/install-kubernetes-tools.sh
```

Installe tous les outils Kubernetes :
- Docker CE (latest stable)
- Minikube (latest)
- kubectl v1.28.0
- Helm 3 (latest)
- k9s, kubectx, kubens, crictl

### Script prepare-ova-export.sh

```bash
sudo bash scripts/prepare-ova-export.sh
```

Prépare la VM pour export OVA :
- Nettoie l'historique bash
- Vide les logs système
- Supprime les clés SSH host
- Réinitialise `/etc/machine-id`
- Remplit l'espace libre avec des zéros (meilleure compression)
- Éteint la VM

**⚠️ IMPORTANT** : Exécuter ce script uniquement avant l'export final !

---

## Utilisation pour les étudiants

### Première utilisation

1. **Importer l'OVA** (VirtualBox) ou **cloner le template** (Proxmox)
2. **Démarrer la VM**
3. **Se connecter** : `ubuntu` / `ubuntu`
4. **Démarrer Kubernetes** :
   ```bash
   start-k8s
   ```
5. **Vérifier** :
   ```bash
   k get nodes
   k get pods -A
   ```

### Commandes courantes

```bash
# Démarrer Minikube
start-k8s

# Arrêter Minikube
stop-k8s

# Déployer une application
k create deployment nginx --image=nginx
k expose deployment nginx --type=NodePort --port=80
mk service nginx

# Interface graphique
k9s

# Dashboard Kubernetes
mk dashboard
```

### Exemples intégrés

```bash
cd ~/exemples/kubernetes/

# Exemple simple
k apply -f hello-minikube.yaml
k get pods
k get services

# Nginx avec LoadBalancer
k apply -f nginx-deployment.yaml
mk service nginx

# Exemples avancés (ConfigMap, Secret, PVC, Ingress, etc.)
k apply -f advanced-examples.yaml
```

---

## Configuration du proxy

Le proxy **192.168.0.2:3128** est configuré automatiquement.

### Vérifier la configuration

```bash
# Variables d'environnement
echo $http_proxy
echo $https_proxy

# Docker
docker info | grep -i proxy

# APT
cat /etc/apt/apt.conf.d/95proxy
```

### Modifier le proxy

```bash
# Éditer les variables d'environnement
sudo nano /etc/profile.d/proxy.sh

# Recharger
source /etc/profile.d/proxy.sh

# Redémarrer Docker
sudo systemctl restart docker
```

### Désactiver le proxy

```bash
sudo /usr/local/bin/disable-proxy
```

---

## Dépannage

### Minikube ne démarre pas

```bash
# Vérifier les logs
minikube logs

# Supprimer et recréer le cluster
minikube delete
start-k8s
```

### Pas assez de RAM

```bash
# Réduire les ressources Minikube
minikube start --memory=2000mb --cpus=1
```

### Problèmes de proxy

```bash
# Vérifier la connectivité au proxy
curl -I -x http://192.168.0.2:3128 https://google.com

# Tester sans proxy
export http_proxy=""
export https_proxy=""
```

### Dashboard inaccessible

```bash
# Méthode 1 : Tunnel
mk dashboard

# Méthode 2 : Port forwarding
kubectl proxy --address='0.0.0.0' --port=8001 --accept-hosts='.*' &
# Accès : http://<vm-ip>:8001/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/
```

---

## Distribution

### Pour les enseignants

#### Distribuer l'OVA

1. **Créer l'OVA** en suivant [ova-virtualbox/GUIDE-VIRTUALBOX-OVA.md](ova-virtualbox/GUIDE-VIRTUALBOX-OVA.md)

2. **Vérifier l'intégrité** :
   ```bash
   sha256sum kubernetes-template.ova > kubernetes-template.ova.sha256
   ```

3. **Distribuer avec** :
   - Le fichier `.ova`
   - Le fichier `.sha256`
   - Le fichier `ova-virtualbox/README-OVA-DISTRIBUTION.txt`

4. **Hébergement** :
   - Serveur FTP/HTTP de l'IUT
   - Cloud storage (Google Drive, OneDrive, etc.)
   - Clés USB pour distribution locale

#### Déployer les templates Proxmox

1. **Créer le template** en suivant [proxmox/GUIDE-PROXMOX.md](proxmox/GUIDE-PROXMOX.md)

2. **Cloner pour chaque étudiant** :
   ```bash
   # Script de clonage automatique
   for i in {1..30}; do
     qm clone 9000 $((100 + i)) --name "student-vm-$(printf %02d $i)"
   done
   ```

3. **Configurer les IPs** (si nécessaire) :
   ```bash
   # Via cloud-init ou script post-clone
   ```

### Pour les étudiants

#### Importer l'OVA

1. **Télécharger** les fichiers :
   - `kubernetes-template.ova`
   - `kubernetes-template.ova.sha256`
   - `README-OVA-DISTRIBUTION.txt`

2. **Vérifier l'intégrité** :
   ```bash
   sha256sum -c kubernetes-template.ova.sha256
   ```

3. **Importer dans VirtualBox** :
   - Fichier → Importer
   - Sélectionner le fichier `.ova`
   - Ajuster les ressources si nécessaire
   - Importer

4. **Démarrer et utiliser** :
   - Démarrer la VM
   - Se connecter : `ubuntu` / `ubuntu`
   - Exécuter `start-k8s`

---

## Support

### Documentation complète

| Sujet | Document |
|-------|----------|
| **Guide OVA VirtualBox** | [ova-virtualbox/GUIDE-VIRTUALBOX-OVA.md](ova-virtualbox/GUIDE-VIRTUALBOX-OVA.md) |
| **Guide Proxmox** | [proxmox/GUIDE-PROXMOX.md](proxmox/GUIDE-PROXMOX.md) |
| **README principal** | [../README.md](../README.md) |
| **Solution Docker** | [../docker-minikube/README.md](../docker-minikube/README.md) |

### Problèmes courants

Consultez la section "Dépannage" ci-dessus ou référez-vous aux guides spécifiques.

---

## Contribution

### Modifier les scripts

1. **Éditer** le script dans `scripts/`
2. **Tester** dans une VM fraîche
3. **Valider** le processus complet
4. **Documenter** les changements

### Ajouter des outils

Pour ajouter un outil à l'installation :

1. **Éditer** `scripts/install-kubernetes-tools.sh`
2. **Ajouter** la section d'installation
3. **Tester** l'installation complète
4. **Mettre à jour** ce README

---

## Licence

Matériel pédagogique pour IUT Grand Ouest Normandie.

**Contact** : Maxime Lambert - maxime.lambert@unicaen.fr

---

**Version** : 2.0
**Dernière mise à jour** : Novembre 2024
**Maintenu par** : Enseignants R5.09 - IUT Grand Ouest Normandie
