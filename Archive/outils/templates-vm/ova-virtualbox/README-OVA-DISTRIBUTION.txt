╔═══════════════════════════════════════════════════════════════════╗
║        KUBERNETES TEMPLATE - OVA VirtualBox v1.0                  ║
╚═══════════════════════════════════════════════════════════════════╝

📦 CONTENU DE CE PACKAGE

Fichiers :
 • kubernetes-template.ova          - Image VirtualBox prête à l'emploi
 • kubernetes-template.ova.sha256   - Checksum SHA256 (vérification)
 • README-OVA-DISTRIBUTION.txt      - Ce fichier

╔═══════════════════════════════════════════════════════════════════╗
║  CARACTÉRISTIQUES                                                 ║
╚═══════════════════════════════════════════════════════════════════╝

Système :
 • OS : Ubuntu 22.04 LTS Server
 • RAM : 4 GB (recommandé)
 • CPU : 2 cores (recommandé)
 • Disque : 32 GB (dynamique)

Logiciels installés :
 • Docker CE (dernière version)
 • Minikube (dernière version)
 • kubectl v1.28.0
 • Helm 3
 • k9s (interface TUI)
 • kubectx & kubens
 • crictl

Configuration :
 • Proxy : 192.168.0.2:3128 (configuré pour tout)
 • Utilisateur : ubuntu / ubuntu
 • SSH : Activé
 • Scripts : start-k8s, stop-k8s

╔═══════════════════════════════════════════════════════════════════╗
║  PRÉREQUIS                                                        ║
╚═══════════════════════════════════════════════════════════════════╝

 • VirtualBox 6.0 ou supérieur
 • 4 GB RAM libre minimum
 • 8 GB RAM libre recommandé
 • Virtualisation activée (VT-x/AMD-V) dans le BIOS
 • 40 GB d'espace disque libre

╔═══════════════════════════════════════════════════════════════════╗
║  INSTALLATION                                                     ║
╚═══════════════════════════════════════════════════════════════════╝

1️⃣  Vérifier le checksum (optionnel mais recommandé)

   Windows PowerShell :
     Get-FileHash kubernetes-template.ova -Algorithm SHA256
     Compare-Object (Get-Content kubernetes-template.ova.sha256) ...

   Linux/macOS :
     sha256sum -c kubernetes-template.ova.sha256

2️⃣  Importer l'OVA dans VirtualBox

   Via l'interface :
     VirtualBox → Fichier → Importer un appareil virtuel
     → Sélectionner kubernetes-template.ova
     → Importer

   Via la ligne de commande :
     VBoxManage import kubernetes-template.ova

3️⃣  Configurer la VM (optionnel)

   • Renommer la VM
   • Ajuster RAM/CPU selon vos besoins
   • Vérifier la configuration réseau (Bridged/NAT)

4️⃣  Démarrer la VM

   Clic droit sur la VM → Démarrer

╔═══════════════════════════════════════════════════════════════════╗
║  PREMIER DÉMARRAGE                                                ║
╚═══════════════════════════════════════════════════════════════════╝

1. Attendre que la VM démarre complètement

2. Se connecter :
   Login    : ubuntu
   Password : ubuntu

   ⚠️  IMPORTANT : Changez le mot de passe par défaut !
   passwd

3. Obtenir l'adresse IP :
   ip addr show
   # Noter l'adresse IP (ex: 192.168.1.100)

4. Se connecter via SSH (recommandé) :
   ssh ubuntu@<ip-de-la-vm>

5. Démarrer Kubernetes :
   start-k8s

6. Vérifier que tout fonctionne :
   k get nodes
   k get pods -A

╔═══════════════════════════════════════════════════════════════════╗
║  UTILISATION                                                      ║
╚═══════════════════════════════════════════════════════════════════╝

Démarrer Kubernetes :
  start-k8s

Arrêter Kubernetes :
  stop-k8s

Vérifier le statut :
  minikube status
  k get nodes

Déployer une application :
  k create deployment nginx --image=nginx
  k expose deployment nginx --type=NodePort --port=80
  minikube service nginx

Explorer avec l'interface k9s :
  k9s

Dashboard Kubernetes :
  minikube dashboard

╔═══════════════════════════════════════════════════════════════════╗
║  ALIAS CONFIGURÉS                                                 ║
╚═══════════════════════════════════════════════════════════════════╝

k   = kubectl
mk  = minikube
h   = helm

Exemples :
  k get pods
  mk status
  h list

╔═══════════════════════════════════════════════════════════════════╗
║  CONFIGURATION DU PROXY                                           ║
╚═══════════════════════════════════════════════════════════════════╝

Proxy préconfigré : 192.168.0.2:3128

Systèmes concernés :
 • APT (apt-get, apt)
 • Docker
 • wget, curl
 • Git
 • Variables d'environnement

Exclusions (no_proxy) :
 • localhost, 127.0.0.1
 • 10.0.0.0/8
 • 172.16.0.0/12
 • 192.168.0.0/16

Modifier le proxy :
  sudo nano /etc/profile.d/proxy.sh
  # Changer http_proxy et https_proxy
  source /etc/profile.d/proxy.sh
  sudo systemctl restart docker

Désactiver le proxy :
  sudo /usr/local/bin/disable-proxy
  sudo reboot

╔═══════════════════════════════════════════════════════════════════╗
║  DOCUMENTATION                                                    ║
╚═══════════════════════════════════════════════════════════════════╝

Dans la VM :
  cat ~/README.md

Online :
 • Kubernetes : https://kubernetes.io/docs/
 • Minikube   : https://minikube.sigs.k8s.io/docs/
 • kubectl    : https://kubernetes.io/docs/reference/kubectl/
 • Helm       : https://helm.sh/docs/
 • k9s        : https://k9scli.io/

╔═══════════════════════════════════════════════════════════════════╗
║  EXEMPLES DE DÉPLOIEMENTS                                         ║
╚═══════════════════════════════════════════════════════════════════╝

1. Hello World

   k create deployment hello --image=k8s.gcr.io/echoserver:1.4
   k expose deployment hello --type=NodePort --port=8080
   minikube service hello

2. Nginx

   k create deployment nginx --image=nginx
   k expose deployment nginx --type=LoadBalancer --port=80
   minikube service nginx

3. WordPress avec Helm

   helm repo add bitnami https://charts.bitnami.com/bitnami
   helm install my-wordpress bitnami/wordpress
   k get pods -w

╔═══════════════════════════════════════════════════════════════════╗
║  DÉPANNAGE                                                        ║
╚═══════════════════════════════════════════════════════════════════╝

Minikube ne démarre pas :
  minikube logs
  minikube delete
  start-k8s

Problème réseau :
  # Vérifier la configuration réseau de VirtualBox
  # Essayer mode NAT au lieu de Bridge

Problème de proxy :
  echo $http_proxy
  curl -I http://google.com
  sudo systemctl status docker

VM lente :
  # Augmenter RAM dans VirtualBox (4 GB → 6-8 GB)
  # Augmenter CPUs (2 → 4)

Pas assez de ressources :
  # Réduire les ressources Minikube
  minikube delete
  minikube start --memory=2000mb --cpus=1

╔═══════════════════════════════════════════════════════════════════╗
║  CLONAGE DE LA VM                                                 ║
╚═══════════════════════════════════════════════════════════════════╝

Pour créer plusieurs instances :

1. Clic droit sur la VM → Cloner
2. Choisir "Clone complet"
3. Cocher "Réinitialiser l'adresse MAC"
4. Démarrer la VM clonée
5. Dans la VM clonée :
   sudo rm /etc/machine-id
   sudo systemd-machine-id-setup
   sudo reboot

╔═══════════════════════════════════════════════════════════════════╗
║  EXPORT VERS D'AUTRES PLATEFORMES                                 ║
╚═══════════════════════════════════════════════════════════════════╝

VMware :
  • Ouvrir directement l'OVA dans VMware Workstation/Player

Proxmox :
  tar -xvf kubernetes-template.ova
  qemu-img convert -f vmdk *-disk001.vmdk -O qcow2 k8s.qcow2
  # Importer dans Proxmox

Hyper-V :
  # Convertir avec StarWind V2V Converter
  # Ou utiliser qemu-img

╔═══════════════════════════════════════════════════════════════════╗
║  SÉCURITÉ                                                         ║
╚═══════════════════════════════════════════════════════════════════╝

⚠️  IMPORTANT - Après import :

1. Changer le mot de passe par défaut :
   passwd

2. Mettre à jour le système :
   sudo apt update && sudo apt upgrade -y

3. Configurer le firewall si nécessaire :
   sudo ufw enable
   sudo ufw allow 22/tcp
   sudo ufw allow 30000:32767/tcp

4. Configurer SSH avec clé publique :
   ssh-copy-id ubuntu@<ip-vm>
   sudo nano /etc/ssh/sshd_config
   # PasswordAuthentication no
   sudo systemctl restart ssh

╔═══════════════════════════════════════════════════════════════════╗
║  INFORMATIONS TECHNIQUES                                          ║
╚═══════════════════════════════════════════════════════════════════╝

Format : OVA 2.0
Système invité : Ubuntu 22.04 LTS (64-bit)
Firmware : BIOS (ou EFI si configuré)
Contrôleur disque : SATA
Type réseau : Bridged (modifiable)
Ports par défaut :
 • SSH : 22
 • NodePort : 30000-32767
 • API Kubernetes : 8443 (dans le conteneur Minikube)

╔═══════════════════════════════════════════════════════════════════╗
║  SUPPORT                                                          ║
╚═══════════════════════════════════════════════════════════════════╝

Pour obtenir de l'aide :
1. Lire ~/README.md dans la VM
2. Consulter les logs : minikube logs
3. Vérifier Docker : docker info
4. Vérifier le proxy : echo $http_proxy

╔═══════════════════════════════════════════════════════════════════╗
║  LICENCE ET CRÉDITS                                               ║
╚═══════════════════════════════════════════════════════════════════╝

• Ubuntu : Canonical Ltd. (https://ubuntu.com)
• Kubernetes : CNCF (https://kubernetes.io)
• Minikube : Kubernetes Project
• Docker : Docker Inc.
• Helm : CNCF
• k9s : Fernand Galiana

Cette image est fournie à des fins éducatives.

╔═══════════════════════════════════════════════════════════════════╗
║  CHANGELOG                                                        ║
╚═══════════════════════════════════════════════════════════════════╝

Version 1.0 (2025-10-28)
 • Version initiale
 • Ubuntu 22.04
 • Minikube latest
 • kubectl v1.28.0
 • Helm 3
 • k9s
 • Proxy 192.168.0.2:3128 configuré

─────────────────────────────────────────────────────────────────────

Créé par : IUT R509
Date : 2025-10-28
Version : 1.0

Bon déploiement ! 🚀
