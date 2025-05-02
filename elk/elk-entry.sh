#!/bin/bash
set -euo pipefail

# Start Elasticsearch in the background
bash /usr/local/bin/docker-entrypoint.sh &


# Wait for Elasticsearch to be ready
echo "⏳ Waiting for Elasticsearch to start..."
until curl -s -u "${ELASTIC_USERNAME}:${ELASTIC_PASSWORD}" http://localhost:9200 \
      | grep -q "You Know, for Search"; do
  echo "Still waiting for Elasticsearch…"
  sleep 5
done
echo "✅ Elasticsearch is up!"

# Check if we've already initialized security
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -u "${ELASTIC_USERNAME}:${ELASTIC_PASSWORD}" \
  http://localhost:9200/_security/role/app_monitoring_role)

if [ "$HTTP_CODE" -eq 200 ]; then
  echo "⚡️ Security already initialized—skipping setup."
else
  echo "🚀 Bootstrapping security configuration..."


  # Setup kibana_system user
  echo "🔐 Setting up kibana_system user..."
  curl -s -u "${ELASTIC_USERNAME}:${ELASTIC_PASSWORD}" -X POST \
    http://localhost:9200/_security/user/kibana_system/_password \
    -H "Content-Type: application/json" \
    -d "{\"password\":\"${KIBANA_SYSTEM_PASSWORD}\"}"

  curl -s -u "${ELASTIC_USERNAME}:${ELASTIC_PASSWORD}" -X PUT \
    http://localhost:9200/_security/user/kibana_system/_roles \
    -H "Content-Type: application/json" \
    -d '["kibana_admin"]'

  # Create admin user
  echo "👤 Creating admin user..."
  curl -s -u "${ELASTIC_USERNAME}:${ELASTIC_PASSWORD}" -X POST \
    http://localhost:9200/_security/user/admin \
    -H "Content-Type: application/json" \
    -d "{
      \"password\":\"${ADMIN_PASSWORD}\",
      \"roles\":[\"superuser\"]
    }"

  # Create APM user
    echo "🔧 Creating APM user..."
    curl -s -u "${ELASTIC_USERNAME}:${ELASTIC_PASSWORD}" -X POST \
      http://localhost:9200/_security/user/${APM_USER} \
      -H "Content-Type: application/json" \
      -d "{
        \"password\":\"${APM_PASSWORD}\",
        \"roles\":[\"apm_system\"]
      }"

  # Create App Monitoring Role
    echo "🔧 Creating app_monitoring_role..."
    curl -s -u "${ELASTIC_USERNAME}:${ELASTIC_PASSWORD}" -X PUT \
      http://localhost:9200/_security/role/app_monitoring_role \
      -H "Content-Type: application/json" \
      -d "{
        \"cluster\":[],
        \"indices\":[{
          \"names\":[\"logs-*\",\"app-logs-*\"],
          \"privileges\":[\"create_index\",\"write\",\"read\"]
        }]
      }"

  # Create App User with Monitoring Role
    echo "👤 Creating app_user..."
    curl -s -u "${ELASTIC_USERNAME}:${ELASTIC_PASSWORD}" -X POST \
      http://localhost:9200/_security/user/"${APP_USER}" \
      -H "Content-Type: application/json" \
      -d "{
        \"password\":\"${APP_PASSWORD}\",
        \"roles\":[\"app_monitoring_role\"]
      }"
fi

# 8) Wait on Elasticsearch process so container doesn’t exit
wait -n
