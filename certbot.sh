#!/bin/bash

set -euo pipefail

trap 'echo "Script failed on line $LINENO"' ERR

read -p 'Root domain (e.g. example.org without the www subdomain): ' domain
[ -z "$domain" ] && echo "Root domain cannot be empty" && exit 1

read -p 'Email address for registration and recovery with EFF: ' email
[ -z "$email" ] && echo "Email cannot be empty" && exit 1

# Generate a NGINX config with the given domain
dirpath=$(dirname $(dirname "$0"))
[ ! -f "$dirpath"/docker/reverse-proxy/nginx-conf/nginx.conf-sample ] \
    && echo "Sample NGINX config is not found" && exit 1
sed "s/ROOT_DOMAIN/$domain/" "$dirpath"/docker/reverse-proxy/nginx-conf/nginx.conf-sample \
    > "$dirpath"/docker/reverse-proxy/nginx-conf/nginx.conf

if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose is not installed" && exit 1
fi

docker-compose -f "$dirpath"/docker/reverse-proxy/docker-compose.yml up -d

# Create a dummy TLS certificate and private key and 
# restart NGINX to load the dummy certificate
dirname=$(echo $(basename $(dirname $(dirname "$0"))) | sed "s/\.//")
certpath=/var/lib/docker/volumes/${dirname}_certbot/_data/live/$domain/

if ! command -v openssl &> /dev/null; then
    echo "OpenSSL is not installed" && exit 1
fi

mkdir -p "$certpath" && openssl req -x509 -nodes -newkey rsa:4096 -days 1 \
    -keyout "${certpath}privkey.pem" -out "${certpath}fullchain.pem" -subj '/CN=localhost'
docker-compose -f "$dirpath"/docker/reverse-proxy/docker-compose.yml restart nginx

# Remove the dummy certificate and private key before 
# requesting a signed TLS certificate with Certbot
# and restart NGINX to load the new certificate
rm -r $(dirname "$certpath")
docker-compose -f "$dirpath"/docker/reverse-proxy/docker-compose.yml run --rm --entrypoint "\
    certbot certonly --webroot --webroot-path=/var/www/html --email $email --agree-tos \
    --eff-email --force-renewal -d $domain -d www.$domain" certbot
docker-compose -f "$dirpath"/docker/reverse-proxy/docker-compose.yml restart nginx

if ! command -v systemctl &> /dev/null; then
    echo "systemctl is not installed" && exit 1
fi

systemctl enable docker
