# TP Kubernetes - Guides d'installation et déploiement

Documentation complète pour les TP01 et TP02 de Kubernetes avec gestion du proxy IUT.

## 📚 Guides disponibles

### 🚀 Guides principaux

1. **[INSTALL_TP1_RAPIDE.md](INSTALL_TP1_RAPIDE.md)** - Installation cluster Kind
   - Installation de Docker, kubectl, Kind
   - Configuration complète du proxy
   - Création du cluster avec 2 control-plane + 1 worker
   - Installation de l'Ingress Controller NGINX
   - Test de validation avec Nginx

2. **[INSTALL_TP2_RAPIDE.md](INSTALL_TP2_RAPIDE.md)** - Déploiement d'applications
   - VS Code Server (application simple avec stockage)
   - Guestbook PHP/Redis (application multi-tiers)
   - Manifests YAML complets et prêts à l'emploi
   - Commandes de debug et dépannage

### 📖 Guides complémentaires

3. **[PROXY_GUIDE.md](PROXY_GUIDE.md)** - Configuration proxy (IMPORTANT)
   - Configuration complète du proxy IUT
   - Workflow quotidien
   - Script de test automatique
   - Dépannage des problèmes courants

4. **[KUBERNETES_GLOSSAIRE.md](KUBERNETES_GLOSSAIRE.md)** - Référence Kubernetes
   - Définitions de tous les objets Kubernetes
   - Exemples de manifests
   - Cas d'usage et bonnes pratiques
   - Workflows typiques

5. **[INSTALL_KUBERNETES.md](INSTALL_KUBERNETES.md)** - Installation Minikube (alternative)
   - Installation avec Minikube au lieu de Kind
   - Configuration des namespaces
   - Installation Helm

## 🎯 Par où commencer ?

### Nouveau sur Kubernetes ?

```
1. Lire le KUBERNETES_GLOSSAIRE.md (comprendre les concepts)
2. Suivre INSTALL_TP1_RAPIDE.md (installer l'environnement)
3. Lire PROXY_GUIDE.md (configurer le proxy)
4. Suivre INSTALL_TP2_RAPIDE.md (déployer des applications)
```

### Déjà un cluster installé ?

```
1. Vérifier la config proxy avec PROXY_GUIDE.md
2. Passer directement à INSTALL_TP2_RAPIDE.md
```

### Problème avec le proxy ?

```
1. Consulter PROXY_GUIDE.md section "Dépannage"
2. Exécuter le script de test : ~/test-proxy.sh
3. Vérifier la checklist dans PROXY_GUIDE.md
```

## 🔧 Configuration Proxy (Essentiel)

### Règle d'or

```bash
Proxy Docker daemon : OUI ✅  (pour télécharger les images)
Proxy variables shell : NON ❌ (pour Kind/Kubernetes)
```

### Commandes rapides

```bash
# Désactiver le proxy shell (TOUJOURS pour K8s)
proxy-off

# Vérifier la configuration complète
proxy-check

# Vérifier uniquement les variables (doivent être vides)
env | grep -i proxy

# Vérifier le proxy Docker (doit afficher le proxy)
sudo systemctl show --property=Environment docker | grep PROXY
```

## 📋 Checklist avant de commencer les TPs

### TP01 - Installation

- [ ] Ubuntu 20.04+ avec 4 Go RAM, 4 CPUs
- [ ] Proxy système configuré (`proxy-on`)
- [ ] Docker installé avec proxy daemon
- [ ] kubectl installé
- [ ] Kind installé
- [ ] Proxy shell désactivé (`proxy-off`)
- [ ] Cluster Kind créé et fonctionnel
- [ ] Ingress Controller NGINX installé

### TP02 - Déploiement

- [ ] TP01 terminé
- [ ] Proxy shell désactivé (`proxy-off`)
- [ ] Cluster Kind opérationnel
- [ ] Namespace `tp-kubernetes` créé
- [ ] Docker daemon avec proxy actif

## 🗂️ Structure des fichiers

```
TP2/
├── README.md                           # Ce fichier
├── INSTALL_TP1_RAPIDE.md              # Guide installation TP01
├── INSTALL_TP2_RAPIDE.md              # Guide déploiement TP02
├── PROXY_GUIDE.md                     # Guide proxy complet
├── KUBERNETES_GLOSSAIRE.md            # Référence Kubernetes
├── INSTALL_KUBERNETES.md              # Installation Minikube
├── kind-cluster-config.yaml           # Config cluster (à créer)
└── ~/tp02/                            # Dossier de travail
    ├── vs_code/                       # Manifests VS Code Server
    │   ├── compute.yaml
    │   ├── storage.yaml
    │   ├── network.yaml
    │   └── secret.yaml
    └── guestbook-php/                 # Manifests Guestbook
        ├── redis-leader-deployment.yaml
        ├── redis-leader-service.yaml
        ├── redis-follower-deployment.yaml
        ├── redis-follower-service.yaml
        ├── frontend-deployment.yaml
        ├── frontend-service.yaml
        └── frontend-ingress.yaml
```

## 🚀 Démarrage rapide TP01

### Option 1 : Configuration automatique (RECOMMANDÉ)

```bash
# 1. Configurer le proxy automatiquement
cd ~/IUT/r509/TPs/TP2
./configure-proxy.sh
# Entrer votre login et mot de passe IUT

# 2. Nouveau terminal OU recharger la config
source ~/.bashrc

# 3. Vérifier la configuration
proxy-check

# 4. Installer Docker, kubectl, Kind
# Voir INSTALL_TP1_RAPIDE.md sections 3-5

# 5. Désactiver le proxy shell (déjà fait par le script)
proxy-off
env | grep -i proxy  # Doit être vide

# 6. Créer le cluster
kind create cluster --name tp-cluster --config kind-cluster-config.yaml

# 7. Installer l'Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# 8. Vérifier
kubectl get nodes
kubectl get pods -A
```

### Option 2 : Configuration manuelle

Suivre le guide [INSTALL_TP1_RAPIDE.md](INSTALL_TP1_RAPIDE.md) étape par étape.

## 🚀 Démarrage rapide TP02

```bash
# 1. Vérifier le proxy
proxy-off
proxy-check

# 2. Créer le namespace
kubectl create namespace tp-kubernetes
kubectl config set-context --current --namespace=tp-kubernetes

# 3. Déployer VS Code Server
cd ~/tp02/vs_code
kubectl apply -f secret.yaml
kubectl apply -f storage.yaml
kubectl apply -f compute.yaml
kubectl apply -f network.yaml

# 4. Accéder à l'application
echo "127.0.0.1 mon-app.local" | sudo tee -a /etc/hosts
# Ouvrir http://mon-app.local dans le navigateur

# 5. Déployer Guestbook (optionnel)
cd ~/tp02/guestbook-php
kubectl apply -f .
echo "127.0.0.1 guestbook.local" | sudo tee -a /etc/hosts
# Ouvrir http://guestbook.local dans le navigateur
```

## 🛠️ Commandes utiles

### Gestion du cluster

```bash
# Voir les nœuds
kubectl get nodes

# Voir tous les pods
kubectl get pods -A

# Voir les ressources dans le namespace actuel
kubectl get all

# Changer de namespace
kubectl config set-context --current --namespace=<namespace>
```

### Debug

```bash
# Logs d'un pod
kubectl logs <pod-name>
kubectl logs -f <pod-name>  # Suivre en temps réel

# Décrire un pod
kubectl describe pod <pod-name>

# Events
kubectl get events --sort-by='.lastTimestamp'

# Entrer dans un pod
kubectl exec -it <pod-name> -- /bin/sh
```

### Nettoyage

```bash
# Supprimer une application
kubectl delete -f .

# Supprimer un namespace (et tout dedans)
kubectl delete namespace <namespace>

# Redémarrer le cluster
kind delete cluster --name tp-cluster
kind create cluster --name tp-cluster --config kind-cluster-config.yaml
```

## ❓ Problèmes fréquents

### ImagePullBackOff

**Cause** : Docker daemon n'a pas de proxy configuré

**Solution** :
```bash
sudo systemctl show --property=Environment docker
# Si vide, configurer le proxy (voir PROXY_GUIDE.md)
```

### Pods en Pending

**Cause** : PVC non bound ou ressources insuffisantes

**Solution** :
```bash
kubectl describe pod <pod-name>
kubectl get pvc
```

### Kind ne démarre pas

**Cause** : Variables proxy actives

**Solution** :
```bash
proxy-off
env | grep -i proxy  # Doit être vide
kind delete cluster --name tp-cluster
kind create cluster --name tp-cluster --config kind-cluster-config.yaml
```

### Ingress ne fonctionne pas

**Cause** : Ingress Controller pas installé ou /etc/hosts manquant

**Solution** :
```bash
kubectl get pods -n ingress-nginx
cat /etc/hosts | grep local
```

## 📊 Tableau de dépannage rapide

| Symptôme | Diagnostic | Solution |
|----------|-----------|----------|
| ImagePullBackOff | `sudo systemctl show --property=Environment docker` | `./configure-proxy.sh` OU configurer proxy Docker manuellement |
| Kind ne démarre pas | `env \| grep -i proxy` | `proxy-off` |
| kubectl lent | `env \| grep -i proxy` | `proxy-off` |
| Pod Pending | `kubectl describe pod` | Vérifier PVC, ressources |
| Ingress 404 | `cat /etc/hosts` | Ajouter entrée DNS |
| apt update échoue | `cat /etc/apt/apt.conf.d/95proxies` | `./configure-proxy.sh` OU configurer proxy APT |
| Proxy mal configuré | `proxy-check` | `./configure-proxy.sh` pour reconfigurer |

## 📞 Ressources externes

- [Documentation Kubernetes](https://kubernetes.io/docs/)
- [Documentation Kind](https://kind.sigs.k8s.io/)
- [Documentation Ingress NGINX](https://kubernetes.github.io/ingress-nginx/)
- [Docker systemd proxy](https://docs.docker.com/config/daemon/systemd/#httphttps-proxy)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

## 🎓 Compte-rendu

### Contenu attendu

1. **Captures d'écran**
   - Applications accessibles dans le navigateur
   - Sorties de commandes `kubectl get all`
   - Pods en état Running

2. **Réponses aux questions du TP**
   - Section env, volumes, PVC
   - Accès aux applications
   - Logs et debugging
   - Sécurisation des secrets

3. **Problèmes rencontrés**
   - Description du problème
   - Diagnostic effectué
   - Solution appliquée
   - Vérification

4. **Bonus : Configuration proxy**
   - Documenter les difficultés proxy
   - Solutions trouvées

## 📝 Template compte-rendu

```markdown
# Compte-rendu TP Kubernetes

## Informations
- Nom :
- Date :
- TP : TP01/TP02

## Configuration environnement
- VM : [specs]
- Proxy configuré : Oui/Non
- Cluster Kind : [nombre de nœuds]

## Déploiements réalisés

### Application 1 : [nom]
- Captures d'écran
- Commandes utilisées
- Problèmes rencontrés

### Application 2 : [nom]
- Captures d'écran
- Commandes utilisées
- Problèmes rencontrés

## Réponses aux questions

1. À quoi sert la section env ?
   [Réponse]

2. À quoi sert la section volume et volumeMount ?
   [Réponse]

[...]

## Problèmes et solutions

### Problème 1 : [titre]
- Symptôme :
- Diagnostic :
- Solution :
- Vérification :

## Conclusion

[Apprentissages, difficultés, améliorations possibles]
```

---

## 📅 Historique des modifications

- 2025-01-24 : Création du README avec liens vers tous les guides
- 2025-01-24 : Ajout du guide proxy complet
- 2025-01-24 : Ajout des guides TP01 et TP02

---

**Bon courage pour vos TPs !** 🚀

Pour toute question, consultez d'abord les guides et les sections de dépannage.
