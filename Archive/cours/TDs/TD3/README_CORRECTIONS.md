# Corrections TD3 - Helm

## Documents disponibles

### 1. CORRECTION_TD3_Helm_PEDAGOGIQUE.pdf (Recommandé pour les étudiants)
**378 KB - 36 pages - Version détaillée et pédagogique**

Ce document contient des explications détaillées pour chaque étape :

#### Structure
- **Introduction** : Présentation de Helm et objectifs pédagogiques
- **Exercice 1** : Chart de base avec explications pas à pas
  - Concepts clés illustrés dans des encadrés colorés
  - Explications du rôle de chaque ressource Kubernetes
  - Commandes avec résultats attendus
- **Exercice 2** : Modularité et dépendances
  - Pourquoi séparer en sous-Charts
  - Structure de dépendances expliquée
- **Exercice 3** : Variabilisation avec values.yaml
  - Syntaxe des templates Helm
  - Ordre de priorité des valeurs
  - Exemples de surcharge
- **Exercice 4** : Labels communs avec helpers
  - Création de templates réutilisables
  - Fonctions de template (include, indent)
- **Tests et validation** : Commandes complètes de vérification
- **Commandes Helm essentielles** : Référence rapide
- **Bonnes pratiques** : Versioning, organisation, sécurité
- **Aller plus loin** : Hooks, tests, repositories
- **Troubleshooting** : Problèmes courants et solutions

#### Points forts
✅ Encadrés pédagogiques colorés (Info, Warning, Success)
✅ Explications détaillées de chaque concept
✅ Code commenté ligne par ligne
✅ Résultats attendus pour chaque commande
✅ Section troubleshooting complète
✅ Ressources pour aller plus loin

### 2. CORRECTION_TD3_Helm.pdf (Version concise)
**224 KB - Document de référence rapide**

Version plus concise pour consultation rapide.

## Utilisation recommandée

### Pour les étudiants débutants
Utiliser **CORRECTION_TD3_Helm_PEDAGOGIQUE.pdf** :
- Lire les encadrés explicatifs
- Suivre les étapes pas à pas
- Comprendre le "pourquoi" de chaque action

### Pour les étudiants avancés
Utiliser **CORRECTION_TD3_Helm.pdf** :
- Référence rapide
- Focus sur les commandes

## État du TD3 sur la VM 192.168.56.11

### Déploiement actuel
```
Namespace: td3
Release: vs-code-release (revision 3)
Chart: vs-code-chart-0.4
Status: deployed
```

### Ressources
```
- Pod: code-server (Running)
- Service: NodePort 30080
- PVC: 5Gi (Bound)
- Labels: orga=IUT-C3, res=R5-09
```

### Charts créés
```
~/testlab/
├── vs-code-chart-0.1.tgz  (Chart de base)
├── vs-code-chart-0.2.tgz  (Avec dépendance storage)
├── vs-code-chart-0.3.tgz  (Variabilisé)
├── vs-code-chart-0.4.tgz  (Avec labels communs) ⭐ VERSION FINALE
├── storage-chart-0.1.tgz  (Gestion du PVC)
└── common-chart-0.1.tgz   (Labels standardisés)
```

## Accès au service

### Via port-forward (recommandé)
```bash
# Sur la VM
kubectl port-forward -n td3 svc/code-server 8080:8080 --address=0.0.0.0

# Puis dans un navigateur
http://192.168.56.11:8080
```

### Tests de vérification
```bash
# Liste des releases
helm list -n td3

# Historique
helm history vs-code-release -n td3

# Ressources
kubectl get all,pvc -n td3

# Test connectivité
kubectl run test-curl --rm -it --restart=Never \
  --image=curlimages/curl -- curl -I http://code-server:8080
```

## Compétences validées

- ✅ Création de Charts Helm
- ✅ Gestion des dépendances
- ✅ Variabilisation avec values.yaml
- ✅ Templates Helm et helpers
- ✅ Labels standardisés
- ✅ Packaging et déploiement
- ✅ Tests et validation

## Ressources complémentaires

- **Documentation Helm** : https://helm.sh/docs/
- **Artifact Hub** : https://artifacthub.io/
- **Best Practices** : https://helm.sh/docs/chart_best_practices/

---

Maxime Lambert - IUT Grand Ouest Normandie - R5.09 - 2024/2025
