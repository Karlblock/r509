# 🚀 COMMENCEZ ICI - Configuration Proxy IUT + TP Kubernetes

**Bienvenue !** Ce guide vous permet de démarrer rapidement avec les TPs Kubernetes.

## ⚡ Démarrage ultra-rapide (3 étapes)

### Étape 1 : Configurer le proxy IUT

```bash
cd ~/IUT/r509/TPs/TP2
./configure-proxy.sh
```

Entrez votre **login** et **mot de passe IUT** quand demandé.

### Étape 2 : Vérifier la configuration

```bash
source ~/.bashrc
proxy-check
```

Vous devriez voir :
- ✅ Variables shell : vides
- ✅ Docker daemon : proxy configuré avec `192.168.0.2:3128`

### Étape 3 : Suivre le TP

- **TP01** → [INSTALL_TP1_RAPIDE.md](INSTALL_TP1_RAPIDE.md)
- **TP02** → [INSTALL_TP2_RAPIDE.md](INSTALL_TP2_RAPIDE.md)

---

## 📚 Documentation disponible

| Fichier | Description | Quand l'utiliser |
|---------|-------------|------------------|
| **[PROXY_CONFIG_IUT.md](PROXY_CONFIG_IUT.md)** | Guide rapide proxy IUT | Configuration initiale |
| **[configure-proxy.sh](configure-proxy.sh)** | Script automatique | Première installation |
| **[INSTALL_TP1_RAPIDE.md](INSTALL_TP1_RAPIDE.md)** | Installation cluster Kind | TP01 - Setup environnement |
| **[INSTALL_TP2_RAPIDE.md](INSTALL_TP2_RAPIDE.md)** | Déploiement applications | TP02 - Déployer VS Code + Guestbook |
| **[PROXY_GUIDE.md](PROXY_GUIDE.md)** | Guide proxy complet | Problèmes proxy |
| **[KUBERNETES_GLOSSAIRE.md](KUBERNETES_GLOSSAIRE.md)** | Référence Kubernetes | Comprendre les concepts |
| **[README.md](README.md)** | Vue d'ensemble complète | Navigation générale |

---

## 🎯 Quelle documentation lire ?

### Je débute complètement

```
1. START_HERE.md (ce fichier) ← VOUS ÊTES ICI
2. PROXY_CONFIG_IUT.md (5 min)
3. INSTALL_TP1_RAPIDE.md (30-45 min)
4. INSTALL_TP2_RAPIDE.md (1-2h)
```

### J'ai un problème de proxy

```
1. PROXY_CONFIG_IUT.md
2. proxy-check (commande)
3. PROXY_GUIDE.md (si problème persiste)
```

### Je veux comprendre Kubernetes

```
1. KUBERNETES_GLOSSAIRE.md
2. INSTALL_TP1_RAPIDE.md
3. INSTALL_TP2_RAPIDE.md
```

### J'ai déjà un cluster installé

```
1. proxy-check (vérifier la config)
2. INSTALL_TP2_RAPIDE.md
```

---

## ⚠️ Points critiques à retenir

### 🔴 Le proxy DOIT être configuré ainsi :

| Composant | Proxy actif ? | Pourquoi |
|-----------|--------------|----------|
| **Docker daemon** | ✅ OUI | Pour télécharger les images |
| **Variables shell** | ❌ NON | Kind/kubectl ne fonctionnent pas avec proxy |

### ✅ Configuration correcte

```bash
# 1. Docker daemon avec proxy
sudo systemctl show --property=Environment docker | grep PROXY
# Doit afficher : HTTP_PROXY=...192.168.0.2:3128...

# 2. Shell sans proxy
env | grep -i proxy
# Ne doit RIEN afficher
```

### ❌ Configuration incorrecte

```bash
# Si vous voyez des variables proxy dans le shell
env | grep -i proxy
HTTP_PROXY=http://...

# ERREUR ! Cela va bloquer Kind/kubectl
# Solution : proxy-off
```

---

## 🛠️ Commandes essentielles

### Gestion du proxy

```bash
proxy-off       # Désactiver le proxy shell (TOUJOURS pour K8s)
proxy-on        # Activer le proxy shell (rarement nécessaire)
proxy-check     # Vérifier la configuration complète
proxy-status    # Voir l'état actuel
```

### Vérification rapide

```bash
# Avant de travailler avec Kubernetes
proxy-check

# Résultat attendu :
# Test 1: Variables shell (devrait être vide pour K8s)
# ✓ OK - Aucune variable proxy
#
# Test 2: Docker daemon (devrait afficher le proxy avec 192.168.0.2:3128)
# ✓ OK - Proxy Docker configuré
# Environment=HTTP_PROXY=http://...@192.168.0.2:3128
```

### Kubernetes/Kind

```bash
kubectl get nodes              # Voir les nœuds
kubectl get pods -A            # Voir tous les pods
kind get clusters              # Lister les clusters Kind
kubectl config view --minify   # Voir la config actuelle
```

---

## 🔥 Problèmes fréquents et solutions

### ❌ "ImagePullBackOff" sur les pods

```bash
# Cause : Docker daemon n'a pas de proxy
# Solution :
./configure-proxy.sh
```

### ❌ Kind ne démarre pas

```bash
# Cause : Variables proxy actives
# Solution :
proxy-off
env | grep -i proxy  # Vérifier que c'est vide
```

### ❌ kubectl très lent ou timeout

```bash
# Cause : Variables proxy actives
# Solution :
proxy-off
```

### ❌ apt update échoue

```bash
# Cause : Proxy APT mal configuré
# Solution :
./configure-proxy.sh
```

---

## 📋 Checklist avant de commencer le TP

### TP01 - Installation

- [ ] Proxy configuré (`./configure-proxy.sh`)
- [ ] Vérification OK (`proxy-check`)
- [ ] Variables shell vides (`env | grep -i proxy`)
- [ ] Docker daemon avec proxy (`sudo systemctl show --property=Environment docker`)
- [ ] Ubuntu 20.04+ avec 4Go RAM, 4 CPUs
- [ ] Accès internet via proxy IUT

### TP02 - Déploiement

- [ ] TP01 terminé
- [ ] Cluster Kind opérationnel (`kubectl get nodes`)
- [ ] Ingress Controller installé (`kubectl get pods -n ingress-nginx`)
- [ ] Namespace créé (`kubectl create namespace tp-kubernetes`)
- [ ] Proxy shell désactivé (`proxy-off`)

---

## 🎓 Workflow recommandé

### Session de travail type

```bash
# 1. Ouvrir le terminal
cd ~/IUT/r509/TPs/TP2

# 2. Vérifier la config proxy
proxy-check

# 3. Si variables proxy apparaissent
proxy-off

# 4. Vérifier à nouveau
env | grep -i proxy  # Doit être vide

# 5. Travailler avec Kubernetes
kubectl get all
kind get clusters

# 6. Si besoin de télécharger avec curl/wget
proxy-on
curl https://example.com
proxy-off  # Remettre off immédiatement
```

### Fin de session

```bash
# Arrêter le cluster Kind (optionnel)
kind delete cluster --name tp-cluster

# Rien d'autre à faire, la config proxy reste active
```

---

## 💡 Astuces

### Vérification ultra-rapide

```bash
# Ajouter dans ~/.bashrc
alias ready='proxy-off && echo "Proxy shell: $(env | grep -i proxy | wc -l) vars" && echo "Docker proxy: $(sudo systemctl show --property=Environment docker | grep -c PROXY) configs"'

# Utilisation
ready
# Proxy shell: 0 vars      ← Doit être 0
# Docker proxy: 2 configs  ← Doit être 2
```

### Reset complet

```bash
# Si tout est cassé, tout réinstaller
sudo rm -f /etc/apt/apt.conf.d/95proxies
sudo rm -f /etc/systemd/system/docker.service.d/http-proxy.conf
rm -f ~/.docker/config.json

# Puis reconfigurer
./configure-proxy.sh
```

---

## 📞 Besoin d'aide ?

### Ordre de consultation

1. **Vérifier avec** `proxy-check`
2. **Consulter** [PROXY_CONFIG_IUT.md](PROXY_CONFIG_IUT.md) (5 min)
3. **Section dépannage** dans [README.md](README.md)
4. **Guide complet** [PROXY_GUIDE.md](PROXY_GUIDE.md)
5. **Documentation Kubernetes** https://kubernetes.io/docs/

---

## 🎯 Objectifs des TPs

### TP01 : Maîtriser l'infrastructure

- Installation Docker, kubectl, Kind
- **Configuration proxy pour environnement IUT**
- Création cluster Kind multi-nœuds
- Installation Ingress Controller
- Déploiement de test

### TP02 : Déployer des applications

- Application simple : VS Code Server
  - Deployment, Service, Ingress
  - PersistentVolumeClaim
  - Secrets
- Application complexe : Guestbook PHP/Redis
  - Architecture multi-tiers
  - Redis Leader/Followers
  - Frontend avec 3 réplicas

---

## 🚀 Commencer maintenant !

```bash
# Étape 1 : Configurer le proxy
./configure-proxy.sh

# Étape 2 : Vérifier
source ~/.bashrc
proxy-check

# Étape 3 : Commencer le TP01
# Ouvrir INSTALL_TP1_RAPIDE.md
```

**Bon courage !** 💪

---

**Version** : 1.0
**Date** : 2025-01-24
**Proxy IUT** : 192.168.0.2:3128
