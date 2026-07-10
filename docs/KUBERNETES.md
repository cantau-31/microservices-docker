# Partie Kubernetes — Jansen

Cette partie déploie les six images Docker de l'application dans Kubernetes.
Elle ne modifie pas le code React ou Node.js.

## 1. Ressources créées

Toutes les ressources applicatives sont isolées dans le namespace
`microservices`.

| Composant | Deployment | Service | Port |
|---|---|---|---:|
| Client | `client-depl` | `client-srv` | 3000 |
| Posts | `posts-depl` | `posts-clusterip-srv` | 4000 |
| Comments | `comments-depl` | `comments-srv` | 4001 |
| Query | `query-depl` | `query-srv` | 4002 |
| Moderation | `moderation-depl` | `moderation-srv` | 4003 |
| Event Bus | `event-bus-depl` | `event-bus-srv` | 4005 |

Les noms des Services correspondent exactement aux noms DNS utilisés dans le
code Node.js.

## 2. Choix des images

Par défaut, `k8s/kustomization.yaml` utilise les images locales suivantes :

```text
client:latest
posts:latest
comments:latest
query:latest
moderation:latest
event-bus:latest
```

Pour un cluster qui ne partage pas les images locales de Docker, remplacer
uniquement les valeurs `newName` et `newTag` dans
`k8s/kustomization.yaml` :

```yaml
images:
  - name: client
    newName: <dockerhub-username>/client
    newTag: v1
```

Répéter cette modification pour les six images.

## 3. Contrôleur Ingress

Les manifests utilisent un Ingress de classe `nginx`. Le contrôleur
Ingress NGINX doit donc être installé dans le cluster avant le déploiement.

Avec Minikube :

```bash
minikube addons enable ingress
```

Pour un autre cluster, suivre la procédure d'installation du contrôleur
Ingress NGINX adaptée à cet environnement.

## 4. Validation et déploiement

Afficher le YAML final généré par Kustomize :

```bash
kubectl kustomize k8s/
```

Déployer toutes les ressources :

```bash
kubectl apply -k k8s/
```

Attendre que les six Deployments soient disponibles :

```bash
kubectl rollout status deployment --all -n microservices --timeout=180s
```

## 5. Vérifications

```bash
kubectl get all -n microservices
kubectl get ingress -n microservices
kubectl get events -n microservices --sort-by=.metadata.creationTimestamp
```

Tous les pods doivent être `Running` et afficher `1/1` dans la colonne
`READY`.

En cas d'erreur :

```bash
kubectl describe pod <nom-du-pod> -n microservices
kubectl logs <nom-du-pod> -n microservices
```

Une erreur `ImagePullBackOff` signifie généralement que le nom de l'image
Docker Hub est incorrect, que l'image n'a pas été poussée, ou que le dépôt
est privé sans secret Kubernetes.

## 6. Routes Ingress

| Route | Service cible |
|---|---|
| `/posts/create` | `posts-clusterip-srv:4000` |
| `/posts/?(.*)/comments` | `comments-srv:4001` |
| `/posts` | `query-srv:4002` |
| `/` | `client-srv:3000` |

Les chemins ne sont pas réécrits : chaque service reçoit donc la route HTTP
attendue par son code.

## 7. Test fonctionnel

Après avoir déterminé l'adresse de l'Ingress, ouvrir l'application dans un
navigateur puis :

1. créer un post ;
2. ajouter un commentaire ;
3. vérifier que le commentaire est modéré ;
4. recharger la page et vérifier que les données sont toujours agrégées par
   le service `query`.

Pour tester localement avec un Ingress exposé sur `localhost` :

```bash
curl -i http://localhost/
curl -i http://localhost/posts
```

## 8. Nettoyage

```bash
kubectl delete -k k8s/
```
