# Fichiers d'exemples pour le TP02

## Problème du copier-coller depuis le PDF

Lorsque vous copiez du code YAML depuis un PDF, l'indentation peut être corrompue car :
- Les espaces sont parfois remplacés par des caractères non imprimables
- Les numéros de ligne peuvent être inclus dans le copier-coller
- Les caractères spéciaux (`:`, `-`) peuvent être mal encodés

## Solution

Utilisez les fichiers YAML fournis dans ce dossier :

### VS Code Server (`vs_code/`)
```bash
# Déployer tous les manifests
kubectl apply -f vs_code/

# Ou déployer individuellement
kubectl apply -f vs_code/storage.yaml
kubectl apply -f vs_code/compute.yaml
kubectl apply -f vs_code/network.yaml
kubectl apply -f vs_code/secret.yaml
```

### Guestbook PHP/Redis (`guestbook-php/`)
```bash
# Déployer tous les manifests
kubectl apply -f guestbook-php/

# Ou déployer par étapes
kubectl apply -f guestbook-php/redis-leader-deployment.yaml
kubectl apply -f guestbook-php/redis-leader-service.yaml
kubectl apply -f guestbook-php/redis-follower-deployment.yaml
kubectl apply -f guestbook-php/redis-follower-service.yaml
kubectl apply -f guestbook-php/frontend-deployment.yaml
kubectl apply -f guestbook-php/frontend-service.yaml
```

## Vérification de l'indentation YAML

Pour vérifier que votre fichier YAML est valide :

```bash
# Avec yamllint (si installé)
yamllint fichier.yaml

# Avec kubectl
kubectl apply --dry-run=client -f fichier.yaml
```

## Astuce : Copier-coller propre

Si vous devez absolument copier depuis le PDF :
1. Copiez le code
2. Collez dans un éditeur de texte
3. Remplacez tous les espaces par des vrais espaces (pas des caractères Unicode)
4. Vérifiez l'indentation (2 espaces par niveau en YAML)
5. Supprimez les numéros de ligne s'ils ont été copiés

## Indentation YAML correcte

```yaml
apiVersion: apps/v1  # Pas d'indentation
kind: Deployment
metadata:            # Pas d'indentation
  name: exemple      # 2 espaces
  labels:            # 2 espaces
    app: mon-app     # 4 espaces (2 niveaux)
spec:                # Pas d'indentation
  replicas: 1        # 2 espaces
  template:          # 2 espaces
    spec:            # 4 espaces
      containers:    # 6 espaces
      - name: app    # 6 espaces + tiret
        image: nginx # 8 espaces
```

## Fichiers disponibles

- **vs_code/** : Exemples pour déployer VS Code Server
  - `compute.yaml` : Deployment du pod
  - `storage.yaml` : PersistentVolumeClaim
  - `network.yaml` : Service + Ingress
  - `secret.yaml` : Secret pour le mot de passe

- **guestbook-php/** : Application Guestbook complète
  - `redis-leader-deployment.yaml`
  - `redis-leader-service.yaml`
  - `redis-follower-deployment.yaml`
  - `redis-follower-service.yaml`
  - `frontend-deployment.yaml`
  - `frontend-service.yaml`
