# Docker Compose generator

This script prepares a Linux environment to host Docker containers by installing all the dependencies necessary for Docker to function properly.
Once the environment is prepared, the script generates several preconfigured "docker compose" files and launches them automatically to quickly create containers.

## Containers available

- AdGuard
- Duck DNS
- Jellyfin
- Minecraft
- Nextcloud
- Portainer
- Nginx Proxy Manager
- Rocket.chat.io (under development)
- Transmission

## Use

To use the script, you must first give execute rights to the file with the following command:

```bash
sudo chmod +x init.sh
```

Then you can run the script with the following command:

```bash
sudo ./init.sh
```

The script will walk you through the steps and ask you questions to configure the containers you want to generate.

## Using individual scripts

If you only need one or more containers and you have already prepared your Linux environment with Docker, you can simply run an individual script.
To do this, open a terminal in the "scripts/" folder and give execution rights to the shell script you want to run with the following command:

```bash
sudo chmod +x nextcloud.sh
```

Then you can run the script with the following command:

```bash
sudo ./nextcloud.sh
```

The script will automatically start the container and you will just have to wait to enjoy your new container.