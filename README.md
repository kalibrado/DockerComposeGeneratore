# Générateur de Docker Compose

Ce script prépare un environnement Linux pour accueillir des containers Docker en installant toutes les dépendances nécessaires au bon fonctionnement de Docker.
Une fois l'environnement préparé, le script propose de générer plusieurs fichiers "docker compose" préconfigurés et de les lancer automatiquement pour créer rapidement des containers.

## Containers disponibles

- AdGuard
- Duck DNS
- Jellyfin
- Minecraft
- Nextcloud
- Portainer
- Proxy Manager Nginx
- Rocket.chat.io (en cours de développement)
- Transmission

## Utilisation

Pour utiliser le script, vous devez d'abord donner les droits d'exécution au fichier avec la commande suivante :

```bash
sudo chmod +x init.sh
```

Ensuite, vous pouvez lancer le script avec la commande suivante :

```bash
sudo ./init.sh
```

Le script vous guidera à travers les étapes et vous posera des questions pour configurer les containers que vous souhaitez générer.

## Utilisation des scripts individuels

Si vous n'avez besoin que d'un ou plusieurs containers et que vous avez déjà préparé votre environnement Linux avec Docker, vous pouvez simplement lancer un script individuel.
Pour ce faire, ouvrez un terminal dans le dossier "scripts/" et donnez les droits d'exécution au script shell que vous voulez exécuter avec la commande suivante :

```bash
sudo chmod +x nextcloud.sh
```

Ensuite, vous pouvez lancer le script avec la commande suivante :

```bash
sudo ./nextcloud.sh
```

Le script démarrera automatiquement le container et vous n'aurez plus qu'à attendre pour profiter de votre nouveau container.
