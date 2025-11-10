#!/bin/bash

# Script pour installer Docker Compose v2

set -e

echo "Installation de Docker Compose v2..."

# Télécharger Docker Compose v2
DOCKER_COMPOSE_VERSION="v2.24.0"
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Rendre exécutable
sudo chmod +x /usr/local/bin/docker-compose

# Créer un lien symbolique pour docker compose (commande native)
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

echo "Docker Compose v2 installé avec succès!"
echo ""
echo "Vérification de la version:"
docker-compose --version

echo ""
echo "Vous pouvez maintenant utiliser:"
echo "  docker-compose -f docker-compose.minikube.yml up -d --build"
echo "OU"
echo "  docker compose -f docker-compose.minikube.yml up -d --build"
