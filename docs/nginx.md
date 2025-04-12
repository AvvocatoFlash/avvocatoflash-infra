# 🔐 Nginx & TLS Setup for AvvocatoFlash

This document explains how to configure Nginx with Let's Encrypt TLS certificates in a Dockerized setup, including auto-renewal using `certbot`.

---

## 📁 Directory Structure

```bash
/srv/
├── nginx/
│   ├── certs/             # SSL certs (bind-mounted into the container)
│   ├── conf.d/            # Nginx config files
│   └── webroot/           # Webroot used by Certbot HTTP-01 challenge
├── infra/
│   └── docker-compose.yml
```

---

## 🐳 Nginx Configuration
```bash
cat /srv/nginx/conf.d/default.conf
```


---

## 📦 Nginx in Docker

We run Nginx using Docker with `docker-compose`. Here’s a simplified view of the `nginx` service:

```yaml
services:
  nginx:
    image: nginx:stable
    container_name: nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /srv/nginx/conf.d:/etc/nginx/conf.d:ro
      - /srv/nginx/webroot:/srv/nginx/webroot:ro
      - /srv/nginx/certs:/etc/nginx/certs:ro
    extra_hosts:
      - "host.docker.internal:host-gateway"
```

---

## 🔐 Certificate Storage & Usage
The Nginx config at `/srv/nginx/conf.d/default.conf` uses the following paths inside the container:

```bash
ssl_certificate /etc/nginx/certs/fullchain.pem;
ssl_certificate_key /etc/nginx/certs/privkey.pem;
```
These are mounted from the host path:

```bash
/srv/nginx/certs/fullchain.pem
/srv/nginx/certs/privkey.pem
```

---

## 🛠 How We Applied Certificates
1. Generated with Certbot:
```bash
   sudo certbot certonly --webroot -w /srv/nginx/webroot \
   -d api.avvocatoflash.dev \
   -d api.avvocatoflash.it
 ```

2. Copied real .pem files:
```bash
sudo rm /srv/nginx/certs/fullchain.pem /srv/nginx/certs/privkey.pem
sudo cp /etc/letsencrypt/archive/api.avvocatoflash.dev/fullchain2.pem /srv/nginx/certs/fullchain.pem
sudo cp /etc/letsencrypt/archive/api.avvocatoflash.dev/privkey2.pem /srv/nginx/certs/privkey.pem
```
Replace `fullchain2.pem / privkey2.pem` with the latest versions in `/etc/letsencrypt/archive/`.

3. Restarted Nginx:
```bash
   docker compose -f docker-compose.nginx.yml down && docker compose -f docker-compose.nginx.yml up -d
```

---

## 🔁 Auto-Renewal Setup (Crontab)
We added this to the root crontab (sudo crontab -e):
```bash
0 3 * * * certbot renew --webroot -w /srv/nginx/webroot --deploy-hook "cp \$(readlink -f /etc/letsencrypt/live/api.avvocatoflash.dev/fullchain.pem) /srv/nginx/certs/fullchain.pem && cp \$(readlink -f /etc/letsencrypt/live/api.avvocatoflash.dev/privkey.pem) /srv/nginx/certs/privkey.pem && docker restart nginx"
```

This cron job does the following:

Attempts to renew certificates via HTTP-01 challenge

Copies the newly updated real files to `/srv/nginx/certs/`

Restarts the nginx container to pick up new certificates

---

## 🔍 How to Manually Renew the Certificate
Run this command to trigger a real renewal (if it's close to expiration):

```bash
sudo certbot renew --webroot -w /srv/nginx/webroot
```
This will only renew if renewal is needed (usually <30 days remaining).

Afterward, manually copy the updated files:
```bash
sudo cp /etc/letsencrypt/archive/api.avvocatoflash.dev/fullchain3.pem /srv/nginx/certs/fullchain.pem
sudo cp /etc/letsencrypt/archive/api.avvocatoflash.dev/privkey3.pem /srv/nginx/certs/privkey.pem
docker restart nginx
```

---

## 🧪 How to Test the Renewal Logic
To simulate a renewal (without changing anything):

```bash
sudo certbot renew --dry-run --webroot -w /srv/nginx/webroot
```

Then verify:
```bash
ls -l /srv/nginx/certs/
docker exec -it nginx ls -l /etc/nginx/certs/
docker logs nginx --tail=20
```

---
we have disabled iptables to stop Docker from exposing ports to the public unless explicitly allowed

```bash
nano /etc/docker/daemon.json
sudo systemctl restart docker
```
Added the following content to the file:
```json
{
"iptables": false
}
```

