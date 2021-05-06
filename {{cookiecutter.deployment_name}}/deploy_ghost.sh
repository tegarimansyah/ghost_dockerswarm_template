#!/bin/bash

set -e

# Connect to your VPS using ssh
PATH_TO_PRIVATE_KEY='~/.ssh/your-private-key'
USERNAME='username'
HOST='host_or_ip_of_your_server'
IP_SERVER='ip_of_your_server' # For A record from cloudflare
CLOUDFLARE_ZONE='long_random_alphanumeric' # Each zone (yourdomain.com) on CloudFlare has a unique number identifier. If you need to locate the zoneid for a domain, simply go to the "Reports and Stats' link for that domain (the zone id appears at the end with an equal sign, such as zid=xxxxxx).
CLOUDFLARE_TOKEN='token_from_cloudflare' # https://dash.cloudflare.com/profile/api-tokens
CONFIG_FILE=config.production.json

confirm() {
    read -r -p "$1 [Y/n] " response
    case "$response" in
        [yY][eE][sS]|[yY]|"") 
            true
            ;;
        *)
            false
            ;;
    esac
}

# Login to server
ssh-add $PATH_TO_PRIVATE_KEY
export DOCKER_HOST=ssh://$USERNAME@$HOST


confirm "Set domain in cloudflare? " && \
    curl -X POST "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE/dns_records" \
     -H "Content-Type:application/json" \
     -H "Authorization: Bearer $CLOUDFLARE_TOKEN"
     --data "{\"type\":\"A\",\"name\":\"{{cookiecutter.domain}}\",\"content\":\"$IP_SERVER\",\"ttl\":120,\"priority\":10,\"proxied\":false}" || \
    true

confirm "Create secret and volume? " && \
    docker secret create {{cookiecutter.deployment_name}}-secret config.production.json && \
    docker volume create {{cookiecutter.deployment_name}}-volume  || \
    true

docker stack deploy -c {{cookiecutter.deployment_name}}.yml {{cookiecutter.deployment_name}}

GREEN='\033[0;32m'
NC='\033[0m' # No Color
echo -e """
\nDone\nOpen your website:

\t${GREEN}https://{{cookiecutter.domain}}

${NC}Thank you for using ghost-docker-swarm snippet code by Tegar Imansyah."""
