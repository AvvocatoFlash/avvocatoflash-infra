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
│   └── nginx/docker-compose.yml
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
      - 'host.docker.internal:172.17.0.1'
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
# only dev
sudo certbot certonly --webroot \
  -w /srv/nginx/webroot \
  -d api.avvocatoflash.dev \
  -d api-admin.avvocatoflash.dev \
  -d api-customer.avvocatoflash.dev \
  -d api-website.avvocatoflash.dev \
  -d api-agency.avvocatoflash.dev \
  -d api-realestate.avvocatoflash.dev \
  -d kibana.avvocatoflash.dev
  
# all envs
sudo certbot certonly --webroot \
  -w /srv/nginx/webroot \
  -d api.avvocatoflash.dev \
  -d api.avvocatoflash.it \
  -d api-admin.avvocatoflash.dev \
  -d api-admin.avvocatoflash.it \
  -d api-customer.avvocatoflash.dev \
  -d api-customer.avvocatoflash.it \
  -d api-website.avvocatoflash.dev \
  -d api-website.avvocatoflash.it \
  -d api-agency.avvocatoflash.dev \
  -d api-agency.avvocatoflash.it \
  -d api-realestate.avvocatoflash.dev \
  -d api-realestate.avvocatoflash.it \
  -d kibana.avvocatoflash.dev
 ```

2. Copied real .pem files:
```bash
sudo cp /etc/letsencrypt/live/api.avvocatoflash.dev/fullchain.pem /srv/nginx/certs/fullchain.pem
sudo cp /etc/letsencrypt/live/api.avvocatoflash.dev/privkey.pem /srv/nginx/certs/privkey.pem
```

3. Restarted Nginx:
```bash
   yarn docker restart nginx
   # or
   docker compose -f docker-compose.nginx.yml down && docker compose -f docker-compose.nginx.yml up -d
```

---

## 🔁 Auto-Renewal Setup (Crontab)
We added this to the root crontab (sudo crontab -e):
```bash
0 3 * * * certbot renew --webroot -w /srv/nginx/webroot --deploy-hook "[ -f /srv/nginx/certs/fullchain.pem ] && mkdir -p /srv/nginx/certs/backups && timestamp=\$(date +\%Y\%m\%d-\%H\%M\%S) && cp /srv/nginx/certs/fullchain.pem /srv/nginx/certs/backups/fullchain.pem.\$timestamp && cp /srv/nginx/certs/privkey.pem /srv/nginx/certs/backups/privkey.pem.\$timestamp; cp /etc/letsencrypt/live/api.avvocatoflash.dev/fullchain.pem /srv/nginx/certs/fullchain.pem && cp /etc/letsencrypt/live/api.avvocatoflash.dev/privkey.pem /srv/nginx/certs/privkey.pem && docker exec nginx nginx -s reload" >> /var/log/letsencrypt/renew-hook.log 2>&1
```
This cron job:

Simulates certificate renewal via HTTP-01

Backs up existing certificates

Copies new certs into `/srv/nginx/certs/`

Reloads the Nginx container

Logs everything to `/var/log/letsencrypt/renew-hook.log`

---

## 🔍 How to Manually Renew the Certificate
Run this command to trigger a real renewal (if it's close to expiration):

```bash
sudo certbot renew --webroot -w /srv/nginx/webroot
```
This will only renew if renewal is needed (usually <30 days remaining).

Afterward, manually copy the updated files:
```bash
sudo cp /etc/letsencrypt/live/api.avvocatoflash.dev/fullchain.pem /srv/nginx/certs/fullchain.pem
sudo cp /etc/letsencrypt/live/api.avvocatoflash.dev/privkey.pem /srv/nginx/certs/privkey.pem
docker restart nginx
```

---

## 🧪 How to Test the Renewal Logic
To simulate a renewal (without changing anything):

```bash
sudo certbot renew --dry-run --deploy-hook "[ -f /srv/nginx/certs/fullchain.pem ] && mkdir -p /srv/nginx/certs/backups && timestamp=$(date +%Y%m%d-%H%M%S) && cp /srv/nginx/certs/fullchain.pem /srv/nginx/certs/backups/fullchain.pem.$timestamp && cp /srv/nginx/certs/privkey.pem /srv/nginx/certs/backups/privkey.pem.$timestamp; cp /etc/letsencrypt/live/api.avvocatoflash.dev/fullchain.pem /srv/nginx/certs/fullchain.pem && cp /etc/letsencrypt/live/api.avvocatoflash.dev/privkey.pem /srv/nginx/certs/privkey.pem && docker exec nginx nginx -s reload"
```

Then verify:
```bash
ls -l /srv/nginx/certs/
docker exec nginx ls -l /etc/nginx/certs/
docker logs nginx --tail=20
```

---

## 🚧 docker
We configured Docker to disable the userland proxy to avoid unnecessary port bindings. This enhances security by ensuring Docker doesn’t open additional ports on the host unless explicitly defined in the Docker Compose configuration.
Edit:
```bash
nano /etc/docker/daemon.json
sudo systemctl restart docker
```
Added the following content to the file:
```json
{
  "userland-proxy": false
}
```

sudo tail -f /srv/logs/nginx/access.log
sudo tail -n 50 /srv/logs/nginx/error.log
