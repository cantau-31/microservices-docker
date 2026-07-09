#!/bin/bash
# Demarre les 6 conteneurs localement pour un test rapide (santé de chaque service).
# ATTENTION : lances isolement, les services ne pourront pas se parler entre eux
# (ils cherchent des noms DNS Kubernetes comme posts-clusterip-srv).
# Ce script sert juste a verifier que chaque image demarre et repond sur son port.
#
# Usage : ./scripts/test-local.sh <dockerhub-username> [tag]

set -e

DOCKERHUB_USER=${1:?"Usage: ./test-local.sh <dockerhub-username> [tag]"}
TAG=${2:-latest}

declare -A PORTS=(
  [client]=3000
  [posts]=4000
  [comments]=4001
  [query]=4002
  [moderation]=4003
  [event-bus]=4005
)

echo "Nettoyage des anciens conteneurs de test (si presents)..."
for service in "${!PORTS[@]}"; do
  docker rm -f "test-$service" >/dev/null 2>&1 || true
done

echo ""
echo "Demarrage des conteneurs..."
for service in "${!PORTS[@]}"; do
  port=${PORTS[$service]}
  docker run -d --name "test-$service" -p "$port:$port" "$DOCKERHUB_USER/$service:$TAG"
  echo "  $service -> http://localhost:$port"
done

echo ""
echo "Attente de 5 secondes pour laisser les conteneurs demarrer..."
sleep 5

echo ""
echo "Etat des conteneurs :"
docker ps --filter "name=test-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "Pour voir les logs d'un service : docker logs test-<nom-du-service>"
echo "Pour tout arreter et nettoyer     : ./scripts/stop-local.sh"
