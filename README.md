# How to setup a reverse proxy and wordpress with a docker compose

First of all you need along with docker the [docker compose](https://docs.docker.com/compose/) install.

## Git clone
Download a copy of the app with `git clone`
```
$ git clone https://github.com/Gaaarz/docker_reverse_proxy_wordpress /docker/
```

## Environment Variables
Set your variables domain and email:
```
$ domain=yourdomain.com
```
```
$ email=your@email.com
```

## Generating a NGINX config for the given domain for our reverse-proxy
```
$ [ -f ./nginx-conf/nginx.conf-sample ] && cat ./nginx-conf/nginx.conf-sample | sed "s/ROOT_DOMAIN/$domain/" > ./nginx-conf/nginx.conf
```

## Generating a dummy certificate and private key for NGINX to start service
```
$ dirname=$(echo $(basename $(pwd)) | sed "s/\.//")
```
```
$ path=/var/lib/docker/volumes/${dirname}_certbot/_data/live/$domain/
```
```
$ sudo mkdir -p $path
```
```
$ sudo openssl req -x509 -nodes -newkey rsa:4096 -days 1 -keyout ${path}privkey.pem -out ${path}fullchain.pem -subj '/CN=localhost'
```
Now we need to start the NGINX to pull the dummy certificates (you need to be in the /reverse-proxy/-folder
```
$ docker-compose up -d
```
After startup wait round about 20 sec and remove the dummy certificates and private key to prepare they way for new signed TLS certificates with certbot
```
$ rm -r $(dirname $path)
```


