#!/bin/bash
set -e

echo "Configuration du cluster TP2 Kubernetes"

# Couleurs pour l'affichage
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 1. Créer le cluster Kind
echo -e "${BLUE}1. Création du cluster Kind...${NC}"
kind create cluster --name cluster-tp2 --config cluster.yaml

# 2. Installer ingress-nginx avec kustomize
echo -e "${BLUE}2. Installation d'ingress-nginx avec nodeSelector...${NC}"
kubectl apply -k ingress-kustomize/

# 3. Attendre que ingress soit prêt
echo -e "${BLUE}3. Attente de l'ingress controller...${NC}"
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# 4. Vérifier le placement
echo -e "${BLUE}4. Vérification du placement du pod ingress...${NC}"
kubectl get pods -n ingress-nginx -o wide

# 5. Test de connectivité
echo -e "${BLUE}5. Test de connectivité...${NC}"
sleep 5
curl -s -o /dev/null -w "%{http_code}" http://localhost || echo "Port 80 accessible !"

echo -e "${GREEN}✅ Cluster configuré avec succès !${NC}"
echo ""
echo "Commandes utiles :"
echo "  kubectl get nodes"
echo "  kubectl get pods -n ingress-nginx -o wide"
echo "  kubectl apply -f vs_code/        # Déployer VS Code"
echo "  kubectl apply -f guestbook/      # Déployer Guestbook"
