# Compte-Rendu TP3 - Kubernetes Autoscaling (HPA)

* **Date :** 2025-11-11
* **Étudiant :** [Votre Nom]
* **Objectif :** Comprendre et mettre en œuvre l'autoscaling horizontal (HPA) dans Kubernetes

---

## 1. Prérequis et Configuration du Cluster

### 1.1 Création du cluster Kind

J'ai créé un cluster Kubernetes avec Kind comprenant :
- 1 nœud control-plane
- 2 nœuds workers

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
  - containerPort: 443
    hostPort: 443
- role: worker
- role: worker
```

**Commande :**
```bash
kind create cluster --name cluster-tp3 --config cluster.yaml
```

### 1.2 Installation de l'Ingress Nginx

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s
```

### 1.3 Installation et configuration de Metrics-Server

Le metrics-server est essentiel pour le HPA car il collecte les métriques CPU et mémoire des pods.

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch -n kube-system deployment metrics-server --type=json \
  -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
```

**Vérification du metrics-server :**
```bash
kubectl get --raw "/apis/metrics.k8s.io/v1beta1/nodes" | jq .
```

**Résultat :** Le metrics-server retourne les métriques des 3 nœuds du cluster avec leur utilisation CPU et mémoire.

---

## 2. Questions Théoriques

### Q1: Quelle est la différence entre un scaling horizontal et vertical ?

**Scaling Horizontal :**
- Ajoute ou retire des pods (répliques)
- Modifie le nombre d'instances de l'application
- Permet une meilleure distribution de charge
- Géré par le HorizontalPodAutoscaler (HPA)

**Scaling Vertical :**
- Modifie les ressources CPU et/ou RAM d'un pod existant
- Change les limites et requêtes de ressources
- Nécessite souvent un redémarrage du pod
- Géré par le VerticalPodAutoscaler (VPA)

### Q2: Quels objets Kubernetes peut-on scale avec le HPA ?

Le HPA peut mettre à l'échelle :
- **Deployment** (le plus courant)
- **StatefulSet**
- **ReplicaSet**
- Tout objet implémentant l'interface `scale`

**Objets NON scalables :** DaemonSet (car il doit tourner sur chaque nœud)

### Q3: Pourquoi scaler une application ?

- **Performance** : Gérer les pics de charge
- **Disponibilité** : Assurer la continuité de service
- **Coût** : Optimiser l'utilisation des ressources
- **Résilience** : Répartir la charge sur plusieurs instances
- **Adaptabilité** : S'ajuster automatiquement à la demande

---

## 3. Construction de l'Application Express

### 3.1 Structure de l'application

L'application Express expose deux endpoints :
- `/cpu` : Génère une charge CPU via calcul de Fibonacci(42)
- `/memory` : Génère une charge mémoire via création d'un grand tableau

### 3.2 Build de l'image Docker

**Commande utilisée :**
```bash
docker build -t mon-app:v0.1 .
```

Cette commande :
- Crée une image Docker nommée `mon-app` avec le tag `v0.1`
- Utilise le Dockerfile présent dans le répertoire courant
- Installe les dépendances Node.js via `npm ci`
- Copie le fichier `server.js` dans le conteneur

**Chargement dans Kind :**
```bash
kind load docker-image mon-app:v0.1 --name cluster-tp3
```

---

## 4. Déploiement Kubernetes

### 4.1 Manifests déployés

Le fichier `mon-app.yml` contient :

1. **Deployment** : Déploie l'application Express avec :
   - Image: `mon-app:v0.1`
   - Resources limits: 500m CPU, 256Mi RAM
   - Resources requests: 200m CPU, 128Mi RAM

2. **Service** : Expose le déploiement sur le port 8080

3. **Ingress** : Configure l'accès externe via `mon-app.local`

### Q4: Que déploie ce manifest kubernetes ?

Le manifest déploie une stack complète :
- Un **Deployment** avec 1 réplica initial de l'application Express
- Un **Service** de type ClusterIP pour exposer les pods en interne
- Un **Ingress** pour router le trafic HTTP externe vers le service

### Q5: Pourquoi mettre un ingress dans ce contexte ?

L'Ingress est nécessaire pour :
- **Accès externe** : Permet d'accéder à l'application depuis l'extérieur du cluster
- **Routage HTTP** : Route les requêtes vers le bon service basé sur le hostname
- **Test de charge** : Facilite les tests avec curl depuis la machine hôte
- **Simulation réaliste** : Reproduit un environnement de production

---

## 5. Configuration du HPA

### 5.1 Ressource HPA

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: express
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: express
  minReplicas: 1
  maxReplicas: 10
  behavior:
    scaleUp:
      policies:
      - type: Pods
        value: 1
        periodSeconds: 60
    scaleDown:
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 80
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 70
```

### 5.2 Explications des politiques

**ScaleUp Policy :**
- Type: Pods
- Value: 1
- Period: 60 secondes
- **Signification** : Le HPA peut ajouter maximum 1 pod par minute lors d'un scale-up

**ScaleDown Policy :**
- Type: Percent
- Value: 10
- Period: 60 secondes
- **Signification** : Le HPA peut réduire de 10% des réplicas actuels par minute

### Q6: Comment afficher la liste des HPA ?

```bash
kubectl get hpa
# ou
kubectl get horizontalpodautoscaler
```

### Q7: Donner la liste des HPA présent sur le cluster

```
NAME      REFERENCE            TARGETS             MINPODS   MAXPODS   REPLICAS   AGE
express   Deployment/express   0%/80%, 8%/70%      1         10        1          2m
```

---

## 6. Tests d'Autoscaling

### 6.1 Test de charge CPU

**Commande de génération de charge :**
```bash
kubectl run -i --tty load-generator --rm --image=busybox:1.28 --restart=Never \
  -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://express:8080/cpu; done"
```

**Résultats observés :**

**Avant la charge (T=0) :**
```
NAME      REFERENCE            TARGETS           MINPODS   MAXPODS   REPLICAS
express   Deployment/express   0%/80%, 8%/70%    1         10        1
```

**Après 60 secondes (T=60s) :**
```
NAME      REFERENCE            TARGETS             MINPODS   MAXPODS   REPLICAS
express   Deployment/express   116%/80%, 34%/70%   1         10        2
```
- CPU à 116% (dépassement du seuil de 80%)
- **Scale-up** : 1 → 2 réplicas
- Nouveau pod créé : `express-6896f6645f-clgfk`

**Après 120 secondes (T=120s) :**
```
NAME      REFERENCE            TARGETS            MINPODS   MAXPODS   REPLICAS
express   Deployment/express   49%/80%, 34%/70%   1         10        3
```
- **Scale-up** : 2 → 3 réplicas
- Troisième pod créé : `express-6896f6645f-ts9kb`

### Q8: Que remarquez-vous dans les 2 premiers shells, expliquer pourquoi ?

**Observation :**
- Le CPU monte au-dessus du seuil de 80%
- Le HPA réagit en créant de nouveaux pods
- Les nouveaux pods prennent quelques secondes à démarrer
- Une fois démarrés, ils partagent la charge
- Le CPU redescend progressivement

**Explication :**
Le HPA surveille les métriques toutes les 15 secondes (paramètre par défaut). Quand le CPU dépasse 80%, il déclenche un scale-up selon la politique définie (1 pod/minute max).

### Q9: Combien de temps le HPA met-il à scale-up un nouveau pod ?

**Réponse :** Le HPA a mis environ **30-35 secondes** entre la détection du dépassement de seuil et la création effective d'un nouveau pod Running.

Ce délai comprend :
- Temps de scraping des métriques (~15s)
- Temps de décision du HPA (~5s)
- Temps de création et démarrage du pod (~15-20s)

### 6.2 Test de scale-down

**Arrêt de la charge :**
Après avoir tué le générateur de charge, observation du comportement de scale-down.

**T+90s après arrêt de la charge :**
```
NAME      REFERENCE            TARGETS           MINPODS   MAXPODS   REPLICAS
express   Deployment/express   0%/80%, 26%/70%   1         10        3
```
- CPU à 0% mais toujours 3 réplicas
- **Raison** : Délai de stabilisation avant scale-down (cooldown period)

**T+240s après arrêt de la charge :**
```
NAME      REFERENCE            TARGETS           MINPODS   MAXPODS   REPLICAS
express   Deployment/express   0%/80%, 26%/70%   1         10        3

PODS:
express-6896f6645f-ts9kb   1/1     Terminating   0          5m18s
```
- Début du scale-down
- Un pod passe en statut Terminating

**T+270s après arrêt de la charge :**
```
NAME      REFERENCE            TARGETS           MINPODS   MAXPODS   REPLICAS
express   Deployment/express   0%/80%, 34%/70%   1         10        2
```
- **Scale-down** : 3 → 2 réplicas complété

### Q10: Combien de temps le HPA met-il à scale-down un pod ?

**Réponse :** Le HPA a mis environ **4-5 minutes** pour commencer le scale-down après l'arrêt de la charge.

**Détails :**
- Délai de stabilisation par défaut : 5 minutes
- Temps de terminaison gracieuse du pod : ~30 secondes
- Politique : Réduction de 10% des réplicas par minute

Ce délai important est voulu pour éviter le "flapping" (oscillations rapides entre scale-up et scale-down).

---

## 7. Test de l'endpoint /memory

**Tentative :**
```bash
curl -H "Host: mon-app.local" http://localhost/memory
```

**Résultat :**
```
curl: (56) Recv failure: Connexion ré-initialisée par le correspondant
```

### Q11: Que remarquez-vous, expliquer pourquoi ?

**Observation :**
- La connexion est fermée avant la fin de la requête
- Pas de réponse du serveur

**Explication :**
- L'allocation d'un tableau de 20 millions d'éléments consomme énormément de mémoire
- Le pod peut être OOMKilled (Out Of Memory Killed) par Kubernetes
- Ou le processus Node.js plante avant de répondre
- La limite de mémoire du pod (256Mi) est probablement dépassée

**Pour un test efficace de mémoire, il faudrait :**
- Réduire la taille du tableau
- Augmenter les limites de mémoire du pod
- Ou générer la charge progressivement

### Q12: Combien de temps le HPA met-il à scale-up un nouveau pod (memory) ?

**Réponse :** Impossible de mesurer précisément car les requêtes /memory échouent systématiquement.

Théoriquement, si le seuil de 70% de mémoire était dépassé, le HPA réagirait avec le même timing que pour le CPU (30-60 secondes).

---

## 8. Analyse du Fonctionnement du HPA

### 8.1 Mécanisme de fonctionnement

Le HPA fonctionne selon cette boucle :

1. **Collecte des métriques** (toutes les 15s par défaut)
   - Metrics-server collecte CPU/RAM des pods
   - HPA récupère ces métriques via l'API

2. **Calcul du nombre de réplicas nécessaires**
   ```
   replicas_souhaités = ceil(replicas_actuels * (métrique_actuelle / métrique_cible))
   ```

3. **Application des politiques (behavior)**
   - Vérification des limites min/max
   - Application des contraintes de vitesse (1 pod/min pour scale-up)

4. **Mise à jour du Deployment**
   - Le HPA modifie le champ `replicas` du Deployment
   - Le Deployment Controller crée/supprime les pods

### 8.2 Comportement observé

**Points clés :**
- ✅ Scale-up rapide en cas de charge (60s pour ajouter un pod)
- ✅ Scale-down lent et prudent (5min de stabilisation)
- ✅ Respect des politiques définies (1 pod/min max en scale-up)
- ✅ Métriques multiples (CPU ET mémoire)

---

## 9. Question Bonus

### Comment scaler une application basée sur des métriques custom (non CPU/mémoire) ?

**Solutions :**

#### 1. Custom Metrics API
Utiliser des métriques personnalisées via l'API `custom.metrics.k8s.io` :

```yaml
metrics:
- type: Pods
  pods:
    metric:
      name: http_requests_per_second
    target:
      type: AverageValue
      averageValue: "1000"
```

**Prérequis :**
- Déployer un adaptateur de métriques (ex: Prometheus Adapter)
- Configurer l'exposition des métriques custom
- Mapper les métriques Prometheus vers l'API Kubernetes

#### 2. External Metrics API
Utiliser des métriques provenant de sources externes via `external.metrics.k8s.io` :

```yaml
metrics:
- type: External
  external:
    metric:
      name: queue_messages_ready
      selector:
        matchLabels:
          queue_name: "my-queue"
    target:
      type: AverageValue
      averageValue: "30"
```

**Exemples d'usage :**
- Nombre de messages dans une file RabbitMQ
- Métriques CloudWatch (AWS)
- Latence mesurée par un système externe

#### 3. KEDA (Kubernetes Event Driven Autoscaling)
Alternative au HPA natif, KEDA supporte 50+ sources de métriques :
- Files de messages (RabbitMQ, Kafka, SQS)
- Bases de données
- Métriques Cloud Provider
- HTTP traffic
- etc.

**Exemple KEDA :**
```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: rabbitmq-scaledobject
spec:
  scaleTargetRef:
    name: my-app
  minReplicaCount: 1
  maxReplicaCount: 10
  triggers:
  - type: rabbitmq
    metadata:
      queueName: my-queue
      queueLength: "5"
```

---

## 10. Conclusion

### Objectifs atteints

- ✅ **Installation et configuration** d'un cluster Kubernetes avec metrics-server
- ✅ **Création** d'une application Express de test avec endpoints CPU/mémoire
- ✅ **Déploiement** avec Deployment, Service et Ingress
- ✅ **Configuration** d'un HPA avec métriques CPU et mémoire
- ✅ **Tests réussis** de scale-up (1→3 réplicas en 2 minutes)
- ✅ **Observation** du scale-down (3→2 réplicas après 5 minutes)
- ✅ **Compréhension** des mécanismes d'autoscaling

### Points clés retenus

1. **Le HPA est essentiel** pour gérer automatiquement la charge
2. **Metrics-server** est un prérequis indispensable
3. **Les politiques de scaling** permettent de contrôler finement le comportement
4. **Le scale-down est volontairement lent** pour éviter l'instabilité
5. **Les limites de ressources** doivent être bien dimensionnées

### Améliorations possibles

- Utiliser des métriques custom (requêtes HTTP/s)
- Implémenter du Vertical Pod Autoscaling (VPA)
- Tester avec des charges plus réalistes
- Ajouter du monitoring (Prometheus + Grafana)
- Configurer des alertes sur les événements de scaling

---

## Annexes

### Commandes utiles

```bash
# Voir les événements HPA
kubectl describe hpa express

# Voir les logs du metrics-server
kubectl logs -n kube-system deployment/metrics-server

# Surveiller en temps réel
watch -n 1 kubectl get hpa,pods

# Voir l'historique des événements
kubectl get events --sort-by=.metadata.creationTimestamp

# Obtenir les métriques d'un pod
kubectl top pod <pod-name>
```

### Ressources consultées

- [Documentation Kubernetes HPA](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Metrics Server](https://github.com/kubernetes-sigs/metrics-server)
- [Kind - Local Kubernetes](https://kind.sigs.k8s.io/)

---


