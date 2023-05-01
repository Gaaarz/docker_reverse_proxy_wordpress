# How to Setup a Reverse Proxy and WordPress with Docker Compose
## Prerequisites

- Docker and [Docker Compose](https://docs.docker.com/compose/) installed on your server.
- A domain linked to your server with an A DNS record.
- A password for the MySQL and WordPress databases. You'll enter this in the Docker Compose environment statements file at `~/docker/website/`.
Download a copy of the app with `git clone`.
## Step 1: Clone the Repository
Clone the repository and navigate into the new directory:
```
git clone https://github.com/Gaaarz/docker_reverse_proxy_wordpress ~/docker/
cd ~/docker/
```
## Step 2: Create a Docker Network
Create a Docker network. This example uses "network" as the name, but you can change this to suit your needs. If you do, remember to adjust the Docker Compose file accordingly.
```
sudo docker network create network
```
## Step 3: Generate SSL/TLS Certificates
You can either generate SSL/TLS certificates automatically or manually.
### Automatic Method
```
sudo chmod +x ~/docker/certbot.sh && sudo ~/docker/certbot.sh
```
### Manual Method
Prompt for the root domain and email address:
```
read -p 'Root domain (e.g., example.org without the www subdomain): ' domain
[ -z "$domain" ] && echo "Root domain cannot be empty" && exit 1

read -p 'Email address for registration and recovery with EFF: ' email
[ -z "$email" ] && echo "Email cannot be empty" && exit 1
```
Generate a NGINX config with the given domain.
```
[ -f ./nginx-conf/nginx.conf-sample ] && \
    sed "s/ROOT_DOMAIN/$domain/" ./nginx-conf/nginx.conf-sample > ./nginx-conf/nginx.conf
```
Create a dummy TLS certificate and private key, then start NGINX.
```
dirname=$(echo $(basename $(pwd)) | sed "s/\.//")
path=/var/lib/docker/volumes/${dirname}_certbot/_data/live/$domain/
sudo mkdir -p $path
sudo openssl req -x509 -nodes -newkey rsa:4096 -days 1 \
    -keyout ${path}privkey.pem -out ${path}fullchain.pem -subj '/CN=localhost'
sudo docker compose up -d
```
Remove the dummy certificate and private key before requesting a signed TLS certificate with Certbot. Then, restart NGINX to load the new certificate.
```
sleep 20
sudo rm -r $(dirname $path)
sudo docker compose run --rm --entrypoint "\
    certbot certonly --webroot --webroot-path=/var/www/html --email $email --agree-tos \
    --eff-email --force-renewal -d $domain -d www.$domain" certbot
sudo docker compose restart nginx
```
Enable Docker to start on boot.
```
if ! command -v systemctl &> /dev/null; then
    echo "systemctl is not installed" && exit 1
fi
sudo systemctl enable docker
sudo docker compose down
```
After this, check the generated nginx.conf in ~/docker/reverse-proxy/nginx-conf/ and compare it with the nginx.conf-sample.
## Step 4: Start Docker Compose
You can now start both compose files with the following commands in the `~/docker/reverse-proxy` or `~/docker/website` directories.

Remember to start the reverse-proxy first.
```
sudo docker compose up -d
```
To stop the services, use the following command:
```
sudo docker compose down
```
This is the end of the guide. Your WordPress site should now be accessible via your domain, running behind the reverse proxy set up with Docker Compose.
