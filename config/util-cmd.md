# mongo
docker compose -f docker-compose.mongo.yml -p mongo down --remove-orphans && docker compose -f docker-compose.mongo.yml -p mongo up -d --build

# elastic search
docker compose -f docker-compose.elasticsearch.yml -p elasticsearch down --remove-orphans && docker compose -f docker-compose.elasticsearch.yml -p elasticsearch up -d --build

# elastic agent
docker compose -f docker-compose.elasticagent.yml -p elasticagent down --remove-orphans && docker compose -f docker-compose.elasticagent.yml -p elasticagent up -d --build

# nginx
docker compose -f docker-compose.nginx.yml -p nginx down --remove-orphans && docker compose -f docker-compose.nginx.yml -p nginx up -d

# avvocatoflash-dev env
docker compose -f docker-compose-dev.yml -p avvocatoflash-dev down --remove-orphans && docker compose -f docker-compose-dev.yml -p avvocatoflash-dev up -d --build

# avvocatoflash-prod env
docker compose -f docker-compose-prod.yml -p avvocatoflash-prod down --remove-orphans && docker compose -f docker-compose-prod.yml -p avvocatoflash-prod up -d --build

# single container dev
docker compose -f docker-compose-dev.yml -p avvocatoflash-dev rm -fs service-api && docker compose -f docker-compose-dev.yml -p avvocatoflash-dev up -d --build service-api

# single container prod
docker compose -f docker-compose-prod.yml -p avvocatoflash-prod rm -fs service-api && docker compose -f docker-compose-prod.yml -p avvocatoflash-prod up -d --build service-api

# nginx config
nano /srv/nginx/conf.d/default.conf

# nginx config test and reload
docker exec -it nginx nginx -t && docker exec -it nginx nginx -s reload

docker network create internal-net
docker network create public-net

# docker ps
docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"

# logs
docker logs kibana

# access
docker exec -it kibana bash
docker exec -it kibana /bin/bash
docker exec -it avvocatoflash-dev-service-api /bin/bash
docker exec -it fleet-server /bin/bash


# delete all dev
docker ps -a --filter name=dev -q | xargs -r docker rm -f


# backup
docker ps -a --filter "name=-\${ENV_SUFFIX}" -q | xargs -r docker rm -f
docker network ls --filter "name=-\${ENV_SUFFIX}" -q | xargs -r docker network rm


rm -rf /srv/data/elasticsearch/*
rm -rf /srv/logs/elasticsearch/*
rm -rf /srv/data/kibana/*
rm -rf /srv/logs/kibana/*

# metricbeat - one time
metricbeat setup --dashboards

# mongo check replicaset
docker exec -it mongo1 mongosh --quiet --eval 'printjson(rs.status().members.map(m=>m.stateStr))'

mongodb://localhost:27017,localhost:27018,localhost:27019/?replicaSet=rs0
mongodb://mongo1:27017,mongo2:27017,mongo3:27017/?replicaSet=rs0


docker compose -f docker-compose.dev.yml down



docker logs -f avvocatoflash-dev-service-api

docker logs -f filebeat


docker compose -f docker-compose.elasticsearch.yml down --remove-orphans
docker rm -f filebeat || true
docker network rm elk-net || true


//
hey so great job

/srv/
── nginx/
│   ├── certs/             # SSL certs (bind-mounted into the container)
│   ├── conf.d/            # Nginx config files
│   └── webroot/           # Webroot used by Certbot HTTP-01 challenge
── infra/
│   └── docker-compose.mongo.yml
│   └── docker-compose.nginx.yml
│   └── docker-compose.elasticsearch.yml
── apps/
│   └── dev/backend/docker-compose-dev.yml
│   └──  prod/backend/docker-compose-prod.yml
── data/
│   └── elasticsearch
│   └── kibana
│   └── mongodb
── logs/
│   └──elasticsearch
│   └──kibana
│   └──nginx
