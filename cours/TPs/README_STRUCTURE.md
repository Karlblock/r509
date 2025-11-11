# Structure des documents TP Kubernetes

## Documents principaux

### TP1 - Installation Kind & Kubernetes
- **TP1/TP1_Kind_Kubernetes_CheatSheet.tex** - Guide complet d'installation et configuration
  - Installation de Kind et kubectl
  - Configuration Proxmox pour VM
  - Création de cluster avec Ingress
  - Commandes kubectl essentielles
  - Troubleshooting

### TP2 - Déploiement d'applications
- **TP2/TP2_Kubernetes_Deploiement.tex** - Document LaTeX officiel du TP2
- **TP2/Docs/INSTALL_TP2_RAPIDE.md** - Guide d'installation rapide
  - Partie 1: VS Code Server (Deployment, PVC, Service, Ingress)
  - Partie 2: Guestbook PHP/Redis (Architecture multi-tiers)
  - Tests de résilience et scaling
  - Troubleshooting proxy et ingress

### Ressources complémentaires
- **TP2/Docs/KUBERNETES_GLOSSAIRE.md** - Glossaire complet des termes Kubernetes
- **TP2/Docs/PROXY_GUIDE.md** - Guide de configuration proxy pour l'IUT
- **TP2/examples/** - Exemples de manifests YAML pour VS Code et Guestbook

## Organisation
```
TPs/
├── TP1/
│   ├── TP1_Kind_Kubernetes_CheatSheet.tex
│   ├── TP1_Kind_Kubernetes_CheatSheet.pdf
│   └── kubeInfo_TP/note.md
├── TP2/
│   ├── TP2_Kubernetes_Deploiement.tex
│   ├── TP2_Kubernetes_Deploiement.pdf
│   ├── Docs/
│   │   ├── INSTALL_TP2_RAPIDE.md
│   │   ├── KUBERNETES_GLOSSAIRE.md
│   │   └── PROXY_GUIDE.md
│   └── examples/
│       ├── vs_code/
│       └── guestbook-php/
└── README_STRUCTURE.md
```

## État des TP sur la VM 192.168.56.11

### TP1 ✓
- Cluster Kind "cluster-ingress" fonctionnel
- Ingress NGINX controller déployé
- Test nginx accessible

### TP2 ✓
- Namespace: tp-kubernetes
- VS Code Server déployé (http://mon-app.local)
- Guestbook PHP/Redis déployé (http://guestbook.local)
- Tous les tests de résilience validés

### TD3 ✓
- Namespace: td3
- Helm chart vs-code-release installé
- Code Server accessible via NodePort 30080
