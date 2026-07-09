#!/bin/bash
# Construit les 6 images Docker du projet
# Usage : ./scripts/build-images.sh <dockerhub-username> [tag]
# Exemple : ./scripts/build-images.sh steven42 v1

set -e

DOCKERHUB_USER=${1:?"Usage: ./build-images.sh <dockerhub-username> [tag]"}
TAG=${2:-latest}

SERVICES=("client" "posts" "comments" "query" "moderation" "event-bus")

echo "Construction des images pour l'utilisateur Docker Hub : $DOCKERHUB_USER (tag: $TAG)"
echo ""

for service in "${SERVICES[@]}"; do
  echo "-> Building $service ..."
  docker build -t "$DOCKERHUB_USER/$service:$TAG" "./$service"
  echo "   OK: $DOCKERHUB_USER/$service:$TAG"
  echo ""
done

echo "Toutes les images ont ete construites."
docker images | grep "$DOCKERHUB_USER"
