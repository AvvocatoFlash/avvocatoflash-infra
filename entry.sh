#!/bin/bash
set -e

# Start Elasticsearch in background
bash /usr/local/bin/docker-entrypoint.sh &

echo "${ELASTIC_PASSWORD}"

# Wait until Elasticsearch is healthy
until curl -s -u elastic:"$ELASTIC_PASSWORD" http://localhost:9200 | grep -q "You Know, for Search"; do
  echo "Still waiting..."
  sleep 5
done

echo "✅ Elasticsearch is up!"

### 1. Reset kibana_system password
echo "🔐 Setting kibana_system password..."
curl -s -X POST -u elastic:"$ELASTIC_PASSWORD" \
  -H "Content-Type: application/json" \
  -d '{"password": "'"$KIBANA_SYSTEM_PASSWORD"'"}' \
  http://localhost:9200/_security/user/kibana_system/_password || echo "❌ Failed to reset kibana_system password"

### 2. Create all roles
echo "🔧 Creating custom roles..."

curl -s -X PUT "http://localhost:9200/_security/role/custom_monitoring_role" \
  -u "elastic:${ELASTIC_PASSWORD}" \
  -H "Content-Type: application/json" \
  -d '{
    "cluster": ["monitor", "monitor_watcher"],
    "indices": [{
      "names": [".monitoring-*", ".kibana*", "metricbeat-*", "filebeat-*", "logs-*"],
      "privileges": ["read", "view_index_metadata"]
    }]
  }' || echo "❌ Failed to create custom_monitoring_role"

curl -s -X PUT "http://localhost:9200/_security/role/logs_viewer_role" \
  -u "elastic:${ELASTIC_PASSWORD}" \
  -H "Content-Type: application/json" \
  -d '{
    "cluster": ["monitor"],
    "indices": [{
      "names": ["logs-*", ".logs-*", ".kibana*"],
      "privileges": ["read", "view_index_metadata"]
    }]
  }' || echo "❌ Failed to create logs_viewer_role"

### 3. Create kibana_admin user with all roles
echo "👤 Creating kibana_admin user..."

curl -s -X POST -u elastic:"$ELASTIC_PASSWORD" \
  -H "Content-Type: application/json" \
  -d '{
    "password": "'"$KIBANA_ADMIN_PASSWORD"'",
    "roles": ["kibana_admin", "superuser", "custom_monitoring_role", "logs_viewer_role"],
    "full_name": "Kibana Admin",
    "email": "admin@example.com"
  }' \
  http://localhost:9200/_security/user/kibana_admin || echo "❌ Failed to create kibana_admin user"

### 4. Expand kibana_admin role to include log writer
echo "📝 Updating kibana_admin role with log writer privileges..."

curl -s -X PUT -u elastic:$ELASTIC_PASSWORD http://localhost:9200/_security/role/kibana_admin \
  -H 'Content-Type: application/json' \
  -d '{
    "cluster": ["all"],
    "indices": [{
      "names": ["node-logs*"],
      "privileges": ["create_index", "create", "write"]
    }]
  }' || echo "❌ Failed to update kibana_admin role"

echo "✅ Setup complete"
echo "🔗 Elasticsearch: http://localhost:9200"
echo "🔗 Kibana:        http://localhost:5601"

wait -n
