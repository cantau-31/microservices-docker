#!/bin/bash
# Tague et pousse les 6 images sur Docker Hub.
# Pre-requis : avoir un compte Docker Hub et etre connecte (docker login).
#
# Usage : ./scripts/push-images.sh <dockerhub-username> [tag]

set -e

DOCKERHUB_USER=${1:?"Usage: ./push-images.sh <dockerhub-username> [tag]"}
TAG=${2:-latest}

SERVICES=("client" "posts" "comments" "query" "moderation" "event-bus")

echo "Connexion a Docker Hub (si pas deja connecte)..."
docker login

echo ""
for service in "${SERVICES[@]}"; do
  echo "-> Push de $DOCKERHUB_USER/$service:$TAG ..."
  docker push "$DOCKERHUB_USER/$service:$TAG"
  echo ""
done

echo "Toutes les images ont ete poussees sur Docker Hub."
echo "Communique ces noms d'images a Jansen pour ses fichiers Deployment :"
echo ""
for service in "${SERVICES[@]}"; do
  echo "  $service -> $DOCKERHUB_USER/$service:$TAG"
done
