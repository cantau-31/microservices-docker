# Partie Docker — Steven

Cette page documente tout le travail Docker réalisé pour le projet, en vue de la
soutenance et de la reprise par Jansen pour le déploiement Kubernetes.

## 1. Prérequis vérifiés

- Docker installé et fonctionnel : `docker --version` et `docker info`
- Compte Docker Hub créé et accessible : `docker login`

## 2. Dockerfiles

Chaque service (`client`, `posts`, `comments`, `query`, `moderation`, `event-bus`)
possède son propre `Dockerfile` à la racine de son dossier, basé sur l'image
officielle légère `node:alpine`.

Contenu type (identique pour les 6 services) :

```dockerfile
FROM node:alpine

WORKDIR /app

COPY package.json ./
RUN npm install

COPY ./ ./

CMD ["npm", "start"]
```

Pourquoi cette structure ?
- `node:alpine` : image Node.js minimale (quelques Mo au lieu de plusieurs
  centaines de Mo pour l'image `node` complète), donc build et déploiement
  plus rapides.
- On copie `package.json` **avant** le reste du code : Docker met en cache la
  couche `npm install` tant que les dépendances ne changent pas, ce qui
  accélère les rebuilds quand seul le code source évolue.
- `CMD ["npm", "start"]` : lance le script `start` défini dans le
  `package.json` de chaque service.

## 3. Construction des images

```bash
./scripts/build-images.sh <dockerhub-username> [tag]
# exemple :
./scripts/build-images.sh steven42 v1
```

Ce script construit les 6 images suivantes :

| Service     | Image                                  | Port  |
|-------------|-----------------------------------------|-------|
| client      | `<user>/client:<tag>`                  | 3000  |
| posts       | `<user>/posts:<tag>`                   | 4000  |
| comments    | `<user>/comments:<tag>`                | 4001  |
| query       | `<user>/query:<tag>`                   | 4002  |
| moderation  | `<user>/moderation:<tag>`              | 4003  |
| event-bus   | `<user>/event-bus:<tag>`               | 4005  |

## 4. Tests locaux (avant publication)

```bash
./scripts/test-local.sh <dockerhub-username> [tag]
```

Ce script démarre chaque image dans son propre conteneur, sur son port
attendu, et affiche leur statut. **Limite connue** : les conteneurs sont
isolés les uns des autres ici, donc les appels inter-services (ex :
`posts` -> `event-bus`) échoueront tant qu'ils ne tournent pas dans le même
réseau Kubernetes avec les bons noms de service. Ce test sert uniquement à
vérifier que chaque image démarre correctement et répond sur son port.

Pour arrêter et nettoyer :

```bash
./scripts/stop-local.sh
```

Vérification des logs d'un conteneur en cas d'erreur :

```bash
docker logs test-posts
```

## 5. Publication sur Docker Hub

```bash
./scripts/push-images.sh <dockerhub-username> [tag]
```

Ce script se connecte à Docker Hub puis pousse les 6 images.

## 6. Communication à Jansen (partie Kubernetes)

Une fois les images poussées, Jansen a besoin exactement de ces références
d'image pour ses fichiers `Deployment` dans `k8s/` :

```
<dockerhub-username>/client:<tag>
<dockerhub-username>/posts:<tag>
<dockerhub-username>/comments:<tag>
<dockerhub-username>/query:<tag>
<dockerhub-username>/moderation:<tag>
<dockerhub-username>/event-bus:<tag>
```

Attention aux noms de service attendus côté Kubernetes (différents des noms
d'image Docker) :

- `client-srv`
- `posts-clusterip-srv`
- `comments-srv`
- `query-srv`
- `moderation-srv`
- `event-bus-srv`

## 7. Versionnement des images

Pour la soutenance, éviter de ne travailler qu'en `latest` (Kubernetes ne
retire pas toujours une image déjà en cache sur un nœud, ce qui peut masquer
un bug de code corrigé). Recommandation : utiliser un tag explicite à chaque
changement de code, par exemple `v1`, `v2`, ou un tag court basé sur le hash
du commit git (`git rev-parse --short HEAD`).

## 8. Erreurs fréquentes rencontrées / à surveiller

- **`npm install` échoue dans le conteneur mais fonctionne en local** :
  vérifier la version de Node dans `node:alpine` vs la version utilisée en
  local (`node --version`), certains packages nécessitent des versions
  précises.
- **Le service démarre mais crashe immédiatement** : vérifier les logs
  (`docker logs <conteneur>`) et s'assurer qu'aucune variable d'environnement
  requise n'est manquante (ex : URL d'un autre service).
- **Image très volumineuse** : vérifier qu'un `.dockerignore` exclut bien
  `node_modules` du contexte de build (sinon `COPY ./ ./ ` copie un
  `node_modules` local incompatible avec l'image alpine).

## 9. Points pour la soutenance (partie Docker)

- Pourquoi `node:alpine` plutôt que `node` standard.
- Le rôle du cache de layers Docker (ordre des instructions dans le
  Dockerfile).
- La différence entre un tag d'image Docker et un nom de service Kubernetes.
- Le fait que chaque microservice est indépendant : une seule image par
  service, un seul processus par conteneur (principe de responsabilité
  unique appliqué à l'infra).
