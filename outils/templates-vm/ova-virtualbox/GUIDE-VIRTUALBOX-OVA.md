# Guide - Créer un OVA VirtualBox avec Kubernetes et Proxy

## Vue d'ensemble

Ce guide vous permet de créer un fichier **OVA (Open Virtualization Archive)** avec VirtualBox contenant :
- ✅ Ubuntu 22.04
- ✅ Kubernetes (Minikube + kubectl + Helm + k9s)
- ✅ Proxy 192.168.0.2:3128 configuré automatiquement
- ✅ Scripts de démarrage rapide
- ✅ Documentation intégrée

**Avantages de l'OVA** :
- ✅ Portable (un seul fichier)
- ✅ Importable dans VirtualBox, VMware, Proxmox
- ✅ Facile à distribuer
- ✅ Compatible multi-plateformes

---

## Étape 1 : Créer la VM dans VirtualBox

### 1.1 Télécharger Ubuntu Server

```bash
# Télécharger Ubuntu 22.04 Server
wget https://releases.ubuntu.com/22.04/ubuntu-22.04.3-live-server-amd64.iso
```

Ou depuis : https://ubuntu.com/download/server

### 1.2 Créer la VM

1. **Ouvrir VirtualBox**

2. **Nouvelle VM** :
   - Nom : `kubernetes-template`
   - Type : Linux
   - Version : Ubuntu (64-bit)

3. **Mémoire** :
   - RAM : `4096 MB` (4 GB minimum)

4. **Disque dur** :
   - Créer un disque virtuel maintenant
   - Type : VDI (VirtualBox Disk Image)
   - Stockage : Dynamiquement alloué
   - Taille : `32 GB`

5. **Paramètres supplémentaires** :
   - Système → Processeur : `2 CPUs`
   - Système → Activer : "Activer PAE/NX"
   - Réseau → Carte 1 : "Accès par pont" (Bridged Adapter)
   - Stockage → Contrôleur : IDE → Ajouter l'ISO Ubuntu

### 1.3 Configuration recommandée

Avant de démarrer la VM, ajustez ces paramètres dans VirtualBox :

```
Configuration → Système → Carte mère
  ☑ Activer EFI (systèmes d'exploitation spéciaux uniquement)  [OPTIONNEL]

Configuration → Système → Processeur
  CPUs : 2
  ☑ Activer PAE/NX

Configuration → Affichage
  Mémoire vidéo : 16 MB
  ☑ Accélération 3D : Désactivé

Configuration → Stockage
  Contrôleur SATA :
    ☑ Utiliser le cache d'E/S de l'hôte

Configuration → Réseau
  Carte 1 : Accès par pont
  Type : Carte PCnet-FAST III (pour compatibilité)
```

---

## Étape 2 : Installer Ubuntu Server

### 2.1 Démarrer l'installation

1. **Démarrer la VM**
2. **Choisir la langue** : English
3. **Update to the new installer** : Continue without updating (pour accélérer)
4. **Keyboard** : French ou selon vos préférences
5. **Type d'installation** : Ubuntu Server (minimal)
6. **Configuration réseau** : DHCP (par défaut)
7. **Proxy** : Laisser vide pour l'instant (on configurera après)
8. **Mirror** : Par défaut
9. **Stockage** : Utiliser le disque entier
10. **Profil** :
    - Nom : `Ubuntu K8s Template`
    - Nom du serveur : `k8s-template`
    - Utilisateur : `ubuntu`
    - Mot de passe : `ubuntu` (changeable après)
11. **SSH** : ☑ Install OpenSSH server
12. **Snaps** : Ne rien cocher (on installera manuellement)
13. **Installation** : Attendre la fin
14. **Reboot**

### 2.2 Premier démarrage

```bash
# Se connecter
Login: ubuntu
Password: ubuntu

# Mettre à jour le système
sudo apt update
sudo apt upgrade -y

# Redémarrer
sudo reboot
```

---

## Étape 3 : Copier et exécuter les scripts

### 3.1 Obtenir l'IP de la VM

```bash
# Dans la VM
ip addr show
# Noter l'adresse IP (ex: 192.168.1.100)
```

### 3.2 Copier les scripts depuis votre Parrot OS

```bash
# Depuis votre Parrot OS (pas dans la VM)
cd /home/kless/IUT/r509
scp -r scripts/ ubuntu@<ip-de-la-vm>:/home/ubuntu/
```

Si `scp` demande le mot de passe : `ubuntu`

### 3.3 Se connecter à la VM et exécuter le script

```bash
# Depuis votre Parrot OS
ssh ubuntu@<ip-de-la-vm>

# Dans la VM
cd /home/ubuntu/scripts
sudo bash build-vm-image.sh
```

**⏱️ Durée** : 10-15 minutes

Le script va installer :
- Docker + containerd
- Minikube
- kubectl
- Helm
- k9s
- kubectx & kubens
- crictl
- Configurer le proxy 192.168.0.2:3128 partout
- Créer les scripts start-k8s / stop-k8s
- Configurer les alias (k, mk, h)
- Créer la documentation

---

## Étape 4 : Tester l'installation

Avant de créer l'OVA, vérifiez que tout fonctionne :

```bash
# Vérifier les versions
docker --version
minikube version
kubectl version --client
helm version

# Démarrer Minikube (TEST)
start-k8s

# Vérifier
kubectl get nodes
kubectl get pods -A

# Arrêter Minikube
minikube stop
```

Si tout fonctionne, continuez.

---

## Étape 5 : Nettoyer la VM avant export

### 5.1 Nettoyer l'historique et les logs

```bash
# Nettoyer l'historique bash
history -c
rm -f ~/.bash_history
sudo rm -f /root/.bash_history

# Nettoyer les logs
sudo journalctl --vacuum-time=1s
sudo rm -rf /var/log/*.log
sudo rm -rf /var/log/*/*.log
sudo find /var/log -type f -name "*.gz" -delete

# Nettoyer le cache APT
sudo apt clean
sudo apt autoremove -y

# Nettoyer les fichiers temporaires
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*

# Vider le fichier machine-id (régénéré au prochain boot)
sudo truncate -s 0 /etc/machine-id

# Vider le fichier hostname unique
sudo rm -f /etc/ssh/ssh_host_*
```

### 5.2 Remplir l'espace libre avec des zéros (compression optimale)

```bash
# Remplir l'espace libre avec des zéros (pour meilleure compression)
# ATTENTION : Cela peut prendre 5-10 minutes
sudo dd if=/dev/zero of=/EMPTY bs=1M || true
sudo rm -f /EMPTY

# Synchroniser
sync
```

### 5.3 Éteindre la VM

```bash
sudo shutdown -h now
```

---

## Étape 6 : Exporter en OVA

### 6.1 Via l'interface VirtualBox

1. **Sélectionner la VM** `kubernetes-template`
2. **Fichier** → **Exporter un appareil virtuel**
3. **Format** : OVA 2.0
4. **Fichier** : Choisir l'emplacement et le nom
   - Exemple : `/home/kless/IUT/r509/kubernetes-template.ova`
5. **Options** :
   - ☑ Inclure les adresses MAC de toutes les cartes réseau
   - Format de fichier : OVA
6. **Cliquer sur "Exporter"**

**⏱️ Durée** : 5-10 minutes (selon la taille du disque)

### 6.2 Via la ligne de commande

```bash
# Sur votre Parrot OS
VBoxManage export kubernetes-template \
  --output /home/kless/IUT/r509/kubernetes-template.ova \
  --ovf20 \
  --manifest \
  --vsys 0 \
  --product "Kubernetes Template" \
  --producturl "https://kubernetes.io" \
  --vendor "IUT R509" \
  --vendorurl "" \
  --version "1.0" \
  --description "Ubuntu 22.04 with Kubernetes (Minikube, kubectl, Helm) and proxy 192.168.0.2:3128"
```

---

## Étape 7 : Importer et utiliser l'OVA

### 7.1 Importer dans VirtualBox

```bash
# Ligne de commande
VBoxManage import kubernetes-template.ova

# Ou via l'interface
# Fichier → Importer un appareil virtuel → Sélectionner l'OVA
```

### 7.2 Configurer après import

1. **Renommer la VM** : Clic droit → Paramètres → Nom
2. **Ajuster la RAM/CPU** si nécessaire
3. **Configuration réseau** : Vérifier que le mode pont est actif
4. **Démarrer la VM**

### 7.3 Premier démarrage après import

```bash
# Se connecter
ssh ubuntu@<nouvelle-ip>

# Démarrer Kubernetes
start-k8s

# Vérifier
k get nodes
k get pods -A
```

---

## Étape 8 : Distribuer l'OVA

### 8.1 Compresser l'OVA (optionnel)

```bash
# L'OVA est déjà compressé, mais on peut le compresser davantage
gzip kubernetes-template.ova
# Résultat : kubernetes-template.ova.gz
```

### 8.2 Calculer le checksum

```bash
# SHA256
sha256sum kubernetes-template.ova > kubernetes-template.ova.sha256

# MD5
md5sum kubernetes-template.ova > kubernetes-template.ova.md5
```

### 8.3 Créer un fichier README pour la distribution

Le fichier `README-OVA.txt` sera créé automatiquement avec les instructions.

---

## Import dans différentes plateformes

### VirtualBox

```bash
VBoxManage import kubernetes-template.ova
```

### VMware Workstation/Player

1. Fichier → Ouvrir
2. Sélectionner l'OVA
3. Importer

### Proxmox

```bash
# Convertir l'OVA en QCOW2
tar -xvf kubernetes-template.ova
qemu-img convert -f vmdk kubernetes-template-disk001.vmdk -O qcow2 k8s-template.qcow2

# Créer la VM dans Proxmox
qm create 9000 --name kubernetes-template --memory 4096 --cores 2
qm importdisk 9000 k8s-template.qcow2 local-lvm
qm set 9000 --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --boot c --bootdisk scsi0
```

---

## Configuration du proxy après import

Le proxy **192.168.0.2:3128** est déjà configuré pour :
- APT
- Docker
- wget, curl
- Git
- Variables d'environnement

### Modifier le proxy

Si vous devez changer l'adresse du proxy :

```bash
# Éditer le fichier de configuration
sudo nano /etc/profile.d/proxy.sh

# Modifier les lignes
export http_proxy="http://NOUVELLE_IP:NOUVEAU_PORT"
export https_proxy="http://NOUVELLE_IP:NOUVEAU_PORT"

# Sauvegarder et appliquer
source /etc/profile.d/proxy.sh

# Redémarrer Docker
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### Désactiver le proxy

```bash
sudo /usr/local/bin/disable-proxy
sudo reboot
```

---

## Scripts disponibles dans la VM

| Script | Description |
|--------|-------------|
| `start-k8s` | Démarre Minikube avec les bons paramètres |
| `stop-k8s` | Arrête Minikube |
| `/usr/local/bin/disable-proxy` | Désactive le proxy système |

## Alias configurés

| Alias | Commande |
|-------|----------|
| `k` | `kubectl` |
| `mk` | `minikube` |
| `h` | `helm` |

---

## Utilisation quotidienne

### Démarrer Kubernetes

```bash
start-k8s
```

### Déployer une application

```bash
k create deployment nginx --image=nginx
k expose deployment nginx --type=NodePort --port=80
minikube service nginx
```

### Explorer avec k9s

```bash
k9s
```

### Arrêter Kubernetes

```bash
stop-k8s
```

---

## Taille attendue de l'OVA

- **VM de base** : ~3-5 GB
- **Après remplissage de zéros** : ~2-4 GB (mieux compressé)
- **Compressé (.ova.gz)** : ~1-2 GB

---

## Dépannage

### L'export OVA échoue

```bash
# Vérifier l'espace disque
df -h

# Compacter le disque VDI avant export
VBoxManage modifymedium disk /path/to/disk.vdi --compact
```

### La VM ne démarre pas après import

1. Vérifier les paramètres de virtualisation (VT-x/AMD-V)
2. Vérifier la configuration réseau
3. Augmenter la RAM si nécessaire

### Minikube ne démarre pas

```bash
# Voir les logs
minikube logs

# Réinitialiser
minikube delete
start-k8s
```

### Problème de proxy

```bash
# Vérifier la configuration
echo $http_proxy
cat /etc/profile.d/proxy.sh

# Tester
curl -I http://google.com
```

---

## Checklist avant distribution

- [ ] Ubuntu installé et à jour
- [ ] Script `build-vm-image.sh` exécuté avec succès
- [ ] Minikube démarre et fonctionne
- [ ] kubectl fonctionne
- [ ] Proxy configuré et testé
- [ ] Scripts start-k8s / stop-k8s fonctionnent
- [ ] Historique nettoyé
- [ ] Logs nettoyés
- [ ] machine-id vidé
- [ ] Espace libre rempli de zéros
- [ ] VM éteinte proprement
- [ ] OVA exporté
- [ ] Checksum calculé
- [ ] README créé
- [ ] OVA testé (import + démarrage)

---

## Documentation supplémentaire

Dans chaque VM, la documentation complète est disponible :
- `/home/ubuntu/README.md` - Guide utilisateur
- `/home/ubuntu/scripts/` - Scripts d'installation

---

## Support

Pour obtenir de l'aide :
1. Consultez `/home/ubuntu/README.md` dans la VM
2. Vérifiez les logs : `minikube logs`
3. Vérifiez Docker : `docker info`
4. Vérifiez le proxy : `echo $http_proxy`

---

**Version** : 1.0
**Date** : 2025-10-28
**Compatibilité** : VirtualBox 6.x+, Ubuntu 22.04
**Proxy** : 192.168.0.2:3128
