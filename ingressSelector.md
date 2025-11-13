### 1.3 ⚠️ Problème Rencontré : Ingress Controller sur le Mauvais Nœud

**Symptôme :** Impossible d'accéder aux applications via `http://localhost`

**Diagnostic :**

```bash
# Vérifier où tourne l'ingress controller
kubectl get pods -n ingress-nginx -o wide
```

**Résultat initial :**
```
NAME                                        READY   STATUS    NODE
ingress-nginx-controller-6bc8c55c76-twb54   1/1     Running   cluster-tp2-control-plane2
```

**Problème identifié :**
- L'ingress controller tourne sur `cluster-tp2-control-plane2`
- Mais le port forwarding 80:80 est configuré uniquement sur `cluster-tp2-control-plane`
- Le label `ingress-ready=true` est sur `cluster-tp2-control-plane`

**Solution :** Forcer l'ingress controller à tourner sur le bon nœud avec un `nodeSelector`

```bash
# Patcher le deployment pour ajouter un nodeSelector
kubectl patch deployment -n ingress-nginx ingress-nginx-controller \
  -p '{"spec":{"template":{"spec":{"nodeSelector":{"ingress-ready":"true"}}}}}'
```

**Vérification après correction :**

```bash
kubectl get pods -n ingress-nginx -o wide
```

**Résultat :**
```
NAME                                       READY   STATUS    NODE
ingress-nginx-controller-bbd9ffff9-m454z   1/1     Running   cluster-tp2-control-plane
```

✅ L'ingress controller tourne maintenant sur le bon nœud !

**Test de connectivité :**

```bash
# Test VS Code
curl -H "Host: mon-app.local" http://localhost
# Résultat : Found. Redirecting to ./login

# Test Guestbook
curl -H "Host: guestbook.local" http://localhost
# Résultat : <html ng-app="redis">...
```