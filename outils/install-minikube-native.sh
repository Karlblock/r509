#!/bin/bash

# Script pour installer Minikube nativement sur Parrot OS

set -e

echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║  Installation de Minikube nativement sur Parrot OS               ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""

# Vérifier si déjà installé
if command -v minikube &> /dev/null; then
    echo "✓ Minikube est déjà installé : $(minikube version --short)"
    read -p "Voulez-vous réinstaller ? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

echo "1. Installation de Minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64
echo "✓ Minikube installé"

echo ""
echo "2. Installation de kubectl..."
if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    echo "✓ kubectl installé"
else
    echo "✓ kubectl déjà installé : $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
fi

echo ""
echo "3. Vérification des prérequis..."
echo "  Docker: $(docker --version)"
echo "  Minikube: $(minikube version --short)"
echo "  kubectl: $(kubectl version --client --short 2>/dev/null || echo "installed")"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║  Installation terminée !                                          ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""
echo "Pour démarrer Minikube :"
echo "  minikube start --driver=docker --memory=3000mb --cpus=2"
echo ""
echo "Commandes utiles :"
echo "  minikube status       - Voir le statut"
echo "  minikube stop         - Arrêter"
echo "  minikube delete       - Supprimer"
echo "  minikube dashboard    - Ouvrir le dashboard"
echo ""
