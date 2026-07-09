#!/bin/bash
# Stoppe et supprime les conteneurs de test locaux crees par test-local.sh

SERVICES=("client" "posts" "comments" "query" "moderation" "event-bus")

for service in "${SERVICES[@]}"; do
  docker rm -f "test-$service" >/dev/null 2>&1 && echo "Arrete : test-$service"
done

echo "Nettoyage termine."
