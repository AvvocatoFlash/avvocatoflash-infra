deployer@avvocatoflash:/srv/infra$ cat /srv/nginx/conf.d/default.conf
# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name
    api.avvocatoflash.dev
    api.avvocatoflash.it
    api-admin.avvocatoflash.dev
    api-admin.avvocatoflash.it
    api-customer.avvocatoflash.dev
    api-customer.avvocatoflash.it
    api-website.avvocatoflash.dev
    api-website.avvocatoflash.it
    api-agency.avvocatoflash.dev
    api-agency.avvocatoflash.it
    api-realestate.avvocatoflash.dev
    api-realestate.avvocatoflash.it;

    return 301 https://$host$request_uri;
}

# --- Common SSL settings ---
ssl_certificate /etc/nginx/certs/fullchain.pem;
ssl_certificate_key /etc/nginx/certs/privkey.pem;
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers on;

# --- Dev & Prod Domains ---
# api.avvocatoflash.dev → 4000
server {
listen 443 ssl;
server_name api.avvocatoflash.dev;

    location /.well-known/acme-challenge/ {
        root /srv/nginx/webroot;
        try_files $uri =404;
    }

    location / {
        proxy_pass http://host.docker.internal:4000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

# api.avvocatoflash.it → 3000
server {
listen 443 ssl;
server_name api.avvocatoflash.it;

    location /.well-known/acme-challenge/ {
        root /srv/nginx/webroot;
        try_files $uri =404;
    }

    location / {
        proxy_pass http://host.docker.internal:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

# ----- Admin -----
server {
listen 443 ssl;
server_name api-admin.avvocatoflash.dev;

    location / {
        proxy_pass http://host.docker.internal:4001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

server {
listen 443 ssl;
server_name api-admin.avvocatoflash.it;

    location / {
        proxy_pass http://host.docker.internal:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

# ----- Customer -----
server {
listen 443 ssl;
server_name api-customer.avvocatoflash.dev;

    location / {
        proxy_pass http://host.docker.internal:4002;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

server {
listen 443 ssl;
server_name api-customer.avvocatoflash.it;

    location / {
        proxy_pass http://host.docker.internal:3002;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

# ----- Website -----
server {
listen 443 ssl;
server_name api-website.avvocatoflash.dev;

    location / {
        proxy_pass http://host.docker.internal:4003;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

server {
listen 443 ssl;
server_name api-website.avvocatoflash.it;

    location / {
        proxy_pass http://host.docker.internal:3003;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

# ----- Agency -----
server {
listen 443 ssl;
server_name api-agency.avvocatoflash.dev;

    location / {
        proxy_pass http://host.docker.internal:4004;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

server {
    listen 443 ssl;
    server_name api-agency.avvocatoflash.it;
    
        location / {
            proxy_pass http://host.docker.internal:3004;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
}

# ----- Real Estate -----
server {
    listen 443 ssl;
    server_name api-realestate.avvocatoflash.dev;
    
        location / {
            proxy_pass http://host.docker.internal:4005;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
}

server {
    listen 443 ssl;
    server_name api-realestate.avvocatoflash.it;

    
        location / {
            proxy_pass http://host.docker.internal:3005;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
}

# ----- Kibana -----
server {
listen 443 ssl;
server_name elastic.avvocatoflash.dev;

    location / {
        proxy_pass http://host.docker.internal:5601;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

# ----- Fleet Elastic Agent -----
server {
listen 443 ssl;
server_name fleet.avvocatoflash.dev;

    location / {
        proxy_pass https://host.docker.internal:8220;
        proxy_ssl_verify off;  # allow self-signed or internal cert
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
